import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isCreating = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) {
      setState(() => _isCreating = true);
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallets')
          .add({
        'name': _nameController.text.trim(),
        'items': [],
        'createdAt': DateTime.now().toIso8601String(),
      });

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
                  'Wallet "${_nameController.text}" created successfully!',
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

        Navigator.pop(context);
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
                    'Error creating wallet: $e',
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
        setState(() => _isCreating = false);
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
          'Create New Wallet',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(isDark),
                  const SizedBox(height: 32),
                  _buildFormCard(isDark),
                  const SizedBox(height: 32),
                  _buildCreateButton(isDark),
                ],
              ),
            ),
          ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.whiteText,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Create Your Portfolio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your crypto investments\nwith a personalized wallet',
            textAlign: TextAlign.center,
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
                    colors: [
                      AppColors.secondary,
                      AppColors.accent,
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
                'Wallet Details',
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

          // Wallet Name Field
          _buildSectionHeader('Wallet Name', Icons.wallet, isDark),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
            cursorColor: AppColors.secondary,
            decoration: _buildInputDecoration(
              'My Crypto Portfolio',
              Icons.wallet,
              isDark,
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a wallet name';
              }
              if (value.trim().length < 3) {
                return 'Wallet name must be at least 3 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Info Container
          Container(
            padding: const EdgeInsets.all(16),
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
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose a descriptive name for your wallet to easily identify it later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
              ],
            ),
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
      String hint, IconData icon, bool isDark) {
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

  Widget _buildCreateButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
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
          onTap: _isCreating ? null : _createWallet,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCreating)
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
                  _isCreating ? 'Creating Wallet...' : 'Create Wallet',
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
}
