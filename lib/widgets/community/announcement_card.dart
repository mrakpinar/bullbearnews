import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/announcement_model.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: theme.cardTheme.color,
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnnouncementHeader(announcement: announcement),
            const SizedBox(height: 12),
            Text(
              announcement.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              announcement.content,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
                fontFamily: 'DMSerif',
              ),
            ),
            if (announcement.imageUrl != null) ...[
              const SizedBox(height: 12),
              _AnnouncementImage(imageUrl: announcement.imageUrl!),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnnouncementHeader extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementHeader({required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.campaign, color: Colors.orange[800], size: 24),
        const SizedBox(width: 8),
        Text(
          'ANNOUNCEMENT',
          style: TextStyle(
            letterSpacing: 5,
            color: Colors.orange[800],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          _formatDate(announcement.createdAt),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontStyle: FontStyle.italic,
            fontFamily: 'Barlow',
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).round()} weeks ago';
    }
    if (difference.inDays < 365) {
      return '${(difference.inDays / 30).round()} months ago';
    }

    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class _AnnouncementImage extends StatelessWidget {
  final String imageUrl;

  const _AnnouncementImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showFullImage(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: double.infinity,
          height: 150,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 150,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 150,
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
