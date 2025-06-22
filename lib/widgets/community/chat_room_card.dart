import 'package:bullbearnews/screens/community/chat_screen.dart';
import 'package:flutter/material.dart';
import '../../../models/chat_room_model.dart';
import '../../../services/chat_service.dart';

class ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final bool isDark;

  const ChatRoomCard({super.key, required this.room, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currentUser = ChatService().getCurrentUser();
    final hasJoined =
        currentUser != null && room.users.contains(currentUser.uid);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF393E46) : Colors.white,
      child: InkWell(
        onTap: room.isActive
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatRoom: room),
                  ),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: room.isActive
                    ? (isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831))
                    : Colors.grey,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                room.name,
                style: TextStyle(
                  color: room.isActive
                      ? (isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831))
                      : Colors.grey,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  room.description,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                    fontFamily: 'DMSerif',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 1),
              _RoomStatusSection(
                  room: room, hasJoined: hasJoined, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomStatusSection extends StatelessWidget {
  final ChatRoom room;
  final bool hasJoined;
  final bool isDark;

  const _RoomStatusSection({
    required this.room,
    required this.hasJoined,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (!room.isActive) {
      return Column(
        children: [
          _RoomStatusRow(
            icon: Icons.lock,
            text: 'Closed',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Room is inactive',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _RoomStatusRow(
          icon: room.users.isEmpty
              ? Icons.group_off
              : room.users.length == 1
                  ? Icons.person
                  : Icons.groups_2,
          text: '${room.users.length} members',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: hasJoined ? null : () => ChatService().joinRoom(room.id),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            minimumSize: const Size(double.infinity, 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            hasJoined ? 'Joined' : 'Join',
            style: TextStyle(
              color: Color(0xFFDFD0B8),
              fontFamily: hasJoined ? 'Barlow' : 'Mono',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomStatusRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _RoomStatusRow({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            fontFamily: 'DMSerif',
          ),
        ),
      ],
    );
  }
}
