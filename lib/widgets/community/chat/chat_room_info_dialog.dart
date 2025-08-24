import 'package:bullbearnews/models/chat_room_model.dart';
import 'package:flutter/material.dart';

class ChatRoomInfoDialog extends StatelessWidget {
  final ChatRoom chatRoom;

  const ChatRoomInfoDialog({super.key, required this.chatRoom});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF393E46)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              chatRoom.name,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFDFD0B8)
                    : const Color(0xFF222831),
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFDFD0B8)
                  : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            chatRoom.description,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.people,
                size: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${chatRoom.users.length} members',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                chatRoom.isActive ? Icons.check_circle : Icons.block,
                size: 16,
                color: chatRoom.isActive ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                chatRoom.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: chatRoom.isActive ? Colors.green : Colors.red,
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontFamily: 'DMSerif',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
