import 'package:bullbearnews/models/video_model.dart';
import 'package:bullbearnews/services/video_service.dart';
import 'package:bullbearnews/widgets/video_card.dart';
import 'package:flutter/material.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  _VideosScreenState createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final VideoService _videoService = VideoService();
  List<VideoModel> _allVideos = [];
  final List<String> _categories = [
    'All',
    'Trending',
    'New',
    'Teknoloji',
    'Sağlık'
  ];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (_selectedCategory == 'All') {
        _allVideos = await _videoService.getVideos();
      } else {
        _allVideos = await _videoService.getVideosByCategory(_selectedCategory);
      }
    } catch (e) {
      print('Video yükleme hatası: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Videos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _allVideos.isEmpty
              ? Center(
                  child: Text(
                    'No videos available',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  color: Theme.of(context).primaryColor,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Colors.black,
                  onRefresh: _loadVideos,
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(16),
                    itemCount: _allVideos.length,
                    itemBuilder: (context, index) {
                      if (index == _allVideos.length - 1) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: VideoCard(video: _allVideos[index]),
                        );
                      }
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: index == _allVideos.length - 1
                              ? VideoCard(video: _allVideos[index])
                              : VideoCard(video: _allVideos[index]));
                    },
                  ),
                ),
    );
  }
}
