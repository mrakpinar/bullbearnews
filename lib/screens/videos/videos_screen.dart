import 'package:bullbearnews/models/video_model.dart';
import 'package:bullbearnews/services/video_service.dart';
import 'package:bullbearnews/widgets/videos/category_filter.dart';
import 'package:bullbearnews/widgets/videos/empty_videos.dart';
import 'package:bullbearnews/widgets/videos/header_widget.dart';
import 'package:bullbearnews/widgets/videos/loading_videos.dart';
import 'package:bullbearnews/widgets/videos/refresh_indicator_widget.dart';
import 'package:flutter/material.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  _VideosScreenState createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with TickerProviderStateMixin {
  final VideoService _videoService = VideoService();
  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];

  // Backend'deki video kategorilerine göre güncellendi
  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': '🎬'},
    {'name': 'Tutorial', 'icon': '📚'},
    {'name': 'News', 'icon': '📰'},
    {'name': 'Analysis', 'icon': '📊'},
    {'name': 'Interview', 'icon': '🎤'},
    {'name': 'Review', 'icon': '⭐'},
    {'name': 'Trading', 'icon': '📈'},
    {'name': 'DeFi', 'icon': '🏦'},
    {'name': 'NFT', 'icon': '🎨'},
  ];

  String _selectedCategory = 'All';
  bool _isLoading = true;

  // Sayfalama için
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Animations
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
    _loadVideos();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _hideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 900),
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

    // Animasyonları başlat
    _headerAnimationController.forward();
    _hideAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _categoryAnimationController.forward();
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!mounted || !_scrollController.hasClients) return;

    final currentScrollOffset = _scrollController.offset;
    final scrollDelta = currentScrollOffset - _lastScrollOffset;

    // Pagination check - prevent multiple simultaneous loads
    if (!_isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreVideos();
    }

    // Header visibility
    if (scrollDelta > _scrollThreshold && _isHeaderVisible) {
      setState(() {
        _isHeaderVisible = false;
      });
      _hideAnimationController.reverse();
    } else if (scrollDelta < -_scrollThreshold && !_isHeaderVisible) {
      setState(() {
        _isHeaderVisible = true;
      });
      _hideAnimationController.forward();
    }

    if (scrollDelta.abs() > _scrollThreshold) {
      _lastScrollOffset = currentScrollOffset;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _categoryAnimationController.dispose();
    _hideAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _isLoadingMore = false;
      }
    });

    try {
      List<VideoModel> allVideos =
          await _videoService.getVideos(forceRefresh: refresh);

      if (mounted) {
        setState(() {
          _allVideos = allVideos;
          _applyFilter();
          _hasMore = _filteredVideos.isNotEmpty;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Video yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to load videos: ${e.toString()}')),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilter() {
    if (_selectedCategory == 'All') {
      _filteredVideos = List.from(_allVideos);
    } else {
      _filteredVideos = _allVideos
          .where((video) =>
              video.category.toLowerCase() == _selectedCategory.toLowerCase())
          .toList();
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
        _currentPage = 1;
        _isLoadingMore = false;
      });
      _applyFilter();

      // Scroll to top when category changes
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoading || !_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      // Bu kısımda gerçek sayfalama implementasyonu yapılabilir
      // Şimdilik sadece flag'i sıfırlıyoruz
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _hasMore = false; // Şimdilik daha fazla veri yok
        });
      }
    } catch (e) {
      debugPrint('Daha fazla video yükleme hatası: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
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
                          HeaderWidget(
                            isDark: isDark,
                            filteredVideos: _filteredVideos,
                            headerAnimation: _headerAnimation,
                          ),
                          _buildCategoryFilter(isDark),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: _buildVideosList(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return CategoryFilter(
      isDark: isDark,
      allVideos: _allVideos,
      categoryAnimation: _categoryAnimation,
      onCategorySelected: _onCategorySelected,
      selectedCategory: _selectedCategory,
    );
  }

  Widget _buildVideosList(bool isDark) {
    if (_isLoading && _filteredVideos.isEmpty) {
      return LoadingVideos(
        isDark: isDark,
      );
    }

    if (_filteredVideos.isEmpty) {
      return EmptyVideos(
        isDark: isDark,
        selectedCategory: _selectedCategory,
        onRefresh: () => _loadVideos(refresh: true),
      );
    }

    return RefreshIndicatorWidget(
      isDark: isDark,
      loadVideos: () => _loadVideos(refresh: true),
      scrollController: _scrollController,
      filteredVideos: _filteredVideos,
      isLoadingMore: _isLoadingMore,
    );
  }
}
