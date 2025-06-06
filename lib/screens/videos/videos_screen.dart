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
    with AutomaticKeepAliveClientMixin {
  final VideoService _videoService = VideoService();
  List<VideoModel> _allVideos = [];
  final List<String> _categories = [
    'All',
    'Trending',
    'New',
    'Teknoloji',
    'Sağlık'
  ];
  final String _selectedCategory = 'All';
  bool _isLoading = true;

  // Sayfalama için
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _hasMore = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    if (!mounted) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _allVideos.clear();
    }

    setState(() => _isLoading = true);

    try {
      List<VideoModel> newVideos;
      if (_selectedCategory == 'All') {
        newVideos = await _videoService.getVideos();
      } else {
        newVideos = await _videoService.getVideosByCategory(
          _selectedCategory,
        );
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _allVideos = newVideos;
          } else {
            _allVideos.addAll(newVideos);
          }
          _hasMore = newVideos.length == _itemsPerPage;
        });
      }
    } catch (e) {
      debugPrint('Video yükleme hatası: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    await _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allVideos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allVideos.isEmpty) {
      return const Center(
        child: Text(
          'No videos available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        color: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.white
            : Colors.black,
        onRefresh: () => _loadVideos(refresh: true),
        child: _buildVideoList(),
      ),
    );
  }

  Widget _buildVideoList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      itemCount: _allVideos.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the end
        if (index == _allVideos.length) {
          return _hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: VideoCard(
            video: _allVideos[index],
            key: ValueKey(_allVideos[index].videoID),
          ),
        );
      },
    );
  }
}
