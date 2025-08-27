import 'dart:async';
import 'package:bullbearnews/widgets/community/chat/chat_room_body_banned_user_widget.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_body_loading_widget.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_body_widget.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_info_dialog.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_leave_confirm_dialog.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_report_dialog.dart';
import 'package:flutter/material.dart';
import '../../models/chat_room_model.dart';
import '../../models/chat_message_model.dart';
import '../../services/chat_service.dart';

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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // ChatService instance'ı normal şekilde oluştur
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

  // Cache için değişkenler
  StreamSubscription<List<ChatMessage>>? _messageSubscription;
  Completer<void>? _userStatusCompleter;

  @override
  bool get wantKeepAlive => true; // Widget'ı bellekte tut

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

      // Performans: Timer'ı daha geç başlat
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
    _messageSubscription?.cancel(); // Stream subscription'ı iptal et
    super.dispose();
  }

  // Performans: User status kontrolünü debounce et
  Future<void> _checkUserStatus() async {
    // Eğer zaten bir kontrol devam ediyorsa, bekle
    if (_userStatusCompleter != null && !_userStatusCompleter!.isCompleted) {
      return _userStatusCompleter!.future;
    }

    _userStatusCompleter = Completer<void>();

    final currentUser = _chatService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasJoinedRoom = false;
        });
      }
      _userStatusCompleter!.complete();
      return;
    }

    try {
      // Performans: Paralel olarak hem ban durumu hem de room bilgisini al
      final results = await Future.wait([
        _chatService.isUserBannedFromRoom(currentUser.uid, widget.chatRoom.id),
        _chatService.getChatRoom(widget.chatRoom.id),
      ]);

      final isBanned = results[0] as bool;
      final updatedRoom = results[1] as ChatRoom?;
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
    } finally {
      _userStatusCompleter!.complete();
    }
  }

  // Performans: Scroll işlemini optimize et
  void _scrollToHighlightedMessage(List<ChatMessage> messages) {
    if (_highlightedMessageId == null || !_scrollController.hasClients) return;

    // Performans: Binary search kullan (eğer mesajlar ID'ye göre sıralıysa)
    final messageIndex = messages.indexWhere(
      (msg) => msg.id == _highlightedMessageId,
    );

    if (messageIndex != -1) {
      // ListView reverse=true olduğu için index'i tersine çevir
      final scrollIndex = messages.length - 1 - messageIndex;

      // Performans: ScrollController'ın max extent'ini kontrol et
      const itemHeight = 120.0;
      final scrollOffset = scrollIndex * itemHeight;
      final maxScrollExtent = _scrollController.position.maxScrollExtent;

      _scrollController.animateTo(
        scrollOffset.clamp(0.0, maxScrollExtent),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Performans: Mesaj gönderme işlemini optimize et
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    if (_isUserBanned) return;
    if (!_hasJoinedRoom) {
      _showJoinRoomDialog();
      return;
    }

    // UI'ı hemen güncelle
    final replyToMessage = _replyToMessage;
    _messageController.clear();

    if (_replyToMessage != null) {
      setState(() {
        _replyToMessage = null;
      });
    }

    try {
      await _chatService.sendMessage(
        widget.chatRoom.id,
        content,
        replyToMessage: replyToMessage,
      );

      // Performans: Scroll işlemini optimize et
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // Hata durumunda UI'ı geri al
      if (mounted) {
        _messageController.text = content;
        if (replyToMessage != null) {
          setState(() {
            _replyToMessage = replyToMessage;
          });
        }

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

  // Performans: Callback'leri optimize et
  void _handleReply(ChatMessage message) {
    if (_replyToMessage?.id != message.id) {
      setState(() {
        _replyToMessage = message;
      });
    }
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    if (_replyToMessage != null) {
      setState(() {
        _replyToMessage = null;
      });
    }
  }

  // Performans: Join room işlemini optimize et
  Future<void> _joinRoom() async {
    if (_hasJoinedRoom) return; // Zaten katıldıysa işlem yapma

    try {
      await _chatService.joinRoom(widget.chatRoom.id);

      if (mounted) {
        setState(() {
          _hasJoinedRoom = true;
        });
      }
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

  // Performans: Dialog'ları lazy loading ile optimize et
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

  // Performans: Report dialog'ını optimize et
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
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli

    // Performans: Return widget'ları hemen döndür
    if (_isLoading) {
      return const ChatRoomBodyLoadingWidget();
    }

    if (_isUserBanned) {
      return ChatRoomBodyBannedUserWidget(
        chatRoom: widget.chatRoom,
      );
    }

    return ChatRoomBodyWidget(
      chatRoom: widget.chatRoom,
      showLeaveConfirmDialog: _showLeaveConfirmDialog,
      showRoomInfoDialog: _showRoomInfoDialog,
      hasJoinedRoom: _hasJoinedRoom,
      fadeAnimation: _fadeAnimation,
      scrollController: _scrollController,
      messageController: _messageController,
      focusNode: _focusNode,
      onSendMessage: _sendMessage,
      onJoinRoom: _joinRoom,
      replyToMessage: _replyToMessage,
      onCancelReply: _cancelReply,
      onReply: _handleReply,
      onReportMessage: _showReportDialog,
      highlightedMessageId: _highlightedMessageId,
      onScrollToHighlightedMessage: _scrollToHighlightedMessage,
    );
  }

  void _showLeaveConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => ChatRoomLeaveConfirmDialog(
        chatRoom: widget.chatRoom,
        leaveRoom: _leaveRoom,
      ),
    );
  }

  void _showRoomInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => ChatRoomInfoDialog(
        chatRoom: widget.chatRoom,
      ),
    );
  }
}
