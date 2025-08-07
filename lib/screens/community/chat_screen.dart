import 'package:bullbearnews/widgets/community/chat/banned_prompt.dart';
import 'package:bullbearnews/widgets/community/chat/empty_message_states.dart';
import 'package:bullbearnews/widgets/community/chat/join_prompt.dart';
import 'package:bullbearnews/widgets/community/chat/message_card.dart';
import 'package:bullbearnews/widgets/community/chat/message_input.dart';
import 'package:bullbearnews/widgets/community/chat/reply_preview.dart';
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
  bool _isUserBanned = false;
  bool _isDescriptionExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late final Stream<List<ChatMessage>> _messagesStream;

  // Reply functionality
  ChatMessage? _replyToMessage;
  final FocusNode _textFieldFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _checkIfUserJoinedRoom();
    _checkIfUserBanned();
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
    _textFieldFocus.dispose();
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

  Future<void> _checkIfUserBanned() async {
    final currentUser = _chatService.getCurrentUser();
    if (currentUser == null) return;

    try {
      final isBanned = await _chatService.isUserBannedFromRoom(
          currentUser.uid, widget.chatRoom.id);

      if (mounted) {
        setState(() => _isUserBanned = isBanned);
      }
    } catch (e) {
      debugPrint('Error checking if user is banned: $e');
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

  // Cancel reply
  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_hasJoinedRoom || _isUserBanned) return;

    _chatService.sendMessage(
      widget.chatRoom.id,
      text,
      replyToMessage: _replyToMessage,
    );

    _messageController.clear();
    _cancelReply(); // Reply'i temizle

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
    // Ban kontrolü
    if (_isUserBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu odaya katılamazsınız, yasaklısınız.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  // Raporlama dialog'u
  Future<void> _showReportDialog(ChatMessage message) async {
    final currentUser = _chatService.getCurrentUser();
    if (currentUser == null) return;

    // Kendi mesajını raporlayamaz
    if (message.userId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot report your own message.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedReason;
    final reasons = [
      'Spam',
      'Insult/Profanity',
      'Inappropriate Content',
      'Fraud',
      'Hate Speech',
      'Other',
    ];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Report Message',
                style: TextStyle(
                  fontFamily: 'DMSerif',
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              backgroundColor: Theme.of(context).cardTheme.color,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User: ${message.username}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200]?.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reason for reporting:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.solid,
                      decorationColor: Theme.of(context).colorScheme.secondary,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...reasons.map((reason) => RadioListTile<String>(
                        title: Text(
                          reason,
                          style: TextStyle(
                            fontFamily: 'DMSerif',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        value: reason,
                        groupValue: selectedReason,
                        fillColor: MaterialStateProperty.all(
                          Theme.of(context).colorScheme.secondary,
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                        dense: true,
                      )),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Colors.grey[400]?.withOpacity(0.4))),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason != null
                      ? () async {
                          try {
                            await _chatService.reportMessage(
                              roomId: widget.chatRoom.id,
                              messageId: message.id,
                              messageContent: message.content,
                              messageUserId: message.userId,
                              messageUserName: message.username,
                              reason: selectedReason!,
                            );

                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Message reported successfully.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: Text(
                    'Report',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
          if (_replyToMessage != null)
            ReplyPreview(
              message: _replyToMessage!,
              onCancel: _cancelReply,
              theme: theme,
            ),
          if (_isUserBanned)
            BannedPrompt(theme: theme)
          else if (!_hasJoinedRoom)
            JoinPrompt(onJoin: _joinRoom, theme: theme)
          else
            MessageInput(
              controller: _messageController,
              focusNode: _textFieldFocus,
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
            if (_isUserBanned)
              Icon(
                Icons.block,
                color: Colors.red,
                size: 24,
              )
            else if (_isDescriptionExpanded)
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
        if (!_isUserBanned) // Banned kullanıcılar odadan çıkamaz
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
              isUserBanned: _isUserBanned,
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
          return EmptyMessagesState(theme: theme, colorScheme: colorScheme);
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
            return MessageCard(
              key: ValueKey(message.id),
              message: message,
              isCurrentUser: _chatService.isCurrentUser(message.userId),
              hasJoinedRoom: _hasJoinedRoom && !_isUserBanned,
              theme: theme,
              colorScheme: colorScheme,
              onReport: () => _showReportDialog(message),
              onReply: (ChatMessage replyMessage) {
                // Düzeltildi
                setState(() {
                  _replyToMessage = replyMessage; // State'i güncelle
                });
                _textFieldFocus.requestFocus(); // Text field'e focus ver
              },
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
  final bool isUserBanned;

  const _DescriptionCard({
    required this.chatRoom,
    required this.theme,
    required this.isUserBanned,
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
          color: isUserBanned
              ? Colors.red.withOpacity(0.5)
              : theme.brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUserBanned)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.block,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu odadan yasaklandınız. Mesaj gönderemez ve odaya katılamazsınız.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
