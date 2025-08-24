import 'package:bullbearnews/models/crypto_model.dart';
import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/providers/theme_provider.dart';
import 'package:bullbearnews/services/crypto_service.dart';
import 'package:bullbearnews/widgets/profile/portfolio_pie_chart.dart';
import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PortfolioDistribution extends StatefulWidget {
  final List<WalletItem> walletItems;

  const PortfolioDistribution({
    super.key,
    required this.walletItems,
  });

  @override
  State<PortfolioDistribution> createState() => _PortfolioDistributionState();
}

class _PortfolioDistributionState extends State<PortfolioDistribution>
    with SingleTickerProviderStateMixin {
  final CryptoService _cryptoService = CryptoService();
  bool _isLoading = true;
  List<CryptoModel> _cryptoData = [];
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCryptoData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCryptoData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final cryptoData = await _cryptoService.getCryptoData();

      if (mounted) {
        setState(() {
          _cryptoData = cryptoData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load crypto data: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: _buildModernSection(
          title: 'Portfolio Analysis',
          isDark: isDark,
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.lightText.withOpacity(0.1)
              : AppColors.darkText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.3),
                  Colors.greenAccent.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? AppColors.lightText : AppColors.darkText,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      if (widget.walletItems.isNotEmpty && !_isLoading)
                        Text(
                          '${widget.walletItems.length} assets',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.lightText.withOpacity(0.7)
                                : AppColors.darkText.withOpacity(0.7),
                            fontFamily: 'DMSerif',
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isLoading && _errorMessage == null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      onPressed: _loadCryptoData,
                      tooltip: 'Refresh',
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    // Loading state
    if (_isLoading) {
      return _buildLoadingCard(isDark);
    }

    // Error state
    if (_errorMessage != null) {
      return _buildErrorCard(isDark);
    }

    // Empty wallet state
    if (widget.walletItems.isEmpty) {
      return _buildEmptyStateCard(isDark);
    }

    // Success state with data
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.1),
            AppColors.lightBackground.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: PortfolioPieChart(
        walletItems: widget.walletItems,
        allCryptos: _cryptoData,
      ),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: isDark
                  ? AppColors.lightText.withOpacity(0.7)
                  : AppColors.darkText.withOpacity(0.7),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading crypto data...',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade600,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade500,
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadCryptoData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.green,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your Portfolio is Empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some cryptocurrencies to see\nthe distribution chart',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
