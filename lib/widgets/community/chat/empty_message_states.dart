import 'package:flutter/material.dart';

class EmptyMessagesState extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;

  const EmptyMessagesState(
      {super.key, required this.theme, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet.',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start the conversation!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
