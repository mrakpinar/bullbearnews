import 'dart:ui';

import 'package:bullbearnews/screens/profile/shown_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  bool _hasJoinedRoom = false;
  bool _isDescriptionExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late final Stream<List<ChatMessage>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _checkIfUserJoinedRoom();
    _initializeAnimations();
    // Stream'i cache'le
    _messagesStream = _chatService.getChatMessages(widget.chatRoom.id);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserJoinedRoom() async {
    final currentUser = _chatService.getCurrentUser();
    if (currentUser == null) return;

    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoom.id)
          .get();

      if (roomDoc.exists && mounted) {
        final users = List<String>.from(roomDoc['users'] ?? []);
        if (mounted) {
          setState(() => _hasJoinedRoom = users.contains(currentUser.uid));
        }
      }
    } catch (e) {
      // Handle error silently
      debugPrint('Error checking if user joined room: $e');
    }
  }

  void _toggleDescription() {
    setState(() {
      _isDescriptionExpanded = !_isDescriptionExpanded;
    });
    if (_isDescriptionExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_hasJoinedRoom) return;

    _chatService.sendMessage(widget.chatRoom.id, text);
    _messageController.clear();

    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _joinRoom() async {
    try {
      await _chatService.joinRoom(widget.chatRoom.id);
      if (mounted) {
        setState(() => _hasJoinedRoom = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining room: $e')),
        );
      }
    }
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
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildCollapsibleDescription(theme),
          Expanded(child: _buildMessagesStream(theme, colorScheme)),
          if (!_hasJoinedRoom)
            _JoinPrompt(onJoin: _joinRoom, theme: theme)
          else
            _MessageInput(
              controller: _messageController,
              onSend: _sendMessage,
              theme: theme,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: GestureDetector(
        onTap: _toggleDescription,
        child: Row(
          children: [
            Text(
              widget.chatRoom.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            if (_isDescriptionExpanded)
              const Icon(Icons.keyboard_arrow_up_rounded, size: 28)
            else
              const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          ],
        ),
      ),
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(
          Icons.arrow_back_ios_new_sharp,
        ),
      ),
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFF948979),
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
      ),
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _leaveRoom,
          icon: Icon(
            Icons.exit_to_app_sharp,
          ),
        )
      ],
    );
  }

  Widget _buildCollapsibleDescription(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: SizeTransition(
          sizeFactor: _expandAnimation,
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            width: double.infinity,
            child: _DescriptionCard(
              chatRoom: widget.chatRoom,
              theme: theme,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesStream(ThemeData theme, ColorScheme colorScheme) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _EmptyMessagesState(theme: theme, colorScheme: colorScheme);
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(12),
          reverse: true,
          itemCount: snapshot.data!.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            final message = snapshot.data![index];
            return _MessageCard(
              key: ValueKey(message.id),
              message: message,
              isCurrentUser: _chatService.isCurrentUser(message.userId),
              hasJoinedRoom: _hasJoinedRoom,
              theme: theme,
              colorScheme: colorScheme,
            );
          },
        );
      },
    );
  }
}

// Ayrı widget'lar performans için
class _DescriptionCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final ThemeData theme;

  const _DescriptionCard({
    required this.chatRoom,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chatRoom.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total users: ${chatRoom.users.length}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Created at: ${chatRoom.createdAt.toLocal().toString().substring(0, 16)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessagesState extends StatelessWidget {
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _EmptyMessagesState({
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to start the conversation!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  final bool hasJoinedRoom;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MessageCard({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.hasJoinedRoom,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Opacity(
        opacity: hasJoinedRoom ? 1.0 : 1,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: hasJoinedRoom ? 0 : 10,
            sigmaY: hasJoinedRoom ? 0 : 8,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: isCurrentUser
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isCurrentUser) _buildAvatar(context),
                _buildMessageBubble(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShownProfileScreen(userId: message.userId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: colorScheme.primary.withOpacity(0.2),
          backgroundImage: message.userProfileImage != null
              ? NetworkImage(
                  message.userProfileImage!,
                  scale: 1.5,
                )
              : null,
          child: message.userProfileImage == null
              ? Text(
                  message.username.isNotEmpty
                      ? message.username[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ShownProfileScreen(userId: message.userId),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.username,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[200]
                        : Colors.grey[800],
                    fontSize: 16,
                    height: 1.2,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? colorScheme.primary
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isCurrentUser
                    ? const Radius.circular(12)
                    : const Radius.circular(4),
                bottomRight: isCurrentUser
                    ? const Radius.circular(4)
                    : const Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isCurrentUser
                        ? Colors.white
                        : theme.brightness == Brightness.dark
                            ? Colors.grey[200]
                            : Colors.grey[800],
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                _buildMessageFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timestamp.toString().substring(11, 16),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isCurrentUser
                ? Colors.white.withOpacity(0.7)
                : theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (message.likes > 0) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.thumb_up_alt_outlined,
            size: 14,
            color: isCurrentUser
                ? Colors.white.withOpacity(0.7)
                : theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
          ),
          const SizedBox(width: 2),
          Text(
            '${message.likes}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCurrentUser
                  ? Colors.white.withOpacity(0.7)
                  : theme.brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _JoinPrompt extends StatelessWidget {
  final VoidCallback onJoin;
  final ThemeData theme;

  const _JoinPrompt({
    required this.onJoin,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 26.0),
      color: theme.brightness == Brightness.dark
          ? Colors.grey[850]
          : Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 32,
            color: theme.brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'You must join the room to send messages.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: theme.brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[600],
              foregroundColor: Colors.grey[200],
              minimumSize: const Size(120, 40),
            ),
            onPressed: onJoin,
            child: const Text(
              'Join Room',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _MessageInput({
    required this.controller,
    required this.onSend,
    required this.theme,
    required this.colorScheme,
  });

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
