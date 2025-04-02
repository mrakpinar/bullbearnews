import 'package:bullbearnews/models/announcement_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Announcement>> getActiveAnnouncements() {
    return _firestore
        .collection('announcements')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromMap(doc.id, doc.data()))
            .toList());
  }
}
