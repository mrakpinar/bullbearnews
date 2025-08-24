import 'package:bullbearnews/screens/home/search_user_screen.dart';
import 'package:bullbearnews/services/notification_service.dart';
import 'package:bullbearnews/widgets/home/action_button.dart';
import 'package:bullbearnews/widgets/home/empty_state_widget.dart';
import 'package:bullbearnews/widgets/home/error_state_widget.dart';
import 'package:bullbearnews/widgets/home/is_loading.dart';
import 'package:bullbearnews/widgets/home/logo_section_widget.dart';
import 'package:bullbearnews/widgets/home/notification_button_widget.dart';
import 'package:bullbearnews/widgets/news_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/news_model.dart';
import '../../services/news_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  final NotificationService _notificationService = NotificationService();
  List<NewsModel> _allNews = [];

  // Constants for better maintainability
  static const double _scrollThreshold = 50.0;
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _headerAnimationDuration = Duration(milliseconds: 1000);
  static const Duration _categoryAnimationDuration =
      Duration(milliseconds: 800);

  // Backend crypto categories
  static const List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': '📰'},
    {'name': 'Breaking', 'icon': '🚨'},
    {'name': 'Bitcoin', 'icon': '₿'},
    {'name': 'Ethereum', 'icon': 'Ξ'},
    {'name': 'Altcoins', 'icon': '🪙'},
    {'name': 'DeFi', 'icon': '🦄'},
    {'name': 'NFT', 'icon': '🎨'},
    {'name': 'Blockchain', 'icon': '⛓️'},
    {'name': 'Trading', 'icon': '📈'},
    {'name': 'Technology', 'icon': '💻'},
    {'name': 'Regulation', 'icon': '⚖️'},
  ];

  // State variables
  String _selectedCategory = 'All';
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // Controllers and animations
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadNews();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: _headerAnimationDuration,
      vsync: this,
    );
    _categoryAnimationController = AnimationController(
      duration: _categoryAnimationDuration,
      vsync: this,
    );
    _hideAnimationController = AnimationController(
      duration: _animationDuration,
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
      if (mounted) {
        _categoryAnimationController.forward();
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final currentScrollOffset = _scrollController.offset;
      final scrollDelta = currentScrollOffset - _lastScrollOffset;

      if (scrollDelta > _scrollThreshold && _isHeaderVisible) {
        _hideHeader();
      } else if (scrollDelta < -_scrollThreshold && !_isHeaderVisible) {
        _showHeader();
      }

      if (scrollDelta.abs() > _scrollThreshold) {
        _lastScrollOffset = currentScrollOffset;
      }
    });
  }

  void _hideHeader() {
    if (!mounted) return;
    setState(() {
      _isHeaderVisible = false;
    });
    _hideAnimationController.reverse();
  }

  void _showHeader() {
    if (!mounted) return;
    setState(() {
      _isHeaderVisible = true;
    });
    _hideAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _categoryAnimationController.dispose();
    _hideAnimationController.dispose();
    super.dispose();
  }

  // Load news with better error handling
  Future<void> _loadNews({bool forceRefresh = false}) async {
    if (!forceRefresh && _newsCache.containsKey(_selectedCategory)) {
      setState(() {
        _allNews = _newsCache[_selectedCategory]!;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final news = await _getNewsForCategory();
      _newsCache[_selectedCategory] = news;

      if (mounted) {
        setState(() {
          _allNews = news;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('News loading error: $e');
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<List<NewsModel>> _getNewsForCategory() async {
    return _selectedCategory == 'All'
        ? await _newsService.getNews()
        : await _newsService.getNewsByCategory(_selectedCategory);
  }

  // Refresh news with loading state
  Future<void> _refreshNews() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final news = await _getNewsForCategory();
      _newsCache[_selectedCategory] = news;

      if (mounted) {
        setState(() {
          _allNews = news;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('News refresh error: $e');
      }
      _showErrorSnackBar('Failed to refresh news: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
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

  void _onCategorySelected(String categoryName) {
    if (categoryName == _selectedCategory) return;

    setState(() => _selectedCategory = categoryName);
    _loadNews();
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
            _buildAnimatedHeader(isDark),
            Expanded(child: _buildNewsList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isDark) {
    return AnimatedBuilder(
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
                  Expanded(child: LogoSectionWidget(isDark: isDark)),
                  _buildActionButtons(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        ActionButton(
          icon: Icons.search_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchUserScreen()),
          ),
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        NotificationButtonWidget(
          isDark: isDark,
          notificationService: _notificationService,
        ),
        const SizedBox(width: 8),
      ],
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
                itemBuilder: (context, index) =>
                    _buildCategoryChip(index, isDark),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(int index, bool isDark) {
    final category = _categories[index];
    final categoryName = category['name']!;
    final categoryIcon = category['icon']!;
    final isSelected = categoryName == _selectedCategory;

    return AnimatedContainer(
      duration: _animationDuration,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCategorySelected(categoryName),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF393E46), Color(0xFF948979)],
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
                        : const Color(0xFF393E46).withOpacity(0.2)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(categoryIcon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  categoryName,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFDFD0B8)
                        : (isDark
                            ? const Color(0xFF948979)
                            : const Color(0xFF393E46)),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
  }

  Widget _buildNewsList(bool isDark) {
    // Show loading state
    if (_isLoading) {
      return IsLoading(isDark: isDark);
    }

    // Show error state
    if (_errorMessage != null) {
      return ErrorStateWidget(
        isDark: isDark,
        errorMessage: _errorMessage,
        onRetry: () => _loadNews(forceRefresh: true),
      );
    }

    // Show empty state
    if (_allNews.isEmpty) {
      return EmptyStateWidget(
        isDark: isDark,
        isRefreshing: _isRefreshing,
        refreshNews: _refreshNews,
        selectedCategory: _selectedCategory,
      );
    }

    // Show news list
    return _buildNewsListView(isDark);
  }

  Widget _buildNewsListView(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshNews,
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
