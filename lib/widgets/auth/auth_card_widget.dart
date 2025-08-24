import 'package:bullbearnews/constants/colors.dart';
import 'package:bullbearnews/widgets/auth/app_logo_widget.dart';
import 'package:bullbearnews/widgets/auth/auth_mode_switch_widget.dart';
import 'package:bullbearnews/widgets/auth/email_field_widget.dart';
import 'package:bullbearnews/widgets/auth/error_display_widget.dart';
import 'package:bullbearnews/widgets/auth/forgot_password_button_widget.dart';
import 'package:bullbearnews/widgets/auth/name_field_widget.dart';
import 'package:bullbearnews/widgets/auth/nickname_field_widget.dart';
import 'package:bullbearnews/widgets/auth/password_field_widget.dart';
import 'package:bullbearnews/widgets/auth/submit_button_widget.dart';
import 'package:flutter/material.dart';

class AuthCardWidget extends StatelessWidget {
  final bool isLogin;
  final bool isLoading;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController nicknameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback forgotPassword;
  final VoidCallback submitForm;
  final VoidCallback switchAuthMode;

  final String errorMessage;

  const AuthCardWidget(
      {super.key,
      required this.isLogin,
      required this.formKey,
      required this.nameController,
      required this.nicknameController,
      required this.emailController,
      required this.passwordController,
      required this.forgotPassword,
      required this.errorMessage,
      required this.isLoading,
      required this.submitForm,
      required this.switchAuthMode});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkCard
          : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      shadowColor: AppColors.primary.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogoWidget(),
              Text(
                isLogin ? 'Welcome Back!' : 'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.lightText
                      : AppColors.darkText,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Sign in to continue to BullBearNews'
                    : 'Join BullBearNews today',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.lightText.withOpacity(0.7)
                      : AppColors.darkText.withOpacity(0.7),
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 32),
              if (!isLogin) ...[
                NameFieldWidget(
                  nameController: nameController,
                ),
                const SizedBox(height: 20),
                NicknameFieldWidget(
                  nicknameController: nicknameController,
                ),
                const SizedBox(height: 20),
              ],
              EmailFieldWidget(
                emailController: emailController,
              ),
              const SizedBox(height: 20),
              PasswordFieldWidget(
                isLogin: isLogin,
                passwordController: passwordController,
              ),
              if (isLogin)
                ForgotPasswordButtonWidget(
                  forgotPassword: forgotPassword,
                ),
              if (errorMessage.isNotEmpty)
                ErrorDisplayWidget(
                  errorMessage: errorMessage,
                ),
              const SizedBox(height: 32),
              SubmitButtonWidget(
                isLoading: isLoading,
                submitForm: submitForm,
              ),
              const SizedBox(height: 24),
              AuthModeSwitchWidget(
                isLogin: isLoading,
                switchAuthMode: switchAuthMode,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
