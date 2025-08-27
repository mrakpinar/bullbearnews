import 'package:bullbearnews/widgets/auth/auth_card_widget.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Text controller'ları late olarak tanımlayalım
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nameController;
  late final TextEditingController _nicknameController;

  bool _isLogin = true;
  bool _isLoading = false;
  String _errorMessage = '';

  // Theme cache için
  bool? _isDark;

  @override
  void initState() {
    super.initState();
    // Controller'ları initState'de initialize edelim
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
    _nicknameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme değişikliklerini cache'leyalim
    _isDark = Theme.of(context).brightness == Brightness.dark;
  }

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

    try {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _buildForgotPasswordDialog(ctx, emailController),
      );
    } finally {
      emailController.dispose(); // Memory leak önleme
    }
  }

  // Dialog widget'ını ayrı metod haline getirelim
  Widget _buildForgotPasswordDialog(
      BuildContext ctx, TextEditingController emailController) {
    return AlertDialog(
      backgroundColor: _isDark! ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Reset Password',
        style: TextStyle(
          color: _isDark! ? AppColors.lightText : AppColors.darkText,
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
              color: _isDark!
                  ? AppColors.lightText.withOpacity(0.7)
                  : AppColors.darkText.withOpacity(0.7),
              fontFamily: 'DMSerif',
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildEmailTextField(emailController),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          style: TextButton.styleFrom(
            foregroundColor: _isDark!
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
          onPressed: () => _handlePasswordReset(ctx, emailController),
          child: const Text('Send Link'),
        ),
      ],
    );
  }

  // Email text field'ını ayrı widget haline getirelim
  Widget _buildEmailTextField(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _isDark! ? AppColors.lightText : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: InputDecoration(
        labelText: 'E-mail',
        labelStyle: TextStyle(
          fontFamily: 'DMSerif',
          color: _isDark!
              ? AppColors.lightText.withOpacity(0.6)
              : AppColors.darkText.withOpacity(0.6),
        ),
        border: _buildInputBorder(),
        enabledBorder: _buildInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.secondary,
            width: 2.0,
          ),
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.secondary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  // Border styling'i ayrı metoda çıkaralım
  OutlineInputBorder _buildInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: _isDark!
            ? AppColors.lightText.withOpacity(0.3)
            : AppColors.darkText.withOpacity(0.3),
        width: 1.0,
      ),
    );
  }

  // Password reset logic'ini ayrı metoda çıkaralım
  Future<void> _handlePasswordReset(
      BuildContext ctx, TextEditingController emailController) async {
    final email = emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      _showSnackBar('Enter a valid e-mail address', isError: true);
      return;
    }

    try {
      await _authService.resetPassword(email);
      if (!mounted) return;

      Navigator.of(ctx).pop();
      _showSnackBar('Password reset link sent to your e-mail.', isError: false);
    } catch (e) {
      if (!mounted) return;

      Navigator.of(ctx).pop();
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }

  // Email validation'ı ayrı metoda çıkaralım
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // SnackBar gösterme metodunu optimize edelim
  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
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
        await _handleSignIn();
      } else {
        await _handleSignUp();
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

  // Sign in logic'ini ayrı metoda çıkaralım
  Future<void> _handleSignIn() async {
    await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  // Sign up logic'ini ayrı metoda çıkaralım
  Future<void> _handleSignUp() async {
    final result = await _authService.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      _nicknameController.text.trim(),
    );

    if (result != null && mounted) {
      _showSnackBar(
        'Registration successful! Welcome to BullBearNews.',
        isError: false,
      );

      // Ana sayfaya yönlendir
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  // Firebase error parsing'i optimize edelim
  static const Map<String, String> _firebaseErrors = {
    'user-not-found': 'Can\'t find a user with this e-mail address.',
    'wrong-password': 'Wrong password.',
    'invalid-credential': 'Wrong password or email.',
    'email-already-in-use': 'This e-mail address is already in use.',
    'weak-password': 'Password is too weak.',
    'network-request-failed': 'Please check your internet connection.',
  };

  String _parseFirebaseError(String message) {
    for (final entry in _firebaseErrors.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
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
