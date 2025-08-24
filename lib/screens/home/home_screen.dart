import 'package:bullbearnews/screens/home/notification_screen.dart';
import 'package:bullbearnews/screens/home/search_user_screen.dart';
import 'package:bullbearnews/services/notification_service.dart';
import 'package:bullbearnews/widgets/home/action_button.dart';
import 'package:bullbearnews/widgets/home/is_loading.dart';
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
  final NotificationService _notificationService = NotificationService();
  List<NewsModel> _allNews = [];

  // Backend'deki crypto kategorilerine göre güncellendi
  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': '📰'},
    {'name': 'Breaking', 'icon': '🚨'},
    {'name': 'Bitcoin', 'icon': '₿'},
    {'name': 'Ethereum', 'icon': 'Ξ'},
    {'name': 'Altcoins', 'icon': '🪙'},
    {'name': 'DeFi', 'icon': '🏦'},
    {'name': 'NFT', 'icon': '🎨'},
    {'name': 'Blockchain', 'icon': '⛓️'},
    {'name': 'Trading', 'icon': '📈'},
    {'name': 'Technology', 'icon': '💻'},
    {'name': 'Regulation', 'icon': '⚖️'},
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

  // Normal yükleme - cache'li
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

  // Pull to refresh - cache'i temizleyerek fresh data çek
  Future<void> _refreshNews() async {
    try {
      List<NewsModel> news;
      if (_selectedCategory == 'All') {
        news = await _newsService.getNews();
      } else {
        news = await _newsService.getNewsByCategory(_selectedCategory);
      }

      // Cache'i güncelle
      _newsCache[_selectedCategory] = news;

      if (mounted) {
        setState(() {
          _allNews = news;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Haber yenileme hatası: $e');
      }

      // Hata mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to refresh news: $e')),
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
                          // NotificationDebugWidget()
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
                                fontSize: 20,
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
                          'Your crypto news destination 🚀',
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
                      ActionButton(
                        icon: Icons.search_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchUserScreen()),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildNotificationButton(isDark),
                      const SizedBox(width: 8),
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

  Widget _buildNotificationButton(bool isDark) {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadNotificationCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            Container(
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: isDark
                          ? const Color(0xFFDFD0B8)
                          : const Color(0xFF393E46),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 10,
                    minHeight: 10,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
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
              height: 48,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final categoryName = category['name']!;
                  final categoryIcon = category['icon']!;
                  final isSelected = categoryName == _selectedCategory;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedCategory = categoryName);
                          _loadNews();
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
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
                            borderRadius: BorderRadius.circular(28),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                categoryIcon,
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categoryName,
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
                            ],
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
      IsLoading(isDark: isDark);
    }

    if (_allNews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF393E46).withOpacity(0.1),
                    const Color(0xFF948979).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.article_outlined,
                size: 64,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No ${_selectedCategory == 'All' ? 'crypto' : _selectedCategory} news',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '📱 Pull down to refresh for latest updates',
              style: TextStyle(
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                fontSize: 14,
                fontFamily: 'DMSerif',
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _refreshNews,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF393E46),
                        const Color(0xFF948979),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: const Color(0xFFDFD0B8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Refresh Now',
                        style: TextStyle(
                          color: const Color(0xFFDFD0B8),
                          fontWeight: FontWeight.w600,
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
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshNews, // Değişti: _refreshNews kullanıyor
      color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
      strokeWidth: 3,
      displacement: 40,
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
