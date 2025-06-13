import 'package:bullbearnews/models/video_model.dart';
import 'package:bullbearnews/services/video_service.dart';
import 'package:bullbearnews/widgets/video_card.dart';
import 'package:flutter/material.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  _VideosScreenState createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final VideoService _videoService = VideoService();
  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  final List<String> _categories = [
    'All',
    'Trending',
    'New',
    'Teknoloji',
    'Sağlık'
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
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();
    _loadVideos();
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
            content: Text('Videolar yüklenirken hata oluştu: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

    debugPrint('Seçilen kategori: $_selectedCategory');
    debugPrint('Tüm video sayısı: ${_allVideos.length}');
    debugPrint('Filtrelenmiş video sayısı: ${_filteredVideos.length}');
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
    super.build(context);
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
              child: _buildVideosList(isDark),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF393E46),
                                    Color(0xFF393E46),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill,
                                color: Color(0xFFDFD0B8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Videos',
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
                        Row(
                          children: [
                            Text(
                              'Watch the latest video content',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF948979)
                                    : const Color(0xFF393E46),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                            if (_filteredVideos.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF393E46)
                                      : const Color(0xFF948979),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_filteredVideos.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDFD0B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
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
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  int categoryCount = 0;
                  if (category == 'All') {
                    categoryCount = _allVideos.length;
                  } else {
                    categoryCount = _allVideos
                        .where((video) =>
                            video.category.toLowerCase() ==
                            category.toLowerCase())
                        .length;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onCategorySelected(category),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF393E46),
                                      Color(0xFF393E46),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
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
                              if (categoryCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFDFD0B8)
                                            .withOpacity(0.2)
                                        : (isDark
                                            ? const Color(0xFF948979)
                                                .withOpacity(0.2)
                                            : const Color(0xFF393E46)
                                                .withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$categoryCount',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFDFD0B8)
                                          : (isDark
                                              ? const Color(0xFF948979)
                                              : const Color(0xFF393E46)),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildVideosList(bool isDark) {
    if (_isLoading && _filteredVideos.isEmpty) {
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
              'Loading videos...',
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

    if (_filteredVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedCategory == 'All'
                  ? 'No videos available'
                  : 'No videos in $_selectedCategory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'All'
                  ? 'Check back later for new content'
                  : 'Try selecting a different category',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF948979).withOpacity(0.7)
                    : const Color(0xFF393E46).withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadVideos(refresh: true),
      color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _filteredVideos.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == _filteredVideos.length) {
            return _isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            child: VideoCard(
              video: _filteredVideos[index],
              key: ValueKey(_filteredVideos[index].videoID),
            ),
          );
        },
      ),
    );
  }
}
