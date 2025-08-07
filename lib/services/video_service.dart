import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache için
  static List<VideoModel>? _cachedVideos;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  Future<List<VideoModel>> getVideos({bool forceRefresh = false}) async {
    try {
      // Cache kontrolü
      if (!forceRefresh &&
          _cachedVideos != null &&
          _lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!) < _cacheExpiration) {
        return _cachedVideos!;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .orderBy('publishDate', descending: true)
          .get();

      List<VideoModel> videos = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return VideoModel.fromMap(data, doc.id);
      }).toList();

      // Cache güncelle
      _cachedVideos = videos;
      _lastFetchTime = DateTime.now();

      // Debug: Her kategori için video sayısını yazdır
      Map<String, int> categoryCounts = {};
      for (VideoModel video in videos) {
        String category = video.category.toLowerCase();
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      return videos;
    } catch (e) {
      // Cache varsa onu döndür
      if (_cachedVideos != null) {
        return _cachedVideos!;
      }

      return [];
    }
  }

  Future<List<VideoModel>> getVideosByCategory(String category) async {
    try {
      // Önce tüm videoları al
      List<VideoModel> allVideos = await getVideos();

      if (category.toLowerCase() == 'all') {
        return allVideos;
      }

      // Client-side filtreleme yap
      List<VideoModel> filteredVideos = allVideos
          .where(
              (video) => video.category.toLowerCase() == category.toLowerCase())
          .toList();

      print('$category kategorisinde ${filteredVideos.length} video bulundu');

      return filteredVideos;
    } catch (e) {
      return [];
    }
  }

  // Cache temizleme metodu
  static void clearCache() {
    _cachedVideos = null;
    _lastFetchTime = null;
  }

  // Belirli bir kategorideki video sayısını al
  Future<int> getVideosCountByCategory(String category) async {
    try {
      if (category.toLowerCase() == 'all') {
        List<VideoModel> allVideos = await getVideos();
        return allVideos.length;
      }

      List<VideoModel> categoryVideos = await getVideosByCategory(category);
      return categoryVideos.length;
    } catch (e) {
      return 0;
    }
  }

  // Tüm kategorileri al
  Future<List<String>> getAvailableCategories() async {
    try {
      List<VideoModel> allVideos = await getVideos();
      Set<String> categories = allVideos
          .map((video) => video.category)
          .where((category) => category.isNotEmpty)
          .toSet();

      return categories.toList()..sort();
    } catch (e) {
      return [];
    }
  }
}
