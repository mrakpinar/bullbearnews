import 'dart:ui';
import 'package:bullbearnews/models/chat_message_model.dart';
import 'package:bullbearnews/models/chat_room_model.dart';
import 'package:bullbearnews/services/chat_service.dart';
import 'package:bullbearnews/widgets/community/chat/empty_message_states.dart';
import 'package:bullbearnews/widgets/community/chat/message_card.dart';
import 'package:bullbearnews/widgets/community/chat/message_input.dart';
import 'package:bullbearnews/widgets/community/chat/chat_room_join_prompt.dart';
import 'package:bullbearnews/widgets/community/chat/reply_preview.dart';
import 'package:bullbearnews/widgets/community/chat/swipe_to_reply_wrapper.dart';
import 'package:flutter/material.dart';

class ChatRoomBodyWidget extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback showLeaveConfirmDialog;
  final VoidCallback showRoomInfoDialog;
  final bool hasJoinedRoom;
  final Animation<double> fadeAnimation;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final FocusNode focusNode;
  final VoidCallback onSendMessage;
  final VoidCallback onJoinRoom;
  final ChatMessage? replyToMessage;
  final VoidCallback? onCancelReply;
  final Function(ChatMessage) onReply;
  final Function(ChatMessage) onReportMessage;
  final String? highlightedMessageId;
  final Function(List<ChatMessage>) onScrollToHighlightedMessage;

  const ChatRoomBodyWidget({
    super.key,
    required this.chatRoom,
    required this.showLeaveConfirmDialog,
    required this.showRoomInfoDialog,
    required this.hasJoinedRoom,
    required this.fadeAnimation,
    required this.scrollController,
    required this.messageController,
    required this.focusNode,
    required this.onSendMessage,
    required this.onJoinRoom,
    this.replyToMessage,
    this.onCancelReply,
    required this.onReply,
    required this.onReportMessage,
    this.highlightedMessageId,
    required this.onScrollToHighlightedMessage,
  });

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
              chatRoom.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            Text(
              '${chatRoom.users.length} members',
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
                    showLeaveConfirmDialog();
                    break;
                  case 'info':
                    showRoomInfoDialog();
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
                if (hasJoinedRoom)
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
      body: FadeTransition(
        opacity: fadeAnimation,
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: Stack(
                children: [
                  // Ana mesaj listesi
                  StreamBuilder<List<ChatMessage>>(
                    stream: chatService.getChatMessages(chatRoom.id),
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
                      if (highlightedMessageId != null && hasJoinedRoom) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          onScrollToHighlightedMessage(messages);
                        });
                      }

                      return ListView.builder(
                        controller: scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isHighlighted =
                              highlightedMessageId == message.id;

                          return AnimatedContainer(
                            duration:
                                Duration(milliseconds: 300 + (index * 50)),
                            curve: Curves.easeOutBack,
                            child: SwipeToReplyWrapper(
                              onReply:
                                  hasJoinedRoom ? () => onReply(message) : null,
                              child: MessageCard(
                                message: message,
                                isCurrentUser:
                                    chatService.isCurrentUser(message.userId),
                                hasJoinedRoom: hasJoinedRoom,
                                theme: Theme.of(context),
                                colorScheme: colorScheme,
                                isHighlighted: isHighlighted && hasJoinedRoom,
                                onReport: () => onReportMessage(message),
                                onReply: (msg) => onReply(msg),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Blur overlay for non-members
                  if (!hasJoinedRoom)
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

            // Reply preview
            if (replyToMessage != null && hasJoinedRoom)
              ReplyPreview(
                message: replyToMessage!,
                onCancel: onCancelReply ?? () {},
                theme: Theme.of(context),
              ),

            // Message input veya Join prompt
            if (hasJoinedRoom)
              MessageInput(
                controller: messageController,
                focusNode: focusNode,
                onSend: onSendMessage,
                theme: Theme.of(context),
                colorScheme: colorScheme,
                roomId: chatRoom.id,
              )
            else
              ChatRoomJoinPrompt(
                onJoin: onJoinRoom,
                theme: Theme.of(context),
              ),
          ],
        ),
      ),
    );
  }
}
