import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/crypto_model.dart';
import '../../../models/wallet_model.dart';
import '../../../services/crypto_service.dart';
import '../../../constants/colors.dart';

class AddToWalletScreen extends StatefulWidget {
  const AddToWalletScreen({super.key});

  @override
  State<AddToWalletScreen> createState() => _AddToWalletScreenState();
}

class _AddToWalletScreenState extends State<AddToWalletScreen>
    with SingleTickerProviderStateMixin {
  final CryptoService _cryptoService = CryptoService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CryptoModel? _selectedCrypto;
  List<CryptoModel> _allCryptos = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCryptos();
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
    _amountController.dispose();
    _buyPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCryptos() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final cryptos = await _cryptoService.getCryptoData();
      if (mounted) {
        setState(() {
          _allCryptos = cryptos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load cryptocurrencies: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Add to Wallet',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.lightText : AppColors.darkText,
            fontFamily: 'DMSerif',
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
              color: isDark ? AppColors.lightText : AppColors.darkText,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _isLoading
              ? _buildLoadingState(isDark)
              : _errorMessage.isNotEmpty
                  ? _buildErrorState(isDark)
                  : _buildMainContent(isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.secondary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading cryptocurrencies...',
            style: TextStyle(
              color: isDark
                  ? AppColors.lightText.withOpacity(0.7)
                  : AppColors.darkText.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.lightText : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadCryptos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(isDark),
            const SizedBox(height: 24),
            _buildFormCard(isDark),
            const SizedBox(height: 24),
            _buildAddButton(isDark),
            const SizedBox(height: 40), // Extra space for keyboard
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.lightText.withOpacity(0.1)
              : AppColors.darkText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.whiteText,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Expand Your Portfolio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new cryptocurrency to your wallet',
            textAlign: TextAlign.center,
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
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.lightText.withOpacity(0.1)
              : AppColors.darkText.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: AppColors.whiteText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Asset Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.lightText : AppColors.darkText,
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cryptocurrency Selection
          _buildSectionHeader(
              'Select Cryptocurrency', Icons.currency_bitcoin_rounded, isDark),
          const SizedBox(height: 12),
          _buildCryptoSelector(isDark),

          const SizedBox(height: 24),

          // Amount Field
          _buildSectionHeader('Amount', Icons.numbers_rounded, isDark),
          const SizedBox(height: 12),
          _buildAmountField(isDark),

          const SizedBox(height: 24),

          // Buy Price Field
          _buildSectionHeader(
              'Buy Price (USD)', Icons.attach_money_rounded, isDark),
          const SizedBox(height: 12),
          _buildBuyPriceField(isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.secondary,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.lightText : AppColors.darkText,
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoSelector(bool isDark) {
    return InkWell(
      onTap: () => _showCryptoBottomSheet(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isDark ? AppColors.primary.withOpacity(0.3) : AppColors.whiteText,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? AppColors.lightText.withOpacity(0.3)
                : AppColors.darkText.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.currency_bitcoin_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _selectedCrypto == null
                  ? Text(
                      'Choose your cryptocurrency',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.lightText.withOpacity(0.5)
                            : AppColors.darkText.withOpacity(0.5),
                        fontSize: 16,
                        fontFamily: 'DMSerif',
                      ),
                    )
                  : Row(
                      children: [
                        _buildCryptoImage(_selectedCrypto!),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCrypto!.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.lightText
                                      : AppColors.darkText,
                                  fontFamily: 'DMSerif',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _selectedCrypto!.symbol.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.lightText.withOpacity(0.7)
                                      : AppColors.darkText.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${_selectedCrypto!.currentPrice.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showCryptoBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.lightText.withOpacity(0.3)
                          : AppColors.darkText.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.currency_bitcoin_rounded,
                            color: AppColors.whiteText,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Select Cryptocurrency',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.lightText
                                  : AppColors.darkText,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? AppColors.lightText.withOpacity(0.7)
                                : AppColors.darkText.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Crypto List
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _allCryptos.length,
                      itemBuilder: (context, index) {
                        final crypto = _allCryptos[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedCrypto = crypto;
                                  _buyPriceController.text =
                                      crypto.currentPrice.toStringAsFixed(4);
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _selectedCrypto?.id == crypto.id
                                      ? AppColors.secondary.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedCrypto?.id == crypto.id
                                        ? AppColors.secondary.withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildCryptoImage(crypto),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            crypto.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.lightText
                                                  : AppColors.darkText,
                                              fontFamily: 'DMSerif',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            crypto.symbol.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors.lightText
                                                      .withOpacity(0.7)
                                                  : AppColors.darkText
                                                      .withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${crypto.currentPrice.toStringAsFixed(4)}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.lightText
                                                : AppColors.darkText,
                                            fontFamily: 'DMSerif',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                crypto.priceChangePercentage24h >=
                                                        0
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${crypto.priceChangePercentage24h >= 0 ? '+' : ''}${crypto.priceChangePercentage24h.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  crypto.priceChangePercentage24h >=
                                                          0
                                                      ? Colors.green
                                                      : Colors.red,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCryptoImage(CryptoModel crypto) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          crypto.image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Icon(
              Icons.currency_bitcoin,
              color: AppColors.whiteText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField(bool isDark) {
    return TextFormField(
      controller: _amountController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.lightText : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(
        '0.00000000',
        Icons.numbers_rounded,
        _selectedCrypto?.symbol.toUpperCase() ?? '',
        isDark,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter an amount';
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) return 'Amount must be greater than 0';
        return null;
      },
    );
  }

  Widget _buildBuyPriceField(bool isDark) {
    return TextFormField(
      controller: _buyPriceController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.lightText : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(
        '0.0000',
        Icons.attach_money_rounded,
        'USD',
        isDark,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter a buy price';
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        if (double.parse(value) <= 0) return 'Price must be greater than 0';
        return null;
      },
    );
  }

  InputDecoration _buildInputDecoration(
      String hint, IconData icon, String suffix, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark
            ? AppColors.lightText.withOpacity(0.5)
            : AppColors.darkText.withOpacity(0.5),
        fontFamily: 'DMSerif',
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.secondary,
        size: 20,
      ),
      suffixText: suffix.isNotEmpty ? suffix : null,
      suffixStyle: TextStyle(
        color: AppColors.secondary,
        fontWeight: FontWeight.w600,
        fontFamily: 'DMSerif',
      ),
      filled: true,
      fillColor:
          isDark ? AppColors.primary.withOpacity(0.3) : AppColors.whiteText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark
              ? AppColors.lightText.withOpacity(0.3)
              : AppColors.darkText.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.secondary,
          width: 2.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    );
  }

  Widget _buildAddButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveToWallet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSaving)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.whiteText),
                    ),
                  )
                else
                  const Icon(
                    Icons.add_rounded,
                    color: AppColors.whiteText,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isSaving ? 'Adding to Wallet...' : 'Add to Wallet',
                  style: const TextStyle(
                    color: Color(0xFFDFD0B8),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveToWallet() async {
    if (!_formKey.currentState!.validate() || _selectedCrypto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white),
              const SizedBox(width: 12),
              const Text('Please fill all fields correctly'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final newItem = WalletItem(
        cryptoId: _selectedCrypto!.id,
        cryptoName: _selectedCrypto!.name,
        cryptoSymbol: _selectedCrypto!.symbol,
        cryptoImage: _selectedCrypto!.image,
        amount: double.parse(_amountController.text),
        buyPrice: double.parse(_buyPriceController.text),
      );

      final walletId = ModalRoute.of(context)?.settings.arguments as String?;
      if (walletId == null) throw Exception('Wallet ID not provided');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .doc(walletId)
          .update({
        'items': FieldValue.arrayUnion([newItem.toJson()])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                    '${_selectedCrypto!.symbol.toUpperCase()} added to wallet!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
