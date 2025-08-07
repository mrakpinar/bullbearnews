import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/crypto_model.dart';
import '../../../models/wallet_model.dart';
import '../../../services/crypto_service.dart';

class PortfolioDetailScreen extends StatefulWidget {
  final Wallet wallet;
  final Function() onUpdate;

  const PortfolioDetailScreen({
    super.key,
    required this.wallet,
    required this.onUpdate,
  });

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen>
    with TickerProviderStateMixin {
  late Wallet _wallet;
  List<WalletItem> _walletItems = [];
  final CryptoService _cryptoService = CryptoService();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _listAnimation;

  @override
  void initState() {
    super.initState();
    _wallet = widget.wallet;
    _walletItems = List<WalletItem>.from(_wallet.items);
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _listAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );

    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _listAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  // Helper method to format crypto amounts intelligently
  String _formatCryptoAmount(double amount) {
    if (amount == 0) return '0';

    // If amount is >= 1, show up to 2 decimal places, removing unnecessary zeros
    if (amount >= 1) {
      String formatted = amount.toStringAsFixed(2);
      // Remove trailing zeros
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      return formatted;
    }

    // If amount is < 1 but >= 0.01, show up to 4 decimal places
    if (amount >= 0.01) {
      String formatted = amount.toStringAsFixed(4);
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      return formatted;
    }

    // If amount is < 0.01, show up to 6 decimal places
    if (amount >= 0.0001) {
      String formatted = amount.toStringAsFixed(6);
      formatted = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      return formatted;
    }

    // For very small amounts, use scientific notation or show more decimals
    return amount.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '');
  }

  Future<void> _updateItemAmount(int index, double newAmount) async {
    if (newAmount <= 0) {
      _showSnackbar('Amount must be greater than 0', isError: true);
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final item = _walletItems[index];

      List<Map<String, dynamic>> updatedItems =
          _walletItems.map((item) => item.toJson()).toList();
      updatedItems[index]['amount'] = newAmount;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(_wallet.id)
          .update({'items': updatedItems});

      setState(() {
        _walletItems[index] = item.copyWith(amount: newAmount);
      });

      widget.onUpdate();
      _showSnackbar('Amount updated successfully');
    } catch (e) {
      _showSnackbar('Error updating amount: $e', isError: true);
    }
  }

  Future<void> _removeItem(String cryptoId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      if (_wallet.id == 'combined') {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wallets')
            .get();

        for (var doc in snapshot.docs) {
          final wallet = Wallet.fromJson(doc.data()).copyWith(id: doc.id);
          final updatedItems =
              wallet.items.where((item) => item.cryptoId != cryptoId).toList();

          if (updatedItems.isNotEmpty) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('wallets')
                .doc(wallet.id)
                .update(
                    {'items': updatedItems.map((e) => e.toJson()).toList()});
          } else {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('wallets')
                .doc(wallet.id)
                .delete();
          }
        }
      } else {
        final updatedItems =
            _walletItems.where((item) => item.cryptoId != cryptoId).toList();
        final updatedItemsJson =
            updatedItems.map((item) => item.toJson()).toList();

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wallets')
            .doc(_wallet.id)
            .update({'items': updatedItemsJson});
      }

      setState(() {
        _walletItems =
            _walletItems.where((item) => item.cryptoId != cryptoId).toList();
      });

      widget.onUpdate();
      _showSnackbar('Asset removed from portfolio');
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error removing item: $e', isError: true);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _cryptoService.getCryptoData();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error loading data: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : _walletItems.isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildPortfolioList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF393E46),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _wallet.name,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? const Color(0xFFDFD0B8)
                                      : const Color(0xFF222831),
                                  fontFamily: 'DMSerif',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_walletItems.length} assets in portfolio',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.8)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF393E46),
                      ),
                      onPressed: _loadData,
                      tooltip: 'Refresh data',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading portfolio data...',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontWeight: FontWeight.w500,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF393E46).withOpacity(0.3)
                          : Colors.white.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.wallet_outlined,
                      size: 64,
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Portfolio is empty',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add cryptocurrencies to track your investments',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioList(bool isDark) {
    return AnimatedBuilder(
      animation: _listAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _listAnimation.value)),
          child: Opacity(
            opacity: _listAnimation.value,
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              backgroundColor:
                  isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: _walletItems.length,
                itemBuilder: (context, index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOut,
                    child:
                        _buildPortfolioItem(_walletItems[index], index, isDark),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioItem(WalletItem item, int index, bool isDark) {
    return FutureBuilder<List<CryptoModel>>(
      future: _cryptoService.getCryptoData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildLoadingCard(isDark);
        }

        final crypto = snapshot.data!.firstWhere(
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

        final currentValue = item.amount * crypto.currentPrice;
        final investedValue = item.amount * item.buyPrice;
        final profitLoss = currentValue - investedValue;
        final profitLossPercentage =
            investedValue > 0 ? (profitLoss / investedValue) * 100 : 0;
        final isProfit = profitLoss >= 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Dismissible(
            key: Key(item.cryptoId),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delete_outline,
                      color: Colors.white, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) => _showDeleteConfirmationDialog(item),
            onDismissed: (direction) => _removeItem(item.cryptoId),
            child: Card(
              elevation: 0,
              color: isDark ? const Color(0xFF393E46) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF948979).withOpacity(0.2)
                      : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showEditDialog(item, index),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                item.cryptoImage,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF948979)
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Icon(
                                    Icons.currency_bitcoin,
                                    color: isDark
                                        ? const Color(0xFFDFD0B8)
                                        : const Color(0xFF393E46),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.cryptoName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFDFD0B8)
                                        : const Color(0xFF222831),
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.cryptoSymbol.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF948979),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${currentValue.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFDFD0B8)
                                      : const Color(0xFF222831),
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isProfit
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isProfit
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isProfit
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      size: 14,
                                      color:
                                          isProfit ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${profitLossPercentage.toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isProfit
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF222831).withOpacity(0.5)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDetailItem(
                              'Holdings',
                              '${_formatCryptoAmount(item.amount)} ${item.cryptoSymbol.toUpperCase()}',
                              isDark,
                            ),
                            _buildDetailItem(
                              'Avg Buy Price',
                              '\$${item.buyPrice.toStringAsFixed(4)}',
                              isDark,
                            ),
                            _buildDetailItem(
                              'P&L',
                              '\$${profitLoss.abs().toStringAsFixed(2)}',
                              isDark,
                              isProfit: isProfit,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 16,
                            color: const Color(0xFF948979),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap to edit • Swipe left to remove',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF948979),
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String title, String value, bool isDark,
      {bool? isProfit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF948979),
            fontWeight: FontWeight.w500,
            fontFamily: 'DMSerif',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isProfit != null
                ? isProfit
                    ? Colors.green
                    : Colors.red
                : isDark
                    ? const Color(0xFFDFD0B8)
                    : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        color: isDark ? const Color(0xFF393E46) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircularProgressIndicator(
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                strokeWidth: 2,
              ),
              const SizedBox(width: 16),
              Text(
                'Loading asset data...',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(WalletItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_outlined,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Remove Asset',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${item.cryptoName} from your portfolio? This action cannot be undone.',
          style: TextStyle(
            color: isDark
                ? const Color(0xFFDFD0B8).withOpacity(0.8)
                : const Color(0xFF222831).withOpacity(0.8),
            fontFamily: 'DMSerif',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF948979),
                fontFamily: 'DMSerif',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(WalletItem item, int index) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController(
      text: _formatCryptoAmount(item.amount),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF393E46),
                    const Color(0xFF948979),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Update Amount',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${_formatCryptoAmount(item.amount)} ${item.cryptoSymbol.toUpperCase()}',
              style: TextStyle(
                color: const Color(0xFF948979),
                fontFamily: 'DMSerif',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'New Amount',
                labelStyle: TextStyle(
                  color: const Color(0xFF948979),
                  fontFamily: 'DMSerif',
                ),
                suffixText: item.cryptoSymbol.toUpperCase(),
                suffixStyle: TextStyle(
                  color: const Color(0xFF948979),
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF222831).withOpacity(0.5)
                    : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: const Color(0xFF948979).withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF948979),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: const Color(0xFF948979),
                fontFamily: 'DMSerif',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newAmount = double.tryParse(amountController.text);
              if (newAmount != null && newAmount > 0) {
                await _updateItemAmount(index, newAmount);
                Navigator.pop(context);
              } else {
                _showSnackbar('Please enter a valid amount', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF948979),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Update',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
