import 'package:bullbearnews/models/chat_message_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';

class MentionText extends StatelessWidget {
  final ChatMessage message;
  final ThemeData theme;

  const MentionText({
    super.key,
    required this.message,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: _buildTextSpan(context),
    );
  }

  TextSpan _buildTextSpan(BuildContext context) {
    final spans = <TextSpan>[];
    final content = message.content;
    final mentionRegex = RegExp(r'@(\w+)');

    int lastIndex = 0;

    for (final match in mentionRegex.allMatches(content)) {
      // Normal metni ekle
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: content.substring(lastIndex, match.start),
          style: TextStyle(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFFDFD0B8)
                : const Color(0xFF222831),
            fontSize: 16,
            fontFamily: 'DMSerif',
          ),
        ));
      }

      // Mention'ı ekle
      final mentionText = match.group(0)!; // @username
      final username = match.group(1)!; // username

      // Mention edilen kullanıcının ID'sini bul - İyileştirilmiş
      String? userId = _findUserIdForMention(username);

      print(
          'Debug - Mention: $mentionText, Username: $username, UserId: $userId');
      print('Debug - MentionedUsers: ${message.mentionedUsers}');

      spans.add(TextSpan(
        text: mentionText,
        style: TextStyle(
          color: userId != null ? theme.colorScheme.secondary : Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'DMSerif',
          decoration:
              userId != null ? TextDecoration.underline : TextDecoration.none,
        ),
        recognizer: userId != null
            ? (TapGestureRecognizer()
              ..onTap = () {
                print('Debug - Navigating to profile: $userId');
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShownProfileScreen(userId: userId),
                    ),
                  );
                } catch (e) {
                  print('Debug - Navigation error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening profile: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              })
            : null,
      ));

      lastIndex = match.end;
    }

    // Kalan metni ekle
    if (lastIndex < content.length) {
      spans.add(TextSpan(
        text: content.substring(lastIndex),
        style: TextStyle(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFFDFD0B8)
              : const Color(0xFF222831),
          fontSize: 16,
          fontFamily: 'DMSerif',
        ),
      ));
    }

    return TextSpan(children: spans);
  }

  String? _findUserIdForMention(String username) {
    // Önce tam eşleşme ara
    for (final entry in message.mentionedUsers.entries) {
      if (entry.value.toLowerCase() == username.toLowerCase()) {
        return entry.key;
      }
    }

    // Eğer tam eşleşme bulunamazsa, kısmi eşleşme dene
    for (final entry in message.mentionedUsers.entries) {
      if (entry.value.toLowerCase().contains(username.toLowerCase()) ||
          username.toLowerCase().contains(entry.value.toLowerCase())) {
        return entry.key;
      }
    }

    return null;
  }
}
