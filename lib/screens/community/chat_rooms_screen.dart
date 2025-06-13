import 'package:bullbearnews/screens/community/chat_screen.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import '../../services/chat_service.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  _ChatRoomsScreenState createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  late final Stream<List<ChatRoom>> _chatRoomsStream;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _chatRoomsStream = _chatService.getChatRooms();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Sohbet Odaları',
          style: TextStyle(
            fontFamily: 'DMSerif',
            color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: bgColor,
        iconTheme: IconThemeData(
          color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
        ),
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: StreamBuilder<List<ChatRoom>>(
              stream: _chatRoomsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return _buildChatRoomsList(snapshot.data!, isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz sohbet odası bulunmuyor',
            style: TextStyle(
              fontFamily: 'DMSerif',
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yakında yeni odalar eklenecek!',
            style: TextStyle(
              fontFamily: 'DMSerif',
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomsList(List<ChatRoom> rooms, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 16),
          child: _ChatRoomCard(
            room: room,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final bool isDark;

  const _ChatRoomCard({
    required this.room,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: isDark ? const Color(0xFF393E46) : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatRoom: room),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF393E46),
                          const Color(0xFF948979),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.name,
                      style: TextStyle(
                        fontFamily: 'DMSerif',
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                room.description,
                style: TextStyle(
                  fontFamily: 'DMSerif',
                  color: isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 16,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${room.users.length} members',
                    style: TextStyle(
                      fontFamily: 'DMSerif',
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
