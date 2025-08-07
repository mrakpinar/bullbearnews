import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_model.dart';

class FirebaseSavedNewsService {
  static final FirebaseSavedNewsService _instance =
      FirebaseSavedNewsService._internal();
  factory FirebaseSavedNewsService() => _instance;
  FirebaseSavedNewsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının kaydedilmiş haberler koleksiyonuna referans
  CollectionReference get _savedNewsCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return _firestore.collection('users').doc(userId).collection('savedNews');
  }

  // Haberi kaydet
  Future<void> saveNews(NewsModel news) async {
    try {
      await _savedNewsCollection.doc(news.id).set({
        'id': news.id,
        'title': news.title,
        'content': news.content,
        'author': news.author,
        'publishDate': Timestamp.fromDate(news.publishDate),
        'imageUrl': news.imageUrl,
        'category': news.category,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save news: $e');
    }
  }

  // Kaydedilmiş haberi sil
  Future<void> removeSavedNews(String newsId) async {
    try {
      await _savedNewsCollection.doc(newsId).delete();
    } catch (e) {
      throw Exception('Failed to remove saved news: $e');
    }
  }

  // Haberin kaydedilip kaydedilmediğini kontrol et
  Future<bool> isNewsSaved(String newsId) async {
    try {
      final doc = await _savedNewsCollection.doc(newsId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Kaydedilmiş haberleri stream olarak getir (realtime)
  Stream<List<NewsModel>> getSavedNewsStream() {
    try {
      return _savedNewsCollection
          .orderBy('savedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return NewsModel(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            author: data['author'] ?? '',
            publishDate:
                (data['publishDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
            imageUrl: data['imageUrl'] ?? '',
            category: data['category'] ?? '',
          );
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get saved news stream: $e');
    }
  }

  // Kaydedilmiş haberleri tek seferlik getir
  Future<List<NewsModel>> getSavedNews() async {
    try {
      final snapshot =
          await _savedNewsCollection.orderBy('savedAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NewsModel(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          author: data['author'] ?? '',
          publishDate:
              (data['publishDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          imageUrl: data['imageUrl'] ?? '',
          category: data['category'] ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get saved news: $e');
    }
  }

  // Kaydedilmiş haber sayısını getir
  Future<int> getSavedNewsCount() async {
    try {
      final snapshot = await _savedNewsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Kaydedilmiş haber sayısını stream olarak getir
  Stream<int> getSavedNewsCountStream() {
    try {
      return _savedNewsCollection
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  // Tüm kaydedilmiş haberleri sil
  Future<void> clearAllSavedNews() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _savedNewsCollection.get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear saved news: $e');
    }
  }

  // Offline cache için local olarak kaydetme (Hive ile)
  Future<void> syncWithLocalStorage() async {
    try {
      // Bu method gerekirse Hive ile senkronizasyon için kullanılabilir
      // Şu an için boş bırakıyoruz
    } catch (e) {
      throw Exception('Failed to sync with local storage: $e');
    }
  }

  Stream<DocumentSnapshot> getNewsDocumentStream(String newsId) {
    try {
      return _savedNewsCollection.doc(newsId).snapshots();
    } catch (e) {
      throw Exception('Failed to get news document stream: $e');
    }
  }
}
