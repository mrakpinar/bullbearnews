import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/screens/profile/portfolio/portfolio_analysis_screen.dart';
import 'package:bullbearnews/screens/profile/portfolio/portfolio_detail_screen.dart';
import 'package:bullbearnews/screens/profile/wallet/wallets_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';
import '../../services/crypto_service.dart';

class PortfolioSummary extends StatefulWidget {
  final VoidCallback? onUpdate;

  const PortfolioSummary({super.key, this.onUpdate});

  @override
  State<PortfolioSummary> createState() => _PortfolioSummaryState();
}

class _PortfolioSummaryState extends State<PortfolioSummary> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CryptoService _cryptoService = CryptoService();

  List<WalletItem> _walletItems = [];
  double _totalPortfolioValue = 0;
  double _totalInvestment = 0;
  double _totalProfitLoss = 0;
  double _totalProfitLossPercentage = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWalletItems();
  }

  Future<void> _loadWalletItems() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .get();

      List<WalletItem> allItems = [];
      for (var doc in snapshot.docs) {
        final wallet = Wallet.fromJson(doc.data()).copyWith(id: doc.id);
        allItems.addAll(wallet.items);
      }

      await _calculatePortfolioValues(allItems);

      setState(() {
        _walletItems = allItems;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred while loading wallet: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculatePortfolioValues(List<WalletItem> walletItems) async {
    double totalValue = 0;
    double totalInvestment = 0;

    try {
      final List<CryptoModel> allCryptos = await _cryptoService.getCryptoData();

      for (var item in walletItems) {
        final crypto = allCryptos.firstWhere(
          (c) => c.id == item.cryptoId,
          orElse: () => CryptoModel(
            id: item.cryptoId,
            name: item.cryptoName,
            symbol: item.cryptoSymbol,
            image: item.cryptoImage,
            currentPrice: 0,
            priceChangePercentage24h: 0,
            marketCap: 0,
            totalVolume: 0,
            circulatingSupply: 0,
            ath: 0,
            atl: 0,
          ),
        );

        totalValue += item.amount * crypto.currentPrice;
        totalInvestment += item.amount * item.buyPrice;
      }

      double profitLoss = totalValue - totalInvestment;
      double profitLossPercentage =
          totalInvestment > 0 ? (profitLoss / totalInvestment) * 100 : 0;

      if (mounted) {
        setState(() {
          _totalPortfolioValue = totalValue;
          _totalInvestment = totalInvestment;
          _totalProfitLoss = profitLoss;
          _totalProfitLossPercentage = profitLossPercentage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error calculating portfolio: $e';
        });
      }
    }
  }

  Future<void> _showPortfolioDetails() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Tüm wallet'ları getir
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wallets')
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Tüm wallet'ların item'larını birleştir
      List<WalletItem> allItems = [];
      for (var doc in snapshot.docs) {
        final wallet = Wallet.fromJson(doc.data()).copyWith(id: doc.id);
        allItems.addAll(wallet.items);
      }

      // Geçici bir wallet oluştur
      final combinedWallet = Wallet(
        id: 'combined',
        name: 'All Wallets',
        items: allItems,
        createdAt: DateTime.now(),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PortfolioDetailScreen(
            wallet: combinedWallet,
            onUpdate: () async {
              await _loadWalletItems();
              if (mounted) setState(() {});
              widget.onUpdate?.call();
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallet found'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardTheme.color,
            border: Border.all(
              color: isDarkMode
                  ? const Color(0xFFE0E0E0).withOpacity(0.5)
                  : const Color(0xFF393E46).withOpacity(0.3),
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    return _buildPortfolioSummaryCard(isDarkMode);
  }

  Future<void> _navigateToAnalysis() async {
    if (_walletItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('Add cryptocurrencies to your portfolio first'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PortfolioAnalysisScreen(),
      ),
    );
  }

  Widget _buildPortfolioSummaryCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [const Color(0xFF393E46), const Color(0xFF393E46)]
              : [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? const Color(0xFFE0E0E0).withOpacity(0.5)
              : const Color(0xFF393E46).withOpacity(0.3),
          width: 0.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? const Color(0xFF222831).withOpacity(0.3)
                : const Color(0xFFDFD0B8).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Portfolio Value',
                style: TextStyle(
                  fontSize: 18,
                  color: isDarkMode
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                  fontFamily: 'DMSerif',
                ),
              ),
              Text(
                '\$${_totalPortfolioValue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF948979),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  Text(
                    '\$${_totalInvestment.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Profit/Loss',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF948979),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  Text(
                    '${_totalProfitLossPercentage.toStringAsFixed(2)}% (\$${_totalProfitLoss.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 16,
                      color: _totalProfitLoss >= 0 ? Colors.green : Colors.red,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add,
                  label: 'Add Coin',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WalletsScreen()));
                  },
                  isDarkMode: isDarkMode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'Analyze',
                  onPressed:
                      _navigateToAnalysis, // Parent widget'tan geçirilecek
                  isDarkMode: isDarkMode,
                  // isHighlighted: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.pie_chart_outline,
                  label: 'Details',
                  onPressed:
                      _showPortfolioDetails, // Parent widget'tan geçirilecek
                  isDarkMode: isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDarkMode,
    bool isHighlighted = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isHighlighted
            ? const Color(0xFF948979).withOpacity(0.1)
            : const Color(0xFF948979).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isHighlighted
                ? const Color(0xFF948979).withOpacity(0.5)
                : const Color(0xFF948979).withOpacity(0.3),
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted
                ? const Color(0xFF948979)
                : isDarkMode
                    ? const Color(0xFFDFD0B8)
                    : const Color(0xFF222831),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isHighlighted
                  ? const Color(0xFF948979)
                  : isDarkMode
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
              fontFamily: 'DMSerif',
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
