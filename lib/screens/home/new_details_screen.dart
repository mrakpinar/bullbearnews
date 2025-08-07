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
                          padding: const EdgeInsets.only(left: 50.0),
                          child: _buildAppBarTitle(textColor),
                        ),
                        background: _buildHeroImage(isDark),
                        centerTitle: false,
                        titlePadding:
                            const EdgeInsets.only(left: 16, bottom: 16),
                      ),
                      leading: _buildBackButton(cardColor, textColor),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleCard(_news!, cardColor, textColor,
                                secondaryTextColor),
                            const SizedBox(height: 16),
                            _buildContentCard(_news!, cardColor, textColor),
                            const SizedBox(height: 16),
                            _buildAuthorCard(_news!, cardColor, textColor,
                                secondaryTextColor),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBarTitle(Color textColor) {
    return Text(
      _news?.title ?? '',
      style: TextStyle(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
        height: 1.2,
        fontFamily: 'DMSerif',
        fontStyle: FontStyle.normal,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
        decorationStyle: TextDecorationStyle.solid,
        decorationThickness: 1.0,
        wordSpacing: 2.0,
        textBaseline: TextBaseline.alphabetic,
        locale: const Locale('en', 'US'),
        backgroundColor: Colors.transparent,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHeroImage(bool isDark) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _news!.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 300,
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      width: 300,
                      height: 300,
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _news!.imageUrl,
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              clipBehavior: Clip.hardEdge,
            ),
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? const Color(0xFF393E46) : Colors.grey[200],
              child: Icon(
                Icons.image,
                size: 50,
                color: isDark
                    ? const Color(0xFF948979)
                    : const Color(0xFF393E46).withOpacity(0.5),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
                tileMode: TileMode.clamp,
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16.0),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_sharp,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildTitleCard(NewsModel news, Color cardColor, Color textColor,
      Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.3,
              letterSpacing: -0.5,
              fontFamily: 'Mono',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF393E46),
                      const Color(0xFF948979),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  news.category,
                  style: TextStyle(
                    color: const Color(0xFFDFD0B8),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mono',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(news.publishDate),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(NewsModel news, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        news.content,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textColor.withOpacity(0.9),
          height: 1.6,
          fontFamily: 'Mono',
        ),
      ),
    );
  }

  Widget _buildAuthorCard(NewsModel news, Color cardColor, Color textColor,
      Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF393E46),
                  const Color(0xFF948979),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                news.author.isNotEmpty ? news.author[0].toUpperCase() : 'A',
                style: TextStyle(
                  color: const Color(0xFFDFD0B8),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Author',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                news.author,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final Map<DateTime, String> _dateCache = {};

  String _formatDate(DateTime date) {
    return _dateCache[date] ??= '${date.day}.${date.month}.${date.year}';
  }
}
