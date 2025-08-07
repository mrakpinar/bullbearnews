import 'package:bullbearnews/services/firebase_new_saved_service.dart';
import 'package:flutter/material.dart';
import '../../../models/news_model.dart';
import '../../../screens/home/new_details_screen.dart';

class SavedNewsList extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;

  const SavedNewsList({
    super.key,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final firebaseSavedNewsService = FirebaseSavedNewsService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        StreamBuilder<List<NewsModel>>(
          stream: firebaseSavedNewsService.getSavedNewsStream(),
          builder: (context, snapshot) {
            if (isLoading ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading saved news',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your internet connection and try again',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: onRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final newsList = snapshot.data ?? [];

            if (newsList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No saved articles yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return _buildNewsCard(context, news, firebaseSavedNewsService);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewsCard(
      BuildContext context, NewsModel news, FirebaseSavedNewsService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark
          ? const Color(0xFF393E46).withOpacity(0.8)
          : Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(newsId: news.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // News Image
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    news.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF948979).withOpacity(0.3)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? const Color(0xFF948979)
                                  : const Color(0xFF393E46),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF948979).withOpacity(0.3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46).withOpacity(0.5),
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // News Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      news.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark
                            ? const Color(0xFFDFD0B8)
                            : const Color(0xFF393E46),
                        fontFamily: 'DMSerif',
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withOpacity(0.8),
                            Colors.deepOrange.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        news.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'DMSerif',
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46).withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${news.publishDate.day}/${news.publishDate.month}/${news.publishDate.year}',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46).withOpacity(0.6),
                            fontSize: 12,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Remove Bookmark Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.bookmark,
                    color: Colors.orange,
                    size: 24,
                  ),
                  tooltip: 'Remove from saved',
                  onPressed: () async {
                    try {
                      await service.removeSavedNews(news.id);

                      // Success feedback
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Removed from saved news',
                                    style:
                                        const TextStyle(fontFamily: 'DMSerif'),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }

                      onRefresh();
                    } catch (e) {
                      // Error feedback
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Failed to remove: $e',
                                    style:
                                        const TextStyle(fontFamily: 'DMSerif'),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                      debugPrint('Error removing news: $e');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
