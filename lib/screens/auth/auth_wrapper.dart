import 'package:bullbearnews/screens/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();
  final bool showOfflineBanner;

  AuthWrapper({super.key, this.showOfflineBanner = false});

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
          return Stack(
            children: [
              AuthScreen(),
              // Offline banner
              if (showOfflineBanner)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red,
                    child: const Text(
                      'Offline Mode',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        }
      },
    );
  }
}
