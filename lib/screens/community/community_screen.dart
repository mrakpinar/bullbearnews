import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import 'chat_screen.dart';
import '../../services/chat_service.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ChatService _chatService = ChatService();
  bool _showInactiveRooms = false; // Toggle to show/hide inactive rooms

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // renk tonu
    final customPurple = const Color(0xFFBB86FC);
    final inactiveColor = Colors.grey; // Color for inactive rooms

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        centerTitle: true,
        elevation: 0,
        actions: [
          // Optional: Add a toggle button to show/hide inactive rooms
          IconButton(
            icon: Icon(
                _showInactiveRooms ? Icons.visibility_off : Icons.visibility),
            tooltip:
                _showInactiveRooms ? 'Hide inactive rooms' : 'Show all rooms',
            onPressed: () {
              setState(() {
                _showInactiveRooms = !_showInactiveRooms;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık alanı (artık sol taraftan 20 padding ile hizalı)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Text(
                'Rooms',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: customPurple,
                ),
              ),
            ),
            Text(
              'Join a conversation in our community rooms',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Expanded(
              child: StreamBuilder<List<ChatRoom>>(
                stream: _chatService.getChatRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: customPurple,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No chat rooms available.'),
                    );
                  }

                  // Filter rooms based on active status if needed
                  final rooms = _showInactiveRooms
                      ? snapshot.data!
                      : snapshot.data!.where((room) => room.isActive).toList();

                  if (rooms.isEmpty) {
                    return const Center(
                      child: Text('No active chat rooms available.'),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: rooms.length,
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      final cardColor = theme.brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.white;

                      // Choose colors based on active status
                      final roomColor =
                          room.isActive ? customPurple : inactiveColor;
                      // final statusText = room.isActive ? 'Active' : 'Passive';

                      // Check if the current user has joined the room
                      final currentUser = _chatService.getCurrentUser();
                      final hasJoined = currentUser != null &&
                          room.users.contains(currentUser.uid);

                      return GestureDetector(
                        onTap: () {
                          // Only allow navigation to active rooms
                          if (room.isActive) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatScreen(chatRoom: room),
                              ),
                            );
                          } else {
                            // Optionally show message for inactive rooms
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('This room is currently inactive.'),
                                backgroundColor: inactiveColor,
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            // 3 boyutlu etkiyi artırmak için daha belirgin gölgeler
                            boxShadow: [
                              BoxShadow(
                                color: roomColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 1,
                                offset: const Offset(5, 6),
                              ),
                              BoxShadow(
                                color: roomColor.withOpacity(0.5),
                                blurRadius: 2,
                                spreadRadius: 0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                            border: Border.all(
                              color: roomColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          // Apply opacity to inactive rooms
                          child: Opacity(
                            opacity: room.isActive ? 1.0 : 0.7,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Oda ikonunu daha belirgin hale getirme
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: roomColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      // İkon konteynerını da 3 boyutlu göstermek için
                                      boxShadow: [
                                        BoxShadow(
                                          color: roomColor.withOpacity(0.1),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.mode_comment_rounded,
                                      color: roomColor,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    room.name,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Text(
                                      room.description,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Katılım sayısı veya aktif kişi göstergesi
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roomColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          room.isActive
                                              ? Icons.person
                                              : Icons.person_off,
                                          size: 14,
                                          color: roomColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${room.users.length} / ${room.activeUsers.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: roomColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: hasJoined
                                        ? null // Disable the button if already joined
                                        : () {
                                            _chatService.joinRoom(room.id);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: roomColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                        hasJoined ? 'Joined' : 'Join Room'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
