import 'package:bullbearnews/widgets/news_details/app_bar_title.dart';
import 'package:bullbearnews/widgets/news_details/author_card.dart';
import 'package:bullbearnews/widgets/news_details/content_card.dart';
import 'package:bullbearnews/widgets/news_details/custom_back_button.dart';
import 'package:bullbearnews/widgets/news_details/title_card.dart';
import 'package:bullbearnews/widgets/search_user_screen/hero_image.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8);
    final cardColor = isDark ? const Color(0xFF393E46) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46);
    final secondaryTextColor = isDark
        ? const Color(0xFF948979)
        : const Color(0xFF393E46).withOpacity(0.7);

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                ),
              ),
            )
          : _news == null
              ? Center(
                  child: Text(
                    'Haber bulunamadı',
                    style: TextStyle(color: textColor),
                  ),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      floating: false,
                      pinned: true,
                      backgroundColor: isDark
                          ? const Color(0xFF393E46)
                          : const Color(0xFFDFD0B8),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Padding(
                          padding: const EdgeInsets.only(left: 38.0),
                          child: AppBarTitle(
                            textColor: textColor,
                            news: _news,
                          ),
                        ),
                        background: HeroImage(
                          isDark: isDark,
                          news: _news,
                        ),
                        centerTitle: false,
                        titlePadding:
                            const EdgeInsets.only(left: 16, bottom: 16),
                      ),
                      leading: CustomBackButton(
                          cardColor: cardColor, textColor: textColor),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TitleCard(
                              news: _news!,
                              cardColor: cardColor,
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            ContentCard(
                                news: _news!,
                                cardColor: cardColor,
                                textColor: textColor),
                            const SizedBox(height: 16),
                            AuthorCard(
                                news: _news!,
                                cardColor: cardColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
