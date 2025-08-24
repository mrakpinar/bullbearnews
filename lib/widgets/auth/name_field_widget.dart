import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class NameFieldWidget extends StatelessWidget {
  final TextEditingController nameController;

  const NameFieldWidget({
    super.key,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: nameController,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText
            : AppColors.darkText,
        fontFamily: 'DMSerif',
      ),
      cursorColor: AppColors.secondary,
      decoration: _buildInputDecoration(context),
      textCapitalization: TextCapitalization.words,
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Please enter your name'
          : null,
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      labelText: 'Name-Surname',
      labelStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText.withOpacity(0.7)
            : AppColors.darkText.withOpacity(0.7),
        fontFamily: 'DMSerif',
        fontSize: 14,
      ),
      prefixIcon: const Icon(
        Icons.person_outline,
        color: AppColors.secondary,
      ),
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
