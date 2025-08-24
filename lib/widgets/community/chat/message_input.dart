import 'package:bullbearnews/widgets/community/chat/user_suggestion.dart';
import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final String roomId;

  const MessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.theme,
    required this.colorScheme,
    required this.roomId,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _showSuggestions = false;
  String _currentMentionQuery = '';
  int _mentionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    if (cursorPosition < 0) return;

    // @ işaretinden sonra mention arama
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = beforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      // @ işaretinden sonraki metin
      final afterAt = beforeCursor.substring(lastAtIndex + 1);

      // Eğer @ işaretinden sonra boşluk yoksa ve alfanumerik karakterler varsa
      if (!afterAt.contains(' ') && afterAt.isNotEmpty) {
        setState(() {
          _showSuggestions = true;
          _currentMentionQuery = afterAt;
          _mentionStartIndex = lastAtIndex;
        });
      } else if (afterAt.isEmpty) {
        // @ işaretinden hemen sonra
        setState(() {
          _showSuggestions = true;
          _currentMentionQuery = '';
          _mentionStartIndex = lastAtIndex;
        });
      } else {
        _hideSuggestions();
      }
    } else {
      _hideSuggestions();
    }
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
      _currentMentionQuery = '';
      _mentionStartIndex = -1;
    });
  }

  void _onUserSelected(String userId, String username) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    // @ işaretinden mention'ın sonuna kadar olan kısmı değiştir
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(cursorPosition);

    final newText = '$beforeMention@$username $afterMention';

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: beforeMention.length + username.length + 2),
    );

    _hideSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        // User suggestions
        if (_showSuggestions)
          UserSuggestionWidget(
            query: _currentMentionQuery,
            roomId: widget.roomId,
            onUserSelected: _onUserSelected,
            theme: widget.theme,
          ),

        // Main input container - ekranla birleşik
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: keyboardHeight > 0
                ? 12
                : (MediaQuery.of(context).padding.bottom + 12),
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C3137) : const Color(0xFFFAFBFC),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? const Color(0xFF404550).withOpacity(0.3)
                    : const Color(0xFFE1E5E9).withOpacity(0.6),
                width: 0.8,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text input field
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 44,
                    maxHeight: screenWidth < 400 ? 120 : 140,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF393E46) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: widget.colorScheme.primary.withOpacity(0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      cursorColor: widget.colorScheme.primary,
                      cursorHeight: 20,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF222831),
                        fontFamily: 'DMSerif',
                        fontSize: 15,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF948979)
                              : Colors.grey[500],
                          fontFamily: 'DMSerif',
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Send button
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.colorScheme.primary,
                      widget.colorScheme.primary.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colorScheme.primary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: widget.onSend,
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
