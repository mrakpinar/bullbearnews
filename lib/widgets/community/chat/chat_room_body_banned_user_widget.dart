import 'package:bullbearnews/models/chat_room_model.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_banned_prompt.dart';
import 'package:flutter/material.dart';

class ChatRoomBodyBannedUserWidget extends StatelessWidget {
  final ChatRoom chatRoom;
  const ChatRoomBodyBannedUserWidget({
    super.key,
    required this.chatRoom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF393E46).withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          chatRoom.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
            fontFamily: 'DMSerif',
          ),
        ),
      ),
      body: ChatRoomBannedPrompt(theme: Theme.of(context)),
    );
  }
}
