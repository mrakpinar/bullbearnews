import 'package:bullbearnews/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        // Bağlantı bekleme durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı oturum açmışsa ana sayfaya, açmamışsa giriş sayfasına yönlendir
        if (snapshot.hasData && snapshot.data != null) {
          return MainNavigationScreen();
        } else {
          return AuthScreen();
        }
      },
    );
  }
}
