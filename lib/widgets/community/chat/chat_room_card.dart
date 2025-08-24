import 'package:bullbearnews/screens/community/chat_screen.dart';
import 'package:flutter/material.dart';
import '../../../../models/chat_room_model.dart';
import '../../../../services/chat_service.dart';

class ChatRoomCard extends StatefulWidget {
  final ChatRoom room;
  final bool isDark;

  const ChatRoomCard({super.key, required this.room, required this.isDark});

  @override
  State<ChatRoomCard> createState() => _ChatRoomCardState();
}

class _ChatRoomCardState extends State<ChatRoomCard> {
  final ChatService _chatService = ChatService();
  bool _isUserBanned = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBanStatus();
  }

  Future<void> _checkBanStatus() async {
    final currentUser = _chatService.getCurrentUser();
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final isBanned = await _chatService.isUserBannedFromRoom(
          currentUser.uid, widget.room.id);
      if (mounted) {
        setState(() {
          _isUserBanned = isBanned;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error checking ban status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _chatService.getCurrentUser();
    final hasJoined =
        currentUser != null && widget.room.users.contains(currentUser.uid);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive padding and sizing
    final cardPadding = screenWidth < 360 ? 12.0 : 16.0;
    final iconSize = screenWidth < 360 ? 24.0 : 12.0;
    final titleFontSize = screenWidth < 360 ? 14.0 : 16.0;
    final descriptionFontSize = screenWidth < 360 ? 11.0 : 12.0;
    final statusFontSize = screenWidth < 360 ? 9.0 : 10.0;
    final buttonHeight = screenWidth < 360 ? 28.0 : 32.0;

    return Card(
      elevation: widget.isDark ? 4 : 2,
      margin: const EdgeInsets.all(2.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _isUserBanned
              ? Colors.red.withOpacity(0.3)
              : widget.isDark
                  ? const Color(0xFF948979).withOpacity(0.1)
                  : const Color(0xFF393E46).withOpacity(0.1),
          width: _isUserBanned ? 1.5 : 0.5,
        ),
      ),
      color: _isUserBanned
          ? (widget.isDark
              ? const Color(0xFF393E46).withOpacity(0.7)
              : Colors.white.withOpacity(0.7))
          : (widget.isDark ? const Color(0xFF393E46) : Colors.white),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.room.isActive && !_isUserBanned
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatRoom: widget.room),
                    ),
                  )
              : _isUserBanned
                  ? () => _showBanDialog(context)
                  : null,
          borderRadius: BorderRadius.circular(20),
          splashColor: _isUserBanned
              ? Colors.red.withOpacity(0.1)
              : (widget.isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831))
                  .withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: _isUserBanned
                            ? null
                            : widget.room.isActive
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF948979),
                                      const Color(0xFF393E46),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                        color: _isUserBanned
                            ? Colors.red.withOpacity(0.2)
                            : !widget.room.isActive
                                ? Colors.grey.withOpacity(0.3)
                                : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isUserBanned ? Icons.block : Icons.chat_bubble_outline,
                        color: _isUserBanned
                            ? Colors.red[600]
                            : widget.room.isActive
                                ? const Color(0xFFDFD0B8)
                                : Colors.grey,
                        size: iconSize,
                      ),
                    ),
                    const Spacer(),
                    _buildStatusBadge(statusFontSize),
                  ],
                ),

                const SizedBox(height: 12),

                // Title and Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.room.name,
                              style: TextStyle(
                                color: _isUserBanned
                                    ? Colors.red[400]
                                    : widget.room.isActive
                                        ? (widget.isDark
                                            ? const Color(0xFFDFD0B8)
                                            : const Color(0xFF222831))
                                        : Colors.grey,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'DMSerif',
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isUserBanned) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red[400],
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          _isUserBanned
                              ? "You have been banned from this room and your access has been blocked."
                              : widget.room.description,
                          style: TextStyle(
                            color: _isUserBanned
                                ? Colors.red[300]
                                : widget.isDark
                                    ? const Color(0xFF948979)
                                    : const Color(0xFF393E46),
                            fontFamily: 'DMSerif',
                            fontSize: descriptionFontSize,
                            height: 1.3,
                            fontStyle: _isUserBanned ? FontStyle.italic : null,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bottom Section
                _buildBottomSection(hasJoined, statusFontSize, buttonHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(double statusFontSize) {
    if (_isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),
        ),
      );
    }

    if (_isUserBanned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              color: Colors.red[600],
              size: 10,
            ),
            const SizedBox(width: 4),
            Text(
              'Banned',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: statusFontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      );
    }

    if (widget.room.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4CAF50),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Active',
              style: TextStyle(
                color: const Color(0xFF4CAF50),
                fontSize: statusFontSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSerif',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock,
            color: Colors.grey,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            'Closed',
            style: TextStyle(
              color: Colors.grey,
              fontSize: statusFontSize,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
      bool hasJoined, double statusFontSize, double buttonHeight) {
    if (_isUserBanned) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              color: Colors.red[600],
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Access denied',
              style: TextStyle(
                color: Colors.red[600],
                fontFamily: 'DMSerif',
                fontSize: statusFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!widget.room.isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Room is inactive',
              style: TextStyle(
                color: Colors.grey,
                fontFamily: 'DMSerif',
                fontSize: statusFontSize,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Members count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isDark
                ? const Color(0xFF948979).withOpacity(0.2)
                : const Color(0xFF393E46).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.room.users.isEmpty
                    ? Icons.group_off
                    : widget.room.users.length == 1
                        ? Icons.person
                        : Icons.groups_2,
                color: widget.isDark
                    ? const Color(0xFF948979)
                    : const Color(0xFF393E46),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.room.users.length} ${widget.room.users.length == 1 ? 'member' : 'members'}',
                style: TextStyle(
                  color: widget.isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46),
                  fontFamily: 'DMSerif',
                  fontSize: statusFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Join button
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: hasJoined
                ? null
                : () async {
                    try {
                      await _chatService.joinRoom(widget.room.id);
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
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasJoined
                  ? (widget.isDark
                      ? const Color(0xFF948979).withOpacity(0.5)
                      : const Color(0xFF393E46).withOpacity(0.5))
                  : (widget.isDark
                      ? const Color(0xFF948979)
                      : const Color(0xFF393E46)),
              foregroundColor: const Color(0xFFDFD0B8),
              elevation: hasJoined ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasJoined) ...[
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: const Color(0xFFDFD0B8),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  hasJoined ? 'Joined' : 'Join Room',
                  style: TextStyle(
                    color: const Color(0xFFDFD0B8),
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w600,
                    fontSize: statusFontSize + 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:
              widget.isDark ? const Color(0xFF393E46) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.block,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Access denied!',
                  style: TextStyle(
                    color: widget.isDark
                        ? const Color(0xFFDFD0B8)
                        : const Color(0xFF222831),
                    fontFamily: 'DMSerif',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'You are banned from ${widget.room.name}. You have been blocked from accessing this room and cannot send messages.',
            style: TextStyle(
              color: widget.isDark
                  ? const Color(0xFF948979)
                  : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  fontFamily: 'DMSerif',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
