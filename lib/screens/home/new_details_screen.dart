import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final String newsId;

  const NewsDetailScreen({super.key, required this.newsId});

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final NewsService _newsService = NewsService();
  NewsModel? _news;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNewsDetail();
  }

  Future<void> _loadNewsDetail() async {
    setState(() => _isLoading = true);
    try {
      final news = await _newsService.getNewsDetail(widget.newsId);
      setState(() {
        _news = news;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Haber detayı yükleme hatası: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.background
          : Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _news == null
              ? Center(
                  child: Text('Haber bulunamadı',
                      style: TextStyle(color: Colors.white)))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      backgroundColor:
                          Colors.black, // AppBar arka plan rengi siyah
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          children: [
                            Center(
                              child: CachedNetworkImage(
                                imageUrl: _news!.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey[600]),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _news!.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black, // Başlık rengi
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1.5,
                                wordSpacing: 1.5,
                                fontFamily: 'Georgia',
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors
                                        .deepPurple, // Kategori etiketi rengi
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _news!.category,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(Icons.access_time,
                                    size: 16,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black), // Tarih simgesi
                                SizedBox(width: 4),
                                Text(
                                  _formatDate(_news!.publishDate),
                                  style: TextStyle(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black, // Tarih rengi
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            Text(
                              _news!.content,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black, // İçerik rengi
                                height: 1.6,
                                letterSpacing: 0.5,
                                wordSpacing: 0.5,
                                fontFamily: 'Arial',
                                fontStyle: FontStyle.normal,
                              ),
                            ),
                            SizedBox(height: 32),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.deepPurple, // Yazar avatar rengi
                                  child: Text(
                                    _news!.author.isNotEmpty
                                        ? _news!.author[0].toUpperCase()
                                        : 'A',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Author',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors
                                                .black, // Yazar etiketi rengi
                                      ),
                                    ),
                                    Text(
                                      _news!.author,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.2,
                                        fontWeight: FontWeight.bold,

                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black, // Yazar adı rengi
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
