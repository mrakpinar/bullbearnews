import 'package:flutter/material.dart';

class ChatRoomJoinPrompt extends StatelessWidget {
  final VoidCallback onJoin;
  final ThemeData theme;
  const ChatRoomJoinPrompt(
      {super.key, required this.onJoin, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: keyboardHeight > 0
            ? 16
            : (MediaQuery.of(context).padding.bottom + 16),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C3137) : const Color(0xFFFAFBFC),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF404550).withOpacity(0.3)
                : const Color(0xFFE1E5E9).withOpacity(0.6),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Info container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF393E46) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF404550).withOpacity(0.4)
                    : const Color(0xFFE1E5E9).withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 24,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join to Chat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join the room to send messages',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF948979)
                              : Colors.grey[600],
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Join button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              onPressed: onJoin,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Join Room',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
