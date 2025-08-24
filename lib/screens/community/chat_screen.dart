import 'dart:async';
import 'dart:ui';
import 'package:bullbearnews/widgets/community/chat/chat_room_banned_prompt.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_info_dialog.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_join_prompt.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_leave_confirm_dialog.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_report_dialog.dart';
import 'package:bullbearnews/widgets/community/chat/empty_message_states.dart';
import 'package:bullbearnews/widgets/community/chat/reply_preview.dart';
import 'package:bullbearnews/widgets/community/chat/swipe_to_reply_wrapper.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';
import '../../widgets/community/chat/message_card.dart';
import '../../widgets/community/chat/message_input.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String? highlightMessageId; // YENİ: Highlight edilecek mesaj ID'si

  const ChatScreen({
    super.key,
    required this.chatRoom,
    this.highlightMessageId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _highlightedMessageId;
  Timer? _highlightTimer;
  bool _hasJoinedRoom = false;
  bool _isUserBanned = false;
  bool _isLoading = true;
  ChatMessage? _replyToMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    _checkUserStatus();

    // Highlight edilecek mesaj varsa
    if (widget.highlightMessageId != null) {
      _highlightedMessageId = widget.highlightMessageId;

      // 2 saniye sonra scroll et ve highlight et
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          // 5 saniye sonra highlight'ı kaldır
          _highlightTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() {
                _highlightedMessageId = null;
              });
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    _highlightTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkUserStatus() async {
    final currentUser = _chatService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasJoinedRoom = false;
        });
      }
      return;
    }

    try {
      final isBanned = await _chatService.isUserBannedFromRoom(
        currentUser.uid,
        widget.chatRoom.id,
      );

      // ChatService'ten güncel room bilgisini al
      final updatedRoom = await _chatService.getChatRoom(widget.chatRoom.id);
      final hasJoined = updatedRoom?.users.contains(currentUser.uid) ?? false;

      if (mounted) {
        setState(() {
          _isUserBanned = isBanned;
          _hasJoinedRoom = hasJoined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error checking user status: $e');
    }
  }

  void _scrollToHighlightedMessage(List<ChatMessage> messages) {
    if (_highlightedMessageId == null) return;

    // Mesajı listede bul
    final messageIndex = messages.indexWhere(
      (msg) => msg.id == _highlightedMessageId,
    );

    if (messageIndex != -1) {
      // ListView reverse=true olduğu için index'i tersine çevir
      final scrollIndex = messages.length - 1 - messageIndex;

      // Mesaja scroll et (her mesaj için ortalama yükseklik)
      const itemHeight = 120.0; // Tahmini mesaj yüksekliği
      final scrollOffset = scrollIndex * itemHeight;

      _scrollController.animateTo(
        scrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_isUserBanned) return;
    if (!_hasJoinedRoom) {
      _showJoinRoomDialog();
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        widget.chatRoom.id,
        content,
        replyToMessage: _replyToMessage,
      );

      // Reply'i temizle
      if (_replyToMessage != null) {
        setState(() {
          _replyToMessage = null;
        });
      }

      // Mesaj gönderildikten sonra aşağı scroll
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _handleReply(ChatMessage message) {
    setState(() {
      _replyToMessage = message;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  Future<void> _joinRoom() async {
    try {
      await _chatService.joinRoom(widget.chatRoom.id);

      if (mounted) {
        setState(() {
          _hasJoinedRoom = true; // UI'ı hemen güncelle
        });
      }

      // Status kontrolü yapmayın, çünkü UI zaten güncellenmiş
      // await _checkUserStatus(); // Bu satırı kaldırın veya yorum yapın
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining room: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _leaveRoom() async {
    try {
      await _chatService.leaveRoom(widget.chatRoom.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving room: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF393E46)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Join Room',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFDFD0B8)
                : const Color(0xFF222831),
            fontFamily: 'DMSerif',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You need to join "${widget.chatRoom.name}" to send messages.',
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
              _joinRoom();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Join',
              style: TextStyle(
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => ChatRoomReportDialog(
        message: message,
        onReport: (reason) async {
          try {
            await _chatService.reportMessage(
              roomId: widget.chatRoom.id,
              messageId: message.id,
              messageContent: message.content,
              messageUserId: message.userId,
              messageUserName: message.username,
              reason: reason,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message reported successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error reporting message: $e'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading chat...',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Banned user ekranı
    if (_isUserBanned) {
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
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            widget.chatRoom.name,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            Text(
              '${widget.chatRoom.users.length} members',
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF393E46).withOpacity(0.8)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: isDark ? const Color(0xFF393E46) : Colors.white,
              onSelected: (value) {
                switch (value) {
                  case 'leave':
                    _showLeaveConfirmDialog();
                    break;
                  case 'info':
                    _showRoomInfoDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Room Info',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFDFD0B8)
                              : const Color(0xFF222831),
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasJoinedRoom)
                  PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          color: Colors.red[600],
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Leave Room',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // ChatScreen build metodundaki body kısmını şu şekilde güncelleyin:

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Reply preview (sadece katılan kullanıcılar için)

            // Messages list
            Expanded(
              child: Stack(
                children: [
                  // Ana mesaj listesi
                  StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.getChatMessages(widget.chatRoom.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading messages',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red[400],
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return EmptyMessagesState(
                          theme: Theme.of(context),
                          colorScheme: colorScheme,
                        );
                      }

                      final messages = snapshot.data!;

                      // Highlight edilecek mesajı bul ve scroll et
                      if (_highlightedMessageId != null && _hasJoinedRoom) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToHighlightedMessage(messages);
                        });
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isHighlighted =
                              _highlightedMessageId == message.id;

                          return AnimatedContainer(
                            duration:
                                Duration(milliseconds: 300 + (index * 50)),
                            curve: Curves.easeOutBack,
                            child: SwipeToReplyWrapper(
                              onReply: _hasJoinedRoom
                                  ? () => _handleReply(message)
                                  : null,
                              child: MessageCard(
                                message: message,
                                isCurrentUser:
                                    _chatService.isCurrentUser(message.userId),
                                hasJoinedRoom: _hasJoinedRoom,
                                theme: Theme.of(context),
                                colorScheme: colorScheme,
                                isHighlighted: isHighlighted && _hasJoinedRoom,
                                onReport: () => _showReportDialog(message),
                                onReply: (msg) => _handleReply(msg),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Blur overlay for non-members
                  if (!_hasJoinedRoom)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          color: isDark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.3),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 48,
                                  color: isDark
                                      ? const Color(0xFF948979)
                                      : Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Join the room to see messages',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFDFD0B8)
                                        : const Color(0xFF222831),
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Messages are hidden until you join',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFF948979)
                                        : Colors.grey[600],
                                    fontFamily: 'DMSerif',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_replyToMessage != null && _hasJoinedRoom)
              ReplyPreview(
                message: _replyToMessage!,
                onCancel: _cancelReply,
                theme: Theme.of(context),
              ),

            // Message input veya Join prompt
            if (_hasJoinedRoom)
              MessageInput(
                controller: _messageController,
                focusNode: _focusNode,
                onSend: _sendMessage,
                theme: Theme.of(context),
                colorScheme: colorScheme,
                roomId: widget.chatRoom.id,
              )
            else
              ChatRoomJoinPrompt(
                onJoin: _joinRoom,
                theme: Theme.of(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showLeaveConfirmDialog() {
    showDialog(
        context: context,
        builder: (context) => ChatRoomLeaveConfirmDialog(
              chatRoom: widget.chatRoom,
              leaveRoom: _leaveRoom,
            ));
  }

  void _showRoomInfoDialog() {
    showDialog(
        context: context,
        builder: (context) => ChatRoomInfoDialog(chatRoom: widget.chatRoom));
  }
}
