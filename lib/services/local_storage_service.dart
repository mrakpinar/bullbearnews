import 'package:hive/hive.dart';
import '../models/news_model.dart';

class LocalStorageService {
  static late Box<NewsModel> _box;

  static Future<void> init() async {
    try {
      // Önceki box'ı sil (eğer bozuksa)
      await Hive.deleteBoxFromDisk('savedNews');
      _box = await Hive.openBox<NewsModel>('savedNews');
    } catch (e) {
      print('Error initializing Hive: $e');
      rethrow;
    }
  }

  static Future<void> saveNews(NewsModel news) async {
    try {
      await _box.put(news.id, news);
    } catch (e) {
      print('Error saving news: $e');
      rethrow;
    }
  }

  static Future<void> removeNews(String newsId) async {
    try {
      await _box.delete(newsId);
    } catch (e) {
      print('Error removing news: $e');
      rethrow;
    }
  }

  static List<NewsModel> getSavedNews() {
    try {
      return _box.values.where((news) => news.id.isNotEmpty).toList();
    } catch (e) {
      print('Error getting saved news: $e');
      return [];
    }
  }

  static Future<bool> isNewsSaved(String newsId) async {
    try {
      return _box.containsKey(newsId) &&
          _box.get(newsId)?.id.isNotEmpty == true;
    } catch (e) {
      print('Error checking saved news: $e');
      return false;
    }
  }

  static Future<void> closeBox() async {
    if (_box.isOpen) {
      await _box.close();
    }
  }
}
