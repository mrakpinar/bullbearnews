import 'package:bullbearnews/widgets/auth/auth_card_widget.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';

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
          // Kayıt başarılı - direkt ana sayfaya yönlendir
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Registration successful! Welcome to BullBearNews.'),
              backgroundColor: Colors.green.shade700,
            ),
          );

          // Ana sayfaya yönlendir
          Navigator.of(context).pushReplacementNamed('/main');
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
                child: AuthCardWidget(
                  emailController: _emailController,
                  nameController: _nameController,
                  nicknameController: _nicknameController,
                  passwordController: _passwordController,
                  errorMessage: _errorMessage,
                  forgotPassword: _forgotPassword,
                  formKey: _formKey,
                  isLoading: _isLoading,
                  isLogin: _isLogin,
                  submitForm: _submitForm,
                  switchAuthMode: _switchAuthMode,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
