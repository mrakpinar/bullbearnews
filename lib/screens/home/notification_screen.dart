import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../constants/colors.dart';
import '../../models/wallet_model.dart';
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
      appBar: AppBar(
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
      ),
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
                      'When someone follows you or likes your\nportfolio, you\'ll see it here',
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
                      child: _buildNotificationContent(
                        notification.id,
                        data,
                        isDark,
                        index,
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

  Widget _buildNotificationContent(
    String notificationId,
    Map<String, dynamic> data,
    bool isDark,
    int index,
  ) {
    final isRead = data['isRead'] ?? false;
    final type = data['type'] ?? '';
    final senderNickname = data['senderNickname'] ?? 'Unknown';
    final senderProfileImage = data['senderProfileImage'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;
    final senderId = data['senderId'] ?? '';

    return Card(
      elevation: 0,
      color: isRead
          ? (isDark
              ? AppColors.darkCard
              : AppColors.lightCard) // Okunmuşsa normal renk
          : (isDark
              ? AppColors.lightBackground
                  .withOpacity(0.2) // Okunmamış dark mode rengi
              : Colors.blue.shade50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead
              ? Colors.transparent
              : AppColors.secondary.withOpacity(0.8),
          width: isRead ? 0 : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!isRead) {
            _notificationService.markAsRead(notificationId);
          }

          if (type == NotificationService.FOLLOW_TYPE) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShownProfileScreen(userId: senderId),
              ),
            );
          }

          if (type == NotificationService.SHARE_PORTFOLIO_TYPE) {
            final walletId = data['walletId'] ?? '';
            final senderId = data['senderId'] ?? '';

            if (walletId.isNotEmpty && senderId.isNotEmpty) {
              try {
                final walletDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(senderId)
                    .collection('wallets')
                    .doc(walletId)
                    .get();

                if (walletDoc.exists && mounted) {
                  final wallet = Wallet.fromJson(walletDoc.data()!)
                      .copyWith(id: walletDoc.id);

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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('This portfolio is no longer available'),
                        backgroundColor: Colors.orange.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error loading portfolio: $e'),
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
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isRead ? Colors.transparent : AppColors.secondary,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accent.withOpacity(0.3),
                      backgroundImage: senderProfileImage.isNotEmpty
                          ? NetworkImage(senderProfileImage)
                          : null,
                      child: senderProfileImage.isEmpty
                          ? Icon(
                              Icons.person,
                              color: AppColors.secondary,
                              size: 28,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: senderNickname,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.lightText
                                  : AppColors.darkText,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                          TextSpan(
                            text: ' ${_getActionText(type)}',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.lightText.withOpacity(0.8)
                                  : AppColors.darkText.withOpacity(0.8),
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (data['walletName'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${data['walletName']}"',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.secondary,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatTimeAgo(createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.lightText.withOpacity(0.6)
                            : AppColors.darkText.withOpacity(0.6),
                        fontFamily: 'DMSerif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getActionText(String type) {
    switch (type) {
      case NotificationService.FOLLOW_TYPE:
        return 'started following you';
      case NotificationService.UNFOLLOW_TYPE:
        return 'stopped following you';
      case NotificationService.LIKE_PORTFOLIO_TYPE:
        return 'liked your portfolio';
      case NotificationService.SHARE_PORTFOLIO_TYPE:
        return 'shared a new portfolio';
      default:
        return 'sent you a notification';
    }
  }

  String _formatTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
