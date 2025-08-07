import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../constants/colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String? email;
  final String? password;

  const EmailVerificationScreen({
    super.key,
    this.email,
    this.password,
  });

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Timer? _timer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final isVerified = await _authService.checkEmailVerification(
        email: widget.email,
        password: widget.password,
      );
      if (isVerified && mounted) {
        timer.cancel();
        // Email doğrulandı, ana sayfaya yönlendir
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resendEmailVerification(
        email: widget.email,
        password: widget.password,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email sent!'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      // 60 saniye bekleme süresi başlat
      setState(() => _resendCooldown = 60);
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown > 0) {
          setState(() => _resendCooldown--);
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayEmail = widget.email ??
        _authService.currentUser?.email ??
        'your-email@example.com';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCard
                      : AppColors.lightCard,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                  elevation: 12,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 60,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Verify Your Email',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.lightText
                                    : AppColors.darkText,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email address
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  displayEmail,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'We sent a verification link to your email address. Please check your inbox and click the link to verify your account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.lightText.withOpacity(0.7)
                                    : AppColors.darkText.withOpacity(0.7),
                            fontFamily: 'DMSerif',
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Resend button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: _resendCooldown > 0
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey.withOpacity(0.5),
                                      Colors.grey.withOpacity(0.3),
                                    ],
                                  )
                                : LinearGradient(
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.secondary.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            boxShadow: _resendCooldown > 0
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          AppColors.secondary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: (_isLoading || _resendCooldown > 0)
                                ? null
                                : _resendVerificationEmail,
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
                                    _resendCooldown > 0
                                        ? 'RESEND IN ${_resendCooldown}s'
                                        : 'RESEND VERIFICATION EMAIL',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'DMSerif',
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Status indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue.shade600),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Checking verification status...',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontFamily: 'DMSerif',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Back to login
                        TextButton(
                          onPressed: () async {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.of(context)
                                  .pushReplacementNamed('/auth');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                          ),
                          child: const Text(
                            'Back to Sign In',
                            style: TextStyle(
                              fontFamily: 'DMSerif',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
