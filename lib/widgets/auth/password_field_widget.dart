import 'package:bullbearnews/constants/colors.dart';
import 'package:flutter/material.dart';

class PasswordFieldWidget extends StatefulWidget {
  final TextEditingController passwordController;
  final bool isLogin;

  const PasswordFieldWidget({
    super.key,
    required this.passwordController,
    required this.isLogin,
  });

  @override
  State<PasswordFieldWidget> createState() => _PasswordFieldWidgetState();
}

class _PasswordFieldWidgetState extends State<PasswordFieldWidget> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.passwordController,
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
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (!widget.isLogin && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context) {
    return InputDecoration(
      labelText: 'Password',
      labelStyle: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.lightText.withOpacity(0.7)
            : AppColors.darkText.withOpacity(0.7),
        fontFamily: 'DMSerif',
        fontSize: 14,
      ),
      prefixIcon: const Icon(
        Icons.lock_outline,
        color: AppColors.secondary,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.secondary,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
