import 'package:flutter/material.dart';

class JoinPrompt extends StatelessWidget {
  final VoidCallback onJoin;
  final ThemeData theme;
  const JoinPrompt({super.key, required this.onJoin, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
      color: theme.brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 32,
            color: theme.brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'You must join the room to send messages.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[600],
              foregroundColor: Colors.grey[200],
              minimumSize: const Size(120, 40),
            ),
            onPressed: onJoin,
            child: const Text(
              'Join Room',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
