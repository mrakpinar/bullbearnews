import 'package:bullbearnews/screens/home/new_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/local_storage_service.dart';

class NewsCard extends StatefulWidget {
  final NewsModel news;

  const NewsCard({super.key, required this.news});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Haber resmi
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: widget.news.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[600], size: 48),
                  ),
                ),
              ),

              // Haber içeriği
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori ve tarih
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.news.category,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          _formatDate(widget.news.publishDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Başlık
                    Text(
                      widget.news.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    SizedBox(height: 8),

                    // İçerik
                    Text(
                      widget.news.content,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 12),

                    // Yazar ve okuma butonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(widget.news.author),
                          ],
                        ),
                        Row(
                          children: [
                            _buildSaveButton(),

                            // TextButton(
                            //   onPressed: () {
                            //     Navigator.push(
                            //       context,
                            //       _createRoute(
                            //           NewsDetailScreen(newsId: widget.news.id)),
                            //     );
                            //   },
                            //   style: TextButton.styleFrom(
                            //     padding: EdgeInsets.symmetric(
                            //         horizontal: 12, vertical: 6),
                            //     minimumSize: Size(0, 0),
                            //   ),
                            //   child: Row(
                            //     children: [
                            //       Text(
                            //         'Read more',
                            //         style: TextStyle(
                            //           fontSize: 12,
                            //           fontWeight: FontWeight.bold,
                            //         ),
                            //       ),
                            //       SizedBox(width: 4),
                            //       Icon(Icons.arrow_forward, size: 14),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return FutureBuilder<bool>(
      future: LocalStorageService.isNewsSaved(widget.news.id),
      builder: (context, snapshot) {
        final isSaved = snapshot.data ?? false;
        return IconButton(
          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: _toggleSave,
        );
      },
    );
  }

  Future<void> _toggleSave() async {
    try {
      final isSaved = await LocalStorageService.isNewsSaved(widget.news.id);
      if (isSaved) {
        await LocalStorageService.removeNews(widget.news.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from saved')),
        );
      } else {
        await LocalStorageService.saveNews(widget.news);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to saved')),
        );
      }
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(newsId: widget.news.id),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
