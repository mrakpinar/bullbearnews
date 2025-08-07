import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';
import 'email_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkCard
            : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.lightText
                : AppColors.darkText,
            fontFamily: 'DMSerif',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email address to reset your password.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.lightText.withOpacity(0.7)
                    : AppColors.darkText.withOpacity(0.7),
                fontFamily: 'DMSerif',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.lightText
                    : AppColors.darkText,
                fontFamily: 'DMSerif',
              ),
              cursorColor: AppColors.secondary,
              decoration: InputDecoration(
                labelText: 'E-mail',
                labelStyle: TextStyle(
                  fontFamily: 'DMSerif',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.lightText.withOpacity(0.6)
                      : AppColors.darkText.withOpacity(0.6),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.lightText.withOpacity(0.3)
                        : AppColors.darkText.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.lightText.withOpacity(0.3)
                        : AppColors.darkText.withOpacity(0.3),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.secondary,
                    width: 2.0,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: AppColors.secondary,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.lightText.withOpacity(0.7)
                  : AppColors.darkText.withOpacity(0.7),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.whiteText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (emailController.text.isEmpty ||
                  !emailController.text.contains('@')) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Enter a valid e-mail address'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
                return;
              }

              try {
                await _authService.resetPassword(emailController.text.trim());
                if (!mounted) return;
                Navigator.of(ctx).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        const Text('Password reset link sent to your e-mail.'),
                    backgroundColor: Colors.green.shade700,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(ctx).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        final result = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
          _nicknameController.text.trim(),
        );

        if (result != null && mounted) {
          // Kayıt başarılı - ayrı email doğrulama ekranına yönlendir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Registration successful! Please verify your email.'),
              backgroundColor: Colors.green.shade700,
            ),
          );

          // EmailVerificationScreen'e yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EmailVerificationScreen(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _parseFirebaseError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _parseFirebaseError(String message) {
    if (message.contains('user-not-found')) {
      return 'Can\'t find a user with this e-mail address.';
    }
    if (message.contains('wrong-password')) return 'Wrong password.';
    if (message.contains('invalid-credential')) {
      return 'Wrong password or email.';
    }
    if (message.contains('email-already-in-use')) {
      return 'This e-mail address is already in use.';
    }
    if (message.contains('weak-password')) return 'Password is too weak.';
    if (message.contains('network-request-failed')) {
      return 'Please check your internet connection.';
    }
    if (message.contains('email-not-verified')) {
      return 'Please verify your email address before signing in.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildAuthCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      shadowColor: AppColors.primary.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppLogo(context),
              Text(
                _isLogin ? 'Welcome Back!' : 'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.lightText
                      : AppColors.darkText,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Sign in to continue to BullBearNews'
                    : 'Join BullBearNews today',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.lightText.withOpacity(0.7)
                      : AppColors.darkText.withOpacity(0.7),
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                _buildNameField(),
                const SizedBox(height: 20),
                _buildNicknameField(),
                const SizedBox(height: 20),
              ],
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              if (_isLogin) _buildForgotPasswordButton(),
              if (_errorMessage.isNotEmpty) _buildErrorDisplay(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildAuthModeSwitch(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/image/BBN_logo.png',
          width: 200,
          height: 100,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(
        'Name-Surname',
        Icons.person_outline,
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Please enter your name'
          : null,
    );
  }

  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(
        'Nickname',
        Icons.alternate_email,
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Please enter a nickname'
          : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(
        'E-mail',
        Icons.email_outlined,
      ),
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'E-mail is required';
        if (!value.contains('@') || !value.contains('.')) {
          return 'Enter a valid e-mail address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(
        'Password',
        Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.secondary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (!_isLogin && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData prefixIcon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText.withOpacity(0.7)
            : AppColors.darkText.withOpacity(0.7),
        fontFamily: 'DMSerif',
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.secondary,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.lightText.withOpacity(0.3)
              : AppColors.darkText.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
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
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.primary.withOpacity(0.3)
          : AppColors.whiteText,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _forgotPassword,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: const Text(
          'Forgot Password?',
          style: TextStyle(
            fontFamily: 'DMSerif',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(
                color: Colors.red.shade700,
                fontFamily: 'DMSerif',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.secondary,
            AppColors.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.whiteText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.whiteText,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'DMSerif',
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildAuthModeSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Don\'t have an account?' : 'Already have an account?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.lightText.withOpacity(0.7)
                : AppColors.darkText.withOpacity(0.7),
            fontFamily: 'DMSerif',
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _switchAuthMode,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'DMSerif',
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
