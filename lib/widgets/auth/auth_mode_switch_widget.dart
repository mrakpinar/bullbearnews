import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class AuthModeSwitchWidget extends StatelessWidget {
  final bool isLogin;
  final VoidCallback switchAuthMode;
  const AuthModeSwitchWidget(
      {super.key, required this.isLogin, required this.switchAuthMode});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? 'Don\'t have an account?' : 'Already have an account?',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.lightText.withOpacity(0.7)
                : AppColors.darkText.withOpacity(0.7),
            fontFamily: 'DMSerif',
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: switchAuthMode,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            isLogin ? 'Sign Up' : 'Sign In',
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
