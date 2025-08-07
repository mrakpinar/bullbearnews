import 'dart:ui';

import 'package:bullbearnews/models/chat_message_model.dart';
import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:bullbearnews/widgets/community/chat/swipe_to_reply_wrapper.dart';
import 'package:flutter/material.dart';

class MessageCard extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool hasJoinedRoom;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onReport;
  final Function(ChatMessage) onReply;
  const MessageCard({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.hasJoinedRoom,
    required this.theme,
    required this.colorScheme,
    required this.onReport,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Opacity(
        opacity: hasJoinedRoom ? 1.0 : 1,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: hasJoinedRoom ? 0 : 10,
            sigmaY: hasJoinedRoom ? 0 : 8,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SwipeToReplyWrapper(
              onReply: hasJoinedRoom
                  ? () => onReply(message)
                  : null, // message'ı geç
              child: GestureDetector(
                onLongPress:
                    hasJoinedRoom ? () => _showMessageOptions(context) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isCurrentUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!isCurrentUser) _buildAvatar(context),
                    _buildMessageBubble(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.reply,
                color: colorScheme.primary,
              ),
              title: Text(
                'Reply',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReply(message); // message'ı geç
              },
            ),
            ListTile(
              leading: Icon(
                Icons.flag,
                color: Colors.red,
              ),
              title: Text(
                'Report Message!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onReport();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShownProfileScreen(userId: message.userId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primary.withOpacity(0.2),
          backgroundImage: message.userProfileImage != null
              ? NetworkImage(
                  message.userProfileImage!,
                  scale: 1.5,
                )
              : null,
          child: message.userProfileImage == null
              ? Text(
                  message.username.isNotEmpty
                      ? message.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShownProfileScreen(userId: message.userId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[200]
                        : Colors.grey[800],
                    fontSize: 16,
                    height: 1.2,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? colorScheme.primary
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isCurrentUser
                    ? const Radius.circular(12)
                    : const Radius.circular(4),
                bottomRight: isCurrentUser
                    ? const Radius.circular(4)
                    : const Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply preview in message
                if (message.hasReply) _buildReplyPreview(),
                Text(
                  message.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isCurrentUser
                        ? Colors.white
                        : theme.brightness == Brightness.dark
                            ? Colors.grey[200]
                            : Colors.grey[800],
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                _buildMessageFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (isCurrentUser ? Colors.white : colorScheme.primary)
            .withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (isCurrentUser ? Colors.white : colorScheme.primary)
              .withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.white70 : colorScheme.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.replyToUsername ?? 'Unknown User',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.9)
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.replyToContent ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isCurrentUser
                        ? Colors.white.withOpacity(0.7)
                        : theme.brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timestamp.toString().substring(11, 16),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCurrentUser
                ? Colors.white.withOpacity(0.7)
                : theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (message.likes > 0) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.thumb_up_alt_outlined,
            size: 14,
            color: isCurrentUser
                ? Colors.white.withOpacity(0.7)
                : theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
          ),
          const SizedBox(width: 2),
          Text(
            '${message.likes}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCurrentUser
                  ? Colors.white.withOpacity(0.7)
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
