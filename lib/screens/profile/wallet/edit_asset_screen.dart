import 'package:flutter/material.dart';
import '../../../models/wallet_model.dart';
import '../../../constants/colors.dart';

class EditAssetScreen extends StatefulWidget {
  final WalletItem item;
  final Function(WalletItem) onSave;

  const EditAssetScreen({
    super.key,
    required this.item,
    required this.onSave,
  });

  @override
  State<EditAssetScreen> createState() => _EditAssetScreenState();
}

class _EditAssetScreenState extends State<EditAssetScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _amountController;
  late final TextEditingController _buyPriceController;
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.item.amount.toString());
    _buyPriceController =
        TextEditingController(text: widget.item.buyPrice.toString());

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
          'Edit Asset',
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isSaving ? null : _saveChanges,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.save,
                          color: Colors.white,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _isSaving ? 'Saving...' : 'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAssetInfoCard(isDark),
                  const SizedBox(height: 24),
                  _buildEditForm(isDark),
                  const SizedBox(height: 32),
                  _buildSaveButton(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssetInfoCard(bool isDark) {
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
      child: Row(
        children: [
          // Crypto Image with gradient border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary,
                  AppColors.secondary.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
              ),
              child: ClipOval(
                child: widget.item.cryptoImage.isEmpty
                    ? Container(
                        width: 64,
                        height: 64,
                        color: AppColors.accent.withOpacity(0.3),
                        child: Icon(
                          Icons.currency_bitcoin,
                          color: AppColors.secondary,
                          size: 32,
                        ),
                      )
                    : Image.network(
                        widget.item.cryptoImage,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 64,
                            height: 64,
                            color: AppColors.accent.withOpacity(0.3),
                            child: Icon(
                              Icons.error,
                              color: AppColors.secondary,
                              size: 32,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Crypto Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.cryptoName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.lightText : AppColors.darkText,
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.item.cryptoSymbol.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current Value: \$${(widget.item.amount * widget.item.buyPrice).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
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
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit,
                  color: AppColors.whiteText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Asset Details',
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

          // Amount Field
          _buildSectionHeader('Amount', Icons.numbers, isDark),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
            cursorColor: AppColors.secondary,
            decoration: _buildInputDecoration(
              'Enter amount',
              Icons.numbers,
              widget.item.cryptoSymbol.toUpperCase(),
              isDark,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than 0';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Buy Price Field
          _buildSectionHeader('Buy Price', Icons.attach_money, isDark),
          const SizedBox(height: 12),
          TextFormField(
            controller: _buyPriceController,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
            cursorColor: AppColors.secondary,
            decoration: _buildInputDecoration(
              'Enter buy price',
              Icons.attach_money,
              'USD',
              isDark,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a buy price';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Price must be greater than 0';
              }
              return null;
            },
          ),
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
      suffixText: suffix,
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
        borderSide: BorderSide(
          color: isDark
              ? AppColors.lightText.withOpacity(0.3)
              : AppColors.darkText.withOpacity(0.3),
          width: 1.5,
        ),
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

  Widget _buildSaveButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSaving ? null : _saveChanges,
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
                    Icons.save_rounded,
                    color: AppColors.whiteText,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                Text(
                  _isSaving ? 'Saving Changes...' : 'Save Changes',
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'DMSerif',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      final amount = double.parse(_amountController.text);
      final buyPrice = double.parse(_buyPriceController.text);

      final updatedItem = widget.item.copyWith(
        amount: amount,
        buyPrice: buyPrice,
      );

      await widget.onSave(updatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.item.cryptoName} updated successfully!',
                  style: const TextStyle(
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, updatedItem);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error updating asset: $e',
                    style: const TextStyle(
                      fontFamily: 'DMSerif',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
