import 'package:bullbearnews/models/chat_message_model.dart';
import 'package:flutter/material.dart';

class ReplyPreview extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onCancel;
  final ThemeData theme;
  const ReplyPreview(
      {super.key,
      required this.onCancel,
      required this.theme,
      required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.cardTheme.color?.withOpacity(0.5)
            : Colors.grey[200]?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.username}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    fontFamily: 'Mono',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontSize: 16,
                    fontFamily: 'DMSerif',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close,
              size: 20,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
