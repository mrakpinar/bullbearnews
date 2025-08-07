import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../models/announcement_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementCard extends StatefulWidget {
  final Announcement announcement;
  final bool isLatest; // En son duyuru mu?

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.isLatest = false,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isNew = false;

  @override
  void initState() {
    super.initState();
    _checkIfNew();
  }

  void _checkIfNew() async {
    final prefs = await SharedPreferences.getInstance();

    // Son görülen duyuru tarihini al
    final lastSeenTimestamp = prefs.getInt('last_seen_announcement_timestamp');
    final lastSeenDateTime = lastSeenTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(lastSeenTimestamp)
        : null;

    // Bu duyuru son görülen tarihten sonra mı oluşturuldu?
    bool isNewerThanLastSeen = lastSeenDateTime == null ||
        widget.announcement.createdAt.isAfter(lastSeenDateTime);

    // Duyuru son 24 saat içerisinde mi oluşturuldu?
    final now = DateTime.now();
    final difference = now.difference(widget.announcement.createdAt);
    bool isWithin24Hours = difference.inHours < 24;

    // Her iki koşul da sağlanıyorsa "yeni" olarak işaretle
    if (isNewerThanLastSeen && isWithin24Hours) {
      setState(() {
        _isNew = true;
      });
    }

    // Eğer bu en son duyuruysa ve görüntülendiyse, son görülen zamanı güncelle
    if (widget.isLatest) {
      _updateLastSeenTimestamp();
    }
  }

  void _updateLastSeenTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_seen_announcement_timestamp',
      widget.announcement.createdAt.millisecondsSinceEpoch,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: theme.cardTheme.color,
      elevation: _isNew ? 4 : 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: _isNew
              ? Colors.orange.withOpacity(0.3)
              : (isDark ? Colors.white24 : Colors.grey.withOpacity(0.2)),
          width: _isNew ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: _isNew
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnnouncementHeader(
                announcement: widget.announcement,
                isNew: _isNew,
              ),
              const SizedBox(height: 12),
              Text(
                widget.announcement.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'DMSerif',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.announcement.content,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontFamily: 'DMSerif',
                ),
              ),
              if (widget.announcement.imageUrl != null) ...[
                const SizedBox(height: 12),
                _AnnouncementImage(imageUrl: widget.announcement.imageUrl!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementHeader extends StatelessWidget {
  final Announcement announcement;
  final bool isNew;

  const _AnnouncementHeader({
    required this.announcement,
    this.isNew = false,
  });

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
        if (isNew) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
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
