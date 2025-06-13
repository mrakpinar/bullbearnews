import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/news_model.dart';
import '../../screens/home/new_details_screen.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        ValueListenableBuilder<Box<NewsModel>>(
          valueListenable: Hive.box<NewsModel>('savedNews').listenable(),
          builder: (context, box, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final newsList = box.values.toList();

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
                return _buildNewsCard(context, news);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsModel news) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsDetailScreen(newsId: news.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // News Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // News Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      news.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      news.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${news.publishDate.day}/${news.publishDate.month}/${news.publishDate.year}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Bookmark Icon
              IconButton(
                icon: const Icon(Icons.bookmark,
                    color: Color(0xFF8A2BE2),
                    size: 24,
                    semanticLabel: 'Remove from saved'),
                tooltip: 'Remove from saved',
                onPressed: () async {
                  try {
                    await Hive.box<NewsModel>('savedNews').delete(news.id);
                    // Optionally, you can show a snackbar or toast message
                    // to inform the user that the news has been removed.
                    onRefresh();
                  } catch (e) {
                    // Handle any errors that occur during the deletion
                    // For example, you can show a snackbar or log the error.
                    debugPrint('Error removing news: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
