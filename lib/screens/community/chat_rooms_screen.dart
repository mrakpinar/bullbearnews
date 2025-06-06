import 'package:bullbearnews/screens/community/chat_screen.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import '../../services/chat_service.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  _ChatRoomsScreenState createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final ChatService _chatService = ChatService();
  late final Stream<List<ChatRoom>> _chatRoomsStream;

  @override
  void initState() {
    super.initState();
    // Stream'i initState'te cache'le
    _chatRoomsStream = _chatService.getChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sohbet Odaları'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatRoomsStream, // Cache'lenmiş stream kullan
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme, colorScheme);
          }

          return _buildChatRoomsList(snapshot.data!, theme, colorScheme);
        },
      ),
    );
  }

  // Empty state widget'ını ayrı method'a çıkar
  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz sohbet odası bulunmuyor',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Yakında yeni odalar eklenecek!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Chat rooms list widget'ını ayrı method'a çıkar
  Widget _buildChatRoomsList(
      List<ChatRoom> rooms, ThemeData theme, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: rooms.length,
      // Performance optimization: addAutomaticKeepAlives ve addRepaintBoundaries
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _ChatRoomCard(
          key: ValueKey(room.id), // Unique key for better performance
          room: room,
          theme: theme,
          colorScheme: colorScheme,
        );
      },
    );
  }
}

// Chat room card'ı ayrı StatelessWidget olarak çıkar
class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ChatRoomCard({
    super.key,
    required this.room,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToChat(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary.withOpacity(0.2),
                child: Icon(
                  Icons.chat,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: room),
      ),
    );
  }
}
