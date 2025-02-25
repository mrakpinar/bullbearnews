import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_model.dart';

class NewsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tüm haberleri getir
  Future<List<NewsModel>> getNews() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('news')
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return NewsModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Haber getirme hatası: $e');
      return [];
    }
  }

  // Kategori bazlı haberleri getir
  Future<List<NewsModel>> getNewsByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('news')
          .where('category', isEqualTo: category)
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return NewsModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('Kategori haberleri getirme hatası: $e');
      return [];
    }
  }

  // Haber detayı getir
  Future<NewsModel?> getNewsDetail(String newsId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('news').doc(newsId).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return NewsModel.fromJson(data);
    } catch (e) {
      print('Haber detayı getirme hatası: $e');
      return null;
    }
  }
}
