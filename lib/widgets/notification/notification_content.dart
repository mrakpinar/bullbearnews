import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';

class NotificationContent extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;
  final bool isDark;
  final int index;
  final Function(String, Map<String, dynamic>, bool) onNotificationTap;

  const NotificationContent({
    super.key,
    required this.notificationId,
    required this.data,
    required this.isDark,
    required this.index,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = data['isRead'] ?? false;
    final type = data['type'] ?? '';
    final senderProfileImage = data['senderProfileImage'] ?? '';
    final createdAt = data['createdAt'] as Timestamp?;

    return Card(
      elevation: 0,
      color: isRead
          ? (isDark ? AppColors.darkCard : AppColors.lightCard)
          : (isDark
              ? AppColors.lightBackground.withOpacity(0.2)
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
        onTap: () => onNotificationTap(notificationId, data, isDark),
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
                      radius: 24,
                      backgroundColor: _getNotificationIconColor(type, isDark),
                      backgroundImage: senderProfileImage.isNotEmpty &&
                              type != NotificationService.NEW_ANNOUNCEMENT_TYPE
                          ? NetworkImage(senderProfileImage)
                          : null,
                      child: senderProfileImage.isEmpty ||
                              type == NotificationService.NEW_ANNOUNCEMENT_TYPE
                          ? Icon(
                              _getNotificationIcon(type),
                              color: Colors.white,
                              size:
                                  type == NotificationService.CHAT_MENTION_TYPE
                                      ? 20
                                      : 24,
                            )
                          : null,
                    ),
                  ),
                  if (!isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNotificationText(data, isDark, type),
                    if (type == NotificationService.CHAT_MENTION_TYPE) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'in "${data['roomName'] ?? 'Chat Room'}"',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondary,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ),
                      if (data['messageContent'] != null &&
                          data['messageContent'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard.withOpacity(0.5)
                                : AppColors.lightCard.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _truncateMessage(data['messageContent'].toString()),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.lightText.withOpacity(0.8)
                                  : AppColors.darkText.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                              fontFamily: 'DMSerif',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                    if (type == NotificationService.NEW_ANNOUNCEMENT_TYPE) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.campaign,
                              size: 12,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Announcement',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data['content'] != null &&
                          data['content'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _truncateMessage(data['content'].toString()),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.lightText.withOpacity(0.9)
                                  : AppColors.darkText.withOpacity(0.9),
                              fontFamily: 'DMSerif',
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                    if (data['walletName'] != null &&
                        type != NotificationService.CHAT_MENTION_TYPE &&
                        type != NotificationService.NEW_ANNOUNCEMENT_TYPE) ...[
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
                    Row(
                      children: [
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
                        if (type == NotificationService.CHAT_MENTION_TYPE) ...[
                          const Spacer(),
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                        ],
                      ],
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

  Widget _buildNotificationText(
      Map<String, dynamic> data, bool isDark, String type) {
    final senderNickname = data['senderNickname'] ?? 'Unknown';

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: type == NotificationService.NEW_ANNOUNCEMENT_TYPE
                ? (data['title'] ?? 'New Announcement')
                : senderNickname,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:
                  type == NotificationService.NEW_ANNOUNCEMENT_TYPE ? 14 : 13,
              color: isDark ? AppColors.lightText : AppColors.darkText,
              fontFamily: 'DMSerif',
            ),
          ),
          if (type != NotificationService.NEW_ANNOUNCEMENT_TYPE)
            TextSpan(
              text: ' ${_getActionText(type)}',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
                color: isDark
                    ? AppColors.lightText.withOpacity(0.8)
                    : AppColors.darkText.withOpacity(0.8),
                fontFamily: 'DMSerif',
              ),
            ),
        ],
      ),
    );
  }

  String _truncateMessage(String message) {
    if (message.length <= 100) return message;
    return '${message.substring(0, 100)}...';
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationService.FOLLOW_TYPE:
        return Icons.person_add;
      case NotificationService.LIKE_PORTFOLIO_TYPE:
        return Icons.favorite;
      case NotificationService.SHARE_PORTFOLIO_TYPE:
        return Icons.share;
      case NotificationService.CHAT_MENTION_TYPE:
        return Icons.alternate_email;
      case NotificationService.NEW_ANNOUNCEMENT_TYPE:
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationIconColor(String type, bool isDark) {
    switch (type) {
      case NotificationService.FOLLOW_TYPE:
        return Colors.blue.shade600;
      case NotificationService.LIKE_PORTFOLIO_TYPE:
        return Colors.red.shade600;
      case NotificationService.SHARE_PORTFOLIO_TYPE:
        return Colors.green.shade600;
      case NotificationService.CHAT_MENTION_TYPE:
        return AppColors.secondary;
      case NotificationService.NEW_ANNOUNCEMENT_TYPE:
        return Colors.orange.shade600;
      default:
        return AppColors.accent;
    }
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
      case NotificationService.CHAT_MENTION_TYPE:
        return 'mentioned you in chat';
      case NotificationService.NEW_ANNOUNCEMENT_TYPE:
        return ''; // Announcement için action text yok
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
