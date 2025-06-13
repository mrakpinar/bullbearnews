import 'package:bullbearnews/screens/home/search_user_screen.dart';
import 'package:bullbearnews/widgets/news_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  List<NewsModel> _allNews = [];
  final List<String> _categories = [
    'All',
    'Trending',
    'New',
    'Teknoloji',
    'Sağlık'
  ];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final Map<String, List<NewsModel>> _newsCache = {};

  late AnimationController _headerAnimationController;
  late AnimationController _categoryAnimationController;
  late AnimationController _hideAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _categoryAnimation;
  late Animation<double> _hideAnimation;

  bool _isHeaderVisible = true;
  double _lastScrollOffset = 0;
  static const double _scrollThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadNews();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _hideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _categoryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _categoryAnimationController, curve: Curves.easeOut),
    );
    _hideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _hideAnimationController, curve: Curves.easeInOut),
    );

    _headerAnimationController.forward();
    _hideAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _categoryAnimationController.forward();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final currentScrollOffset = _scrollController.offset;
      final scrollDelta = currentScrollOffset - _lastScrollOffset;

      if (scrollDelta > _scrollThreshold && _isHeaderVisible) {
        // Scrolling down - hide header
        setState(() {
          _isHeaderVisible = false;
        });
        _hideAnimationController.reverse();
      } else if (scrollDelta < -_scrollThreshold && !_isHeaderVisible) {
        // Scrolling up - show header
        setState(() {
          _isHeaderVisible = true;
        });
        _hideAnimationController.forward();
      }

      // Update when scroll direction changes significantly
      if (scrollDelta.abs() > _scrollThreshold) {
        _lastScrollOffset = currentScrollOffset;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _categoryAnimationController.dispose();
    _hideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    if (_newsCache.containsKey(_selectedCategory)) {
      setState(() {
        _allNews = _newsCache[_selectedCategory]!;
        _isLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      List<NewsModel> news;
      if (_selectedCategory == 'All') {
        news = await _newsService.getNews();
      } else {
        news = await _newsService.getNewsByCategory(_selectedCategory);
      }

      _newsCache[_selectedCategory] = news;

      if (mounted) {
        setState(() {
          _allNews = news;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Haber yükleme hatası: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF222831) : const Color(0xFFDFD0B8),
      body: SafeArea(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _hideAnimation,
              builder: (context, child) {
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _hideAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -50 * (1 - _hideAnimation.value)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(isDark),
                          _buildCategoryFilter(isDark),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: _buildNewsList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _headerAnimation.value)),
          child: Opacity(
            opacity: _headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Logo and Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF393E46),
                                    const Color(0xFF948979),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'BBN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFDFD0B8),
                                  letterSpacing: 1.5,
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'BullBearNews',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                letterSpacing: -0.5,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Stay informed, stay ahead',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF948979)
                                : const Color(0xFF393E46),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'DMSerif',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.search_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchUserScreen()),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      // _buildActionButton(
                      //   icon: Icons.tune_rounded,
                      //   onTap: _showFilterDialog,
                      //   isDark: isDark,
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF393E46).withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF393E46),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return AnimatedBuilder(
      animation: _categoryAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _categoryAnimation.value)),
          child: Opacity(
            opacity: _categoryAnimation.value,
            child: Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          _loadNews();
                        },
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF393E46),
                                      const Color(0xFF948979),
                                    ],
                                  )
                                : null,
                            color: !isSelected
                                ? (isDark
                                    ? const Color(0xFF393E46).withOpacity(0.3)
                                    : Colors.white.withOpacity(0.7))
                                : null,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? const Color(0xFF948979).withOpacity(0.3)
                                      : const Color(0xFF393E46)
                                          .withOpacity(0.2)),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFFDFD0B8)
                                  : (isDark
                                      ? const Color(0xFF948979)
                                      : const Color(0xFF393E46)),
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 14,
                              fontFamily: 'DMSerif',
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewsList(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading news...',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _allNews.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            child: NewsCard(news: _allNews[index]),
          );
        },
      ),
    );
  }
}
