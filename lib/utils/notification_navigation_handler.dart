import 'package:bullbearnews/models/wallet_model.dart';
import 'package:bullbearnews/screens/home/notification_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/profile/shown_profile_screen.dart';
import '../screens/profile/wallet/wallet_detail_screen.dart';

class NotificationNavigationHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final type = data['type'] ?? '';
    final senderId = data['senderId'] ?? '';
    final walletId = data['walletId'] ?? '';

    try {
      switch (type) {
        case 'follow':
          // Takip bildirimi - profil sayfasına git
          if (senderId.isNotEmpty) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShownProfileScreen(userId: senderId),
              ),
            );
          } else {
            // Sender ID yoksa notifications sayfasına git
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          }
          break;

        case 'like_portfolio':
          // Portfolio like bildirimi - notifications sayfasına git
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
          break;

        case 'share_portfolio':
          // Portfolio paylaşım bildirimi - paylaşılan portfolio'ya git
          if (walletId.isNotEmpty && senderId.isNotEmpty) {
            await _navigateToSharedPortfolio(
                context, walletId, senderId, data['walletName'] ?? 'Portfolio');
          } else {
            // Portfolio bilgileri yoksa notifications sayfasına git
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          }
          break;

        default:
          // Bilinmeyen tip - notifications sayfasına git
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
          break;
      }
    } catch (e) {
      print('Navigation error: $e');
      // Hata durumunda notifications sayfasına git
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationsScreen(),
        ),
      );
    }
  }

  static Future<void> _navigateToSharedPortfolio(
    BuildContext context,
    String walletId,
    String senderId,
    String walletName,
  ) async {
    try {
      // Loading dialog göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Portfolio verisini getir
      final walletDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('wallets')
          .doc(walletId)
          .get();

      // Loading dialog'u kapat
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (walletDoc.exists && context.mounted) {
        final wallet =
            Wallet.fromJson(walletDoc.data()!).copyWith(id: walletDoc.id);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WalletDetailScreen(
              wallet: wallet,
              onUpdate: () {},
              isSharedView: true,
            ),
          ),
        );
      } else {
        // Portfolio bulunamadı
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This portfolio is no longer available'),
              backgroundColor: Colors.orange,
            ),
          );

          // Notifications sayfasına git
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading shared portfolio: $e');

      // Loading dialog'u kapat (eğer hala açıksa)
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading portfolio: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Notifications sayfasına git
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      }
    }
  }

  // App badge sayısını güncelle (iOS için)
  static Future<void> updateAppBadge(int count) async {
    try {
      // flutter_app_badger paketi kullanabilirsiniz
      // FlutterAppBadger.updateBadgeCount(count);
    } catch (e) {
      print('Error updating app badge: $e');
    }
  }
}
