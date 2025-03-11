import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _email = '';
  String _password = '';
  String _name = '';
  String _nickname = '';
  String _errorMessage = '';

  void _switchAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = '';
    });
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Enter your email address to reset your password. We will send the link to your email address.'),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty ||
                  !emailController.text.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Enter a valid e-mail address')),
                );
                return;
              }

              try {
                await _authService.resetPassword(emailController.text.trim());
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password reset link sent to your e-mail.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await _authService.signIn(_email, _password);
      } else {
        await _authService.signUp(_email, _password, _name, _nickname);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String message = e.toString();

      // Firebase hata mesajlarını daha anlaşılır hale getirme
      if (message.contains('user-not-found')) {
        message = 'Can\'t find a user with this e-mail address.';
      } else if (message.contains('wrong-password')) {
        message = 'Wrong password.';
      } else if (message.contains('email-already-in-use')) {
        message = 'This e-mail address is already in use.';
      } else if (message.contains('weak-password')) {
        message = 'Password is too weak.';
      } else if (message.contains('network-request-failed')) {
        message = 'Please check your internet connection.';
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black26,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: deviceSize.width > 600 ? 500 : deviceSize.width * 0.9,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Uygulama Logo ve Başlık
                        // Icon(
                        //   Icons.newspaper,
                        //   size: 70,
                        //   color: Theme.of(context).colorScheme.primary,
                        // ),
                        // SizedBox(height: 8),
                        Text(
                          'BBN',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 20),

                        // Form Başlığı
                        Text(
                          _isLogin ? 'Login' : 'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 20),

                        // İsim Alanı (sadece kayıt modunda)
                        if (!_isLogin)
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Name-Surname',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 16),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (!_isLogin &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                            onSaved: (value) => _name = value?.trim() ?? '',
                          ),
                        if (!_isLogin) SizedBox(height: 16),
                        // Kullanıcı Adı Alanı (sadece kayıt modunda)
                        if (!_isLogin)
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Nickname',
                              prefixIcon: Icon(Icons.alternate_email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) {
                              if (!_isLogin &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Please enter a nickname';
                              }
                              return null;
                            },
                            onSaved: (value) => _nickname = value?.trim() ?? '',
                          ),
                        if (!_isLogin) SizedBox(height: 16),
                        // E-posta Alanı
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'E-mail is required';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid e-mail address';
                            }
                            return null;
                          },
                          onSaved: (value) => _email = value?.trim() ?? '',
                        ),
                        SizedBox(height: 16),

                        // Şifre Alanı
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          onSaved: (value) => _password = value ?? '',
                        ),

                        // Şifremi Unuttum Butonu (sadece giriş modunda)
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              child: Text('Forgot Password?'),
                            ),
                          ),

                        // Hata Mesajı
                        if (_errorMessage.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            padding: EdgeInsets.all(10),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        SizedBox(height: 24),

                        // Giriş/Kayıt Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    _isLogin ? 'LOGIN' : 'REGISTER',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Mod Değiştirme Satırı
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Don\'t have an account?'
                                  : 'Already have an account?',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            TextButton(
                              onPressed: _switchAuthMode,
                              child: Text(
                                _isLogin ? 'Register' : 'Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
            ),
          ),
        ),
      ),
    );
  }
}
