import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<VideoModel>> getVideos() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return VideoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Video getirme hatası: $e');
      return [];
    }
  }

  Future<List<VideoModel>> getVideosByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .where('category', isEqualTo: category)
          .orderBy('publishDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return VideoModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Kategoriye göre video getirme hatası: $e');
      return [];
    }
  }
}
