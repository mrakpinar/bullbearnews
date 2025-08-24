import 'package:bullbearnews/models/chat_message_model.dart';
import 'package:bullbearnews/widgets/community/chat/mention_text.dart';
import 'package:flutter/material.dart';

class MessageCard extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool hasJoinedRoom;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isHighlighted;
  final VoidCallback onReport;
  final Function(ChatMessage) onReply;

  const MessageCard({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.hasJoinedRoom,
    required this.theme,
    required this.colorScheme,
    this.isHighlighted = false,
    required this.onReport,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      padding: isHighlighted
          ? const EdgeInsets.all(8) // Highlight durumunda extra padding
          : EdgeInsets.zero,
      decoration: isHighlighted
          ? BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.secondary.withOpacity(0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) _buildUserInfo(),
                _buildMessageBubble(context),
                _buildMessageFooter(),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return GestureDetector(
      onLongPress: hasJoinedRoom ? () => _showMessageOptions(context) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? (isCurrentUser
                  ? colorScheme.primary
                      .withOpacity(0.9) // Highlighted + current user
                  : colorScheme.secondary
                      .withOpacity(0.2)) // Highlighted + other user
              : (isCurrentUser
                  ? colorScheme.primary // Normal current user
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[800] // Normal other user (dark)
                      : Colors.grey[200]), // Normal other user (light)
          borderRadius: BorderRadius.circular(16),
          border: message.hasMentions || isHighlighted
              ? Border.all(
                  color: isHighlighted
                      ? colorScheme.secondary.withOpacity(0.8)
                      : Colors.blue.withOpacity(0.5),
                  width: isHighlighted ? 2.0 : 1.5,
                )
              : null,
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasReply) _buildReplyPreview(),
            if (isHighlighted)
              _buildHighlightIndicator(), // Highlight indicator
            if (message.hasMentions)
              MentionText(
                message: message,
                theme: theme,
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser
                      ? Colors.white
                      : theme.brightness == Brightness.dark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                  fontSize: 16,
                  fontFamily: 'DMSerif',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // YENİ: Highlight indicator widget
  Widget _buildHighlightIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.secondary.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.push_pin,
            size: 12,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            'Mentioned',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.secondary,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  // Diğer mevcut method'larınız buraya gelecek...
  Widget _buildAvatar() {
    // Mevcut avatar implementasyonunuz
    return CircleAvatar(
      radius: 16,
      backgroundImage: message.userProfileImage != null &&
              message.userProfileImage!.isNotEmpty
          ? NetworkImage(message.userProfileImage!)
          : null,
      backgroundColor: colorScheme.secondary.withOpacity(0.2),
      child:
          message.userProfileImage == null || message.userProfileImage!.isEmpty
              ? Text(
                  message.username.isNotEmpty
                      ? message.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              : null,
    );
  }

  Widget _buildUserInfo() {
    // Mevcut user info implementasyonunuz
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.username,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.secondary,
          fontFamily: 'DMSerif',
        ),
      ),
    );
  }

  Widget _buildMessageFooter() {
    // Mevcut footer implementasyonunuz
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontFamily: 'DMSerif',
            ),
          ),
          if (message.likes > 0) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.favorite,
              size: 12,
              color: Colors.red[400],
            ),
            const SizedBox(width: 2),
            Text(
              message.likes.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    // Mevcut reply preview implementasyonunuz
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Replying to ${message.replyToUsername ?? "Unknown"}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.secondary,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyToContent ?? '',
            style: TextStyle(
              fontSize: 12,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[700],
              fontStyle: FontStyle.italic,
              fontFamily: 'DMSerif',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.reply, color: colorScheme.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply(message);
              },
            ),
            if (!isCurrentUser)
              ListTile(
                leading: Icon(Icons.report, color: Colors.red[400]),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  onReport();
                },
              ),
          ],
        ),
      ),
    );
  }
}
