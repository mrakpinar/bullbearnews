import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final FocusNode? focusNode;
  const MessageInput(
      {super.key,
      required this.controller,
      required this.onSend,
      required this.theme,
      required this.colorScheme,
      this.focusNode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.black26 : Colors.white30,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white70,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode, // FocusNode'u ekle
                style: TextStyle(
                  fontFamily: 'DMSerif',
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    fontFamily: 'DMSerif',
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF393E46),
                  const Color(0xFF948979),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
