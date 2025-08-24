import 'package:bullbearnews/models/chat_room_model.dart';
import 'package:flutter/material.dart';

class ChatRoomLeaveConfirmDialog extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback leaveRoom;
  const ChatRoomLeaveConfirmDialog(
      {super.key, required this.chatRoom, required this.leaveRoom});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF393E46)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Leave Room',
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFDFD0B8)
              : const Color(0xFF222831),
          fontFamily: 'DMSerif',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Are you sure you want to leave "${chatRoom.name}"?',
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF948979)
              : const Color(0xFF393E46),
          fontFamily: 'DMSerif',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey[600],
              fontFamily: 'DMSerif',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            leaveRoom();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Leave',
            style: TextStyle(
              fontFamily: 'DMSerif',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
