import 'package:hive/hive.dart';
import '../models/news_model.dart';

class LocalStorageService {
  static late Box<NewsModel> _box;

  static Future<void> init() async {
    try {
      _box = await Hive.openBox<NewsModel>('savedNews');
    } catch (e) {
      print('Error opening Hive box: $e');
      // Box bozuksa silip yeniden aç
      await Hive.deleteBoxFromDisk('savedNews');
      _box = await Hive.openBox<NewsModel>('savedNews');
    }
  }

  static Future<void> saveNews(NewsModel news) async {
    try {
      await _box.put(news.id, news);
    } catch (e) {
      print('Error saving news: $e');
      throw Exception('Failed to save news');
    }
  }

  static Future<void> removeNews(String newsId) async {
    try {
      await _box.delete(newsId);
    } catch (e) {
      print('Error removing news: $e');
      throw Exception('Failed to remove news');
    }
  }

  static Future<List<NewsModel>> getSavedNews() async {
    try {
      return _box.values.toList();
    } catch (e) {
      print('Error getting saved news: $e');
      return [];
    }
  }

  static Future<bool> isNewsSaved(String newsId) async {
    try {
      return _box.containsKey(newsId);
    } catch (e) {
      print('Error checking saved news: $e');
      return false;
    }
  }

  static Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      print('Error clearing box: $e');
    }
  }
}
