import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class NicknameFieldWidget extends StatelessWidget {
  final TextEditingController nicknameController;
  const NicknameFieldWidget({super.key, required this.nicknameController});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: nicknameController,
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
        context,
        'Nickname',
        Icons.alternate_email,
      ),
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Please enter a nickname'
          : null,
    );
  }

  InputDecoration _buildInputDecoration(
      BuildContext context, String label, IconData prefixIcon,
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
}
