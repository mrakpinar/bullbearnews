import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class SubmitButtonWidget extends StatelessWidget {
  final VoidCallback submitForm;
  final bool isLoading;
  const SubmitButtonWidget(
      {super.key, required this.submitForm, required this.isLoading});

  @override
  Widget build(BuildContext context) {
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
        onPressed: isLoading ? null : submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.whiteText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.whiteText,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                isLoading ? 'SIGN IN' : 'CREATE ACCOUNT',
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
}
