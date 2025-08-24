import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class ForgotPasswordButtonWidget extends StatelessWidget {
  final VoidCallback forgotPassword;
  const ForgotPasswordButtonWidget({super.key, required this.forgotPassword});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: forgotPassword,
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
}
