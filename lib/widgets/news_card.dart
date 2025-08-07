import 'package:bullbearnews/screens/home/new_details_screen.dart';
import 'package:bullbearnews/services/firebase_new_saved_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/news_model.dart';

class NewsCard extends StatefulWidget {
  final NewsModel news;

  const NewsCard({super.key, required this.news});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF393E46).withOpacity(0.9),
                          const Color(0xFF222831).withOpacity(0.8),
                        ]
                      : [
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF5F5F5),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _navigateToDetail,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(isDark),
                      _buildContentSection(isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSection(bool isDark) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: CachedNetworkImage(
            imageUrl: widget.news.imageUrl,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF393E46), const Color(0xFF222831)]
                      : [const Color(0xFFDFD0B8), const Color(0xFF948979)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF948979)),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF393E46), const Color(0xFF222831)]
                      : [const Color(0xFFDFD0B8), const Color(0xFF948979)],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFF948979),
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        // Gradient overlay
        Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.1),
              ],
            ),
          ),
        ),
        // Category badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF393E46).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF948979).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.news.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFDFD0B8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        // Save button
        Positioned(
          top: 16,
          right: 16,
          child: _buildSaveButton(),
        ),
      ],
    );
  }

  Widget _buildContentSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.news.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              letterSpacing: -0.5,
              fontFamily: 'DMSerif',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            widget.news.content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              letterSpacing: 0.2,
              fontFamily: 'DMSerif',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Bottom row
          Row(
            children: [
              // Author
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF222831)
                      : const Color(0xFFDFD0B8).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.news.author,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46),
                          fontFamily: 'Mono'),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Date
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(widget.news.publishDate),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Mono',
                      color: isDark
                          ? const Color(0xFF948979)
                          : const Color(0xFF393E46),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseSavedNewsService().getNewsDocumentStream(widget.news.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.hasData && snapshot.data!.exists;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF393E46).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF948979).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleSave,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  color: isSaved
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF948979),
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleSave() async {
    try {
      final firebaseService = FirebaseSavedNewsService();
      final isSaved = await firebaseService.isNewsSaved(widget.news.id);

      if (isSaved) {
        await firebaseService.removeSavedNews(widget.news.id);
        _showSnackBar('Removed from saved', Colors.red);
      } else {
        await firebaseService.saveNews(widget.news);
        _showSnackBar('Added to saved', Colors.green);
      }

      if (mounted) setState(() {});
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NewsDetailScreen(newsId: widget.news.id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
