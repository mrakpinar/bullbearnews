import 'dart:ui';

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
    return AppBar(
      title: GestureDetector(
        onTap: _toggleDescription,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.chatRoom.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline,
              size: 20,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
            ),
            AnimatedRotation(
              turns: _isDescriptionExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
                size: 20,
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 24,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _leaveRoom,
          icon: const Icon(
            Icons.exit_to_app_sharp,
            color: Colors.redAccent,
            size: 24,
          ),
          tooltip: 'Leave Room',
        ),
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
      // Performance optimization
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
                if (!isCurrentUser) _buildAvatar(),
                _buildMessageBubble(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Padding(
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
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                message.username,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[200]
                      : Colors.grey[800],
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
            // width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]!
                : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[100]
                        : Colors.grey[800],
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
