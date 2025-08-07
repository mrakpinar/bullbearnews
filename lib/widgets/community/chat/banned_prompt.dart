import 'package:flutter/material.dart';

class BannedPrompt extends StatelessWidget {
  final ThemeData theme;

  const BannedPrompt({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.red.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 32,
            color: Colors.red[600],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are banned !!!',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'You cannot send messages or join the room.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
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
}
