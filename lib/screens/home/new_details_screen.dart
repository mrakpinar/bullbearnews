import 'package:bullbearnews/widgets/error_state_widget.dart';
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
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen>
    with TickerProviderStateMixin {
  final NewsService _newsService = NewsService();

  // State variables
  NewsModel? _news;
  bool _isLoading = true;
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Constants
  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const double _expandedHeight = 300.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadNewsDetail();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _slideController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadNewsDetail() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final news = await _newsService.getNewsDetail(widget.newsId);

      if (mounted) {
        setState(() {
          _news = news;
          _errorMessage = null;
        });

        // Start animations when data is loaded
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      if (kDebugMode) {
        print('News detail loading error: $e');
      }

      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('404')) {
      return 'News article not found';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    } else {
      return 'Failed to load news details. Please try again.';
    }
  }

  Future<void> _retryLoadNews() async {
    await _loadNewsDetail();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _getBackgroundColor(isDark),
      body: _buildBody(isDark),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    return isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8);
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }

    if (_news == null) {
      return _buildNotFoundState(isDark);
    }

    return _buildNewsContent(isDark);
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF393E46).withOpacity(0.3)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading news details...',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Column(
      children: [
        // Simple app bar for error state
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CustomBackButton(
                  cardColor: isDark ? const Color(0xFF393E46) : Colors.white,
                  textColor: isDark
                      ? const Color(0xFFDFD0B8)
                      : const Color(0xFF393E46),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'News Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF222831),
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ErrorStateWidget(
            isDark: isDark,
            errorMessage: _errorMessage,
            onRetry: _retryLoadNews,
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundState(bool isDark) {
    final textColor =
        isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46);

    return Column(
      children: [
        // Simple app bar for not found state
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CustomBackButton(
                  cardColor: isDark ? const Color(0xFF393E46) : Colors.white,
                  textColor: textColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'News Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: 'DMSerif',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF393E46).withOpacity(0.3)
                        : Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'News article not found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The article you\'re looking for might have been removed or is temporarily unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xFF948979)
                        : const Color(0xFF393E46).withOpacity(0.7),
                    fontFamily: 'DMSerif',
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF393E46), Color(0xFF948979)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: const Color(0xFFDFD0B8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Go Back',
                            style: TextStyle(
                              color: const Color(0xFFDFD0B8),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsContent(bool isDark) {
    final cardColor = isDark ? const Color(0xFF393E46) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46);
    final secondaryTextColor = isDark
        ? const Color(0xFF948979)
        : const Color(0xFF393E46).withOpacity(0.7);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isDark, cardColor, textColor),
            _buildSliverContent(cardColor, textColor, secondaryTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark, Color cardColor, Color textColor) {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 38.0),
          child: AppBarTitle(
            textColor: textColor,
            news: _news,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            HeroImage(
              isDark: isDark,
              news: _news,
            ),
            // Gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.5, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      leading: CustomBackButton(
        cardColor: cardColor,
        textColor: textColor,
      ),
    );
  }

  Widget _buildSliverContent(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              textColor: textColor,
            ),
            const SizedBox(height: 16),
            AuthorCard(
              news: _news!,
              cardColor: cardColor,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 32),
            // Add some extra space at the bottom for better UX
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
