import 'package:bullbearnews/screens/community/chat_screen.dart';
import 'package:bullbearnews/widgets/notification/notification_content.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../constants/colors.dart';
import '../../models/wallet_model.dart';
import '../../models/chat_room_model.dart';
import '../profile/shown_profile_screen.dart';
import '../profile/wallet/wallet_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<QuerySnapshot>(
          stream: _notificationService.getUserNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.secondary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading notifications...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.lightText.withOpacity(0.7)
                            : AppColors.darkText.withOpacity(0.7),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.lightText.withOpacity(0.7)
                            : AppColors.darkText.withOpacity(0.7),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data?.docs ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard.withOpacity(0.5)
                            : AppColors.lightCard.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.lightText.withOpacity(0.5)
                            : AppColors.darkText.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.lightText : AppColors.darkText,
                        fontFamily: 'DMSerif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'When someone follows you, likes your\nportfolio, or mentions you in chat, you\'ll see it here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.lightText.withOpacity(0.7)
                            : AppColors.darkText.withOpacity(0.7),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              color: AppColors.secondary,
              backgroundColor:
                  isDark ? AppColors.darkCard : AppColors.lightCard,
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final data = notification.data() as Map<String, dynamic>;

                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    onDismissed: (direction) async {
                      await _notificationService
                          .deleteNotification(notification.id);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 50)),
                      curve: Curves.easeOutBack,
                      child: NotificationContent(
                        notificationId: notification.id,
                        data: data,
                        isDark: isDark,
                        index: index,
                        onNotificationTap: _handleNotificationTap,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        'Notifications',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.lightText : AppColors.darkText,
          fontFamily: 'DMSerif',
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppColors.lightText : AppColors.darkText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.done_all,
              size: 20,
              color: AppColors.secondary,
            ),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All notifications marked as read'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // Chat room'a navigate etme fonksiyonu
  Future<void> _navigateToChatRoom(
    String roomId,
    String? messageId,
    bool isDark,
  ) async {
    try {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.secondary),
              ],
            ),
          ),
        ),
      );

      // Chat room verilerini Firestore'dan çek
      final roomDoc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(roomId)
          .get();

      // Loading dialog'unu kapat
      Navigator.pop(context);

      if (!roomDoc.exists) {
        _showErrorSnackBar('Chat room not found or no longer available');
        return;
      }

      if (!mounted) return;

      // ChatRoom modelini oluştur
      final chatRoom = ChatRoom.fromFirestore(roomDoc);

      // ChatScreen'e navigate et
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoom: chatRoom,
            highlightMessageId: messageId, // Mesajı highlight et
          ),
        ),
      );
    } catch (e) {
      // Loading dialog'unu kapat (eğer açıksa)
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Error navigating to chat room: $e');
      _showErrorSnackBar('Error loading chat room: ${e.toString()}');
    }
  }

  Future<void> _handleNotificationTap(
    String notificationId,
    Map<String, dynamic> data,
    bool isDark,
  ) async {
    final isRead = data['isRead'] ?? false;
    final type = data['type'] ?? '';
    final senderId = data['senderId'] ?? '';

    // Mark as read if not already read
    if (!isRead) {
      await _notificationService.markAsRead(notificationId);
    }

    // Handle navigation based on notification type
    switch (type) {
      case NotificationService.FOLLOW_TYPE:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShownProfileScreen(userId: senderId),
          ),
        );
        break;

      case NotificationService.CHAT_MENTION_TYPE:
        final roomId = data['roomId'] ?? '';
        final messageId = data['messageId'] ?? '';

        if (roomId.isNotEmpty) {
          await _navigateToChatRoom(roomId, messageId, isDark);
        } else {
          _showErrorSnackBar('Chat room information not available');
        }
        break;

      case NotificationService.NEW_ANNOUNCEMENT_TYPE:
        final title = data['title'] ?? '';
        final content = data['content'] ?? '';

        // Announcement detay sayfasını göster
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.lightText : AppColors.darkText,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.lightText.withOpacity(0.9)
                          : AppColors.darkText.withOpacity(0.9),
                      fontFamily: 'DMSerif',
                      height: 1.5,
                    ),
                  ),
                  if (data['imageUrl'] != null &&
                      data['imageUrl'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        data['imageUrl'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontFamily: 'DMSerif',
                  ),
                ),
              ),
            ],
          ),
        );
        break;

      case NotificationService.SHARE_PORTFOLIO_TYPE:
        final walletId = data['walletId'] ?? '';

        if (walletId.isNotEmpty && senderId.isNotEmpty) {
          try {
            final walletDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(senderId)
                .collection('wallets')
                .doc(walletId)
                .get();

            if (walletDoc.exists && mounted) {
              final wallet =
                  Wallet.fromJson(walletDoc.data()!).copyWith(id: walletDoc.id);

              Navigator.push(
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
              _showErrorSnackBar('This portfolio is no longer available');
            }
          } catch (e) {
            _showErrorSnackBar('Error loading portfolio: $e');
          }
        }
        break;

      case NotificationService.LIKE_PORTFOLIO_TYPE:
        // Portfolio beğeni bildirimi - profil sayfasına git
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShownProfileScreen(userId: senderId),
          ),
        );
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
