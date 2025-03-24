import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  bool _hasJoinedRoom = false; // Kullanıcının odaya katılıp katılmadığını tutar

  @override
  void initState() {
    super.initState();
    _checkIfUserJoinedRoom(); // Kullanıcının odaya katılıp katılmadığını kontrol et
  }

  // Kullanıcının odaya katılıp katılmadığını kontrol et
  Future<void> _checkIfUserJoinedRoom() async {
    final currentUser = _chatService.getCurrentUser();
    if (currentUser != null) {
      final roomDoc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .get();

      if (roomDoc.exists) {
        final users = List<String>.from(roomDoc['users'] ?? []);
        setState(() {
          _hasJoinedRoom = users.contains(currentUser.uid);
        });
      }
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && _hasJoinedRoom) {
      _chatService.sendMessage(
        widget.chatRoom.id,
        _messageController.text.trim(),
      );
      _messageController.clear();
    }
  }

  void _joinRoom() async {
    await _chatService.joinRoom(widget.chatRoom.id);
    setState(() {
      _hasJoinedRoom = true; // Kullanıcı odaya katıldı
    });
  }

  void _leaveRoom() {
    _chatService.leaveRoom(widget.chatRoom.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.name),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _leaveRoom,
            icon: Icon(Icons.exit_to_app_sharp),
          ),
        ],
      ),
      body: Column(
        children: [
          // Room description
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.grey[200],
            width: double.infinity,
            child: Text(
              widget.chatRoom.description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),

          // Chat Messages Stream
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getChatMessages(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet.',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to start the conversation!',
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

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  reverse: true,
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final message = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.2),
                                  backgroundImage: message.userProfileImage !=
                                          null
                                      ? NetworkImage(message.userProfileImage!)
                                      : null,
                                  child: message.userProfileImage == null
                                      ? Text(
                                          message.username.isNotEmpty
                                              ? message.username[0]
                                                  .toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.username,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      message.timestamp
                                          .toString()
                                          .substring(0, 16),
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                message.content,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      _chatService.likeMessage(message);
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.thumb_up_alt_outlined,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${message.likes}',
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Kullanıcı odaya katılmadıysa uyarı mesajı ve Join butonu
          if (!_hasJoinedRoom)
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[200],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'You must join the room to send messages.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _joinRoom,
                    child: Text('Join Room'),
                  ),
                ],
              ),
            ),

          // Kullanıcı odaya katıldıysa mesaj yazma kutusu
          if (_hasJoinedRoom)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Enter your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                      backgroundColor: colorScheme.primary,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
