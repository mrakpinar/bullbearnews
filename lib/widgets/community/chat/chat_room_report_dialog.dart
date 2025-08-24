import 'package:bullbearnews/models/chat_message_model.dart';
import 'package:flutter/material.dart';

class ChatRoomReportDialog extends StatefulWidget {
  final ChatMessage message;
  final Function(String reason) onReport;

  const ChatRoomReportDialog({
    super.key,
    required this.message,
    required this.onReport,
  });

  @override
  State<ChatRoomReportDialog> createState() => _ChatRoomReportDialogState();
}

class _ChatRoomReportDialogState extends State<ChatRoomReportDialog> {
  String? _selectedReason;
  final TextEditingController _customReasonController = TextEditingController();

  final List<String> _reportReasons = [
    'Spam',
    'Harassment',
    'Inappropriate content',
    'Hate speech',
    'Violence',
    'False information',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF393E46) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.report,
            color: Colors.red[600],
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Report Message',
              style: TextStyle(
                fontFamily: 'DMSerif',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[800]?.withOpacity(0.5)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${widget.message.username}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.message.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Why are you reporting this message?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _reportReasons.length,
              (index) {
                final reason = _reportReasons[index];
                return RadioListTile<String>(
                  title: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: Colors.red[600],
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              },
            ),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Please specify the reason...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontFamily: 'DMSerif',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.red[600]!,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF222831),
                  fontFamily: 'DMSerif',
                ),
              ),
            ],
          ],
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
          onPressed: _selectedReason != null
              ? () {
                  final reason = _selectedReason == 'Other'
                      ? _customReasonController.text.trim()
                      : _selectedReason!;

                  if (reason.isNotEmpty) {
                    Navigator.pop(context);
                    widget.onReport(reason);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Report',
            style: TextStyle(
              fontFamily: 'DMSerif',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
