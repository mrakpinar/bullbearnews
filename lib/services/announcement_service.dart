import 'package:bullbearnews/models/announcement_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart'; // Bildirim servisi

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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

  // YENİ: Duyuru ekleme metodu (admin paneli için)
  Future<String> createAnnouncement({
    required String title,
    required String content,
    String? imageUrl,
    bool isActive = true,
    bool sendNotification = true, // Otomatik bildirim gönderimi
    List<String>? targetUserIds, // Belirli kullanıcılara gönderim (opsiyonel)
  }) async {
    try {
      print('📝 Creating new announcement: $title');

      // Duyuruyu Firestore'a ekle
      final docRef = await _firestore.collection('announcements').add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'likeCount': 0,
      });

      final announcementId = docRef.id;
      print('✅ Announcement created with ID: $announcementId');

      // Eğer bildirim gönderimi aktifse
      if (sendNotification && isActive) {
        print('📢 Sending notification for new announcement...');

        // Bildirim gönder
        await _notificationService.sendAnnouncementNotification(
          announcementId: announcementId,
          title: title,
          content: content,
          imageUrl: imageUrl,
          targetUserIds: targetUserIds,
        );

        print('✅ Notification sent successfully');
      }

      return announcementId;
    } catch (e) {
      print('💥 Error creating announcement: $e');
      rethrow;
    }
  }

  // Duyuru güncelleme metodu
  Future<void> updateAnnouncement({
    required String announcementId,
    String? title,
    String? content,
    String? imageUrl,
    bool? isActive,
    bool sendNotificationIfActivated =
        false, // Aktifleştirildiğinde bildirim gönder
  }) async {
    try {
      print('📝 Updating announcement: $announcementId');

      // Mevcut duyuruyu al
      final docSnapshot = await _firestore
          .collection('announcements')
          .doc(announcementId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Announcement not found');
      }

      final currentData = docSnapshot.data()!;
      final wasActive = currentData['isActive'] as bool? ?? false;

      // Güncelleme verisini hazırla
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (imageUrl != null) updateData['imageUrl'] = imageUrl;
      if (isActive != null) updateData['isActive'] = isActive;

      // Güncellemeyi yap
      await _firestore
          .collection('announcements')
          .doc(announcementId)
          .update(updateData);

      print('✅ Announcement updated successfully');

      // Eğer duyuru aktifleştirildi ve bildirim gönderimi istendiyse
      if (sendNotificationIfActivated && isActive == true && !wasActive) {
        print('📢 Sending notification for activated announcement...');

        await _notificationService.sendAnnouncementNotification(
          announcementId: announcementId,
          title: title ?? currentData['title'],
          content: content ?? currentData['content'],
          imageUrl: imageUrl ?? currentData['imageUrl'],
        );

        print('✅ Activation notification sent successfully');
      }
    } catch (e) {
      print('💥 Error updating announcement: $e');
      rethrow;
    }
  }

  // Duyuru silme metodu
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      print('🗑️ Deleting announcement: $announcementId');

      await _firestore.collection('announcements').doc(announcementId).delete();

      print('✅ Announcement deleted successfully');
    } catch (e) {
      print('💥 Error deleting announcement: $e');
      rethrow;
    }
  }

  // Duyuru aktiflik durumunu değiştir
  Future<void> toggleAnnouncementStatus(String announcementId, bool isActive,
      {bool sendNotification = false}) async {
    try {
      await updateAnnouncement(
        announcementId: announcementId,
        isActive: isActive,
        sendNotificationIfActivated: sendNotification,
      );
    } catch (e) {
      print('💥 Error toggling announcement status: $e');
      rethrow;
    }
  }

  // Duyuru görüntülenme sayısını artır
  Future<void> incrementViewCount(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('💥 Error incrementing view count: $e');
    }
  }

  // Duyuru beğeni sayısını artır/azalt
  Future<void> toggleLike(String announcementId, bool isLiked) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'likeCount': FieldValue.increment(isLiked ? 1 : -1),
      });
    } catch (e) {
      print('💥 Error toggling like: $e');
    }
  }

  // Belirli bir duyuruyu getir
  Future<Announcement?> getAnnouncement(String announcementId) async {
    try {
      final docSnapshot = await _firestore
          .collection('announcements')
          .doc(announcementId)
          .get();

      if (!docSnapshot.exists) return null;

      return Announcement.fromMap(docSnapshot.id, docSnapshot.data()!);
    } catch (e) {
      print('💥 Error getting announcement: $e');
      return null;
    }
  }

  // Tüm duyuruları getir (admin için)
  Stream<List<Announcement>> getAllAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Test bildirimi gönder
  Future<void> sendTestAnnouncementNotification() async {
    try {
      print('🧪 Sending test announcement notification...');

      await _notificationService.sendAnnouncementNotification(
        announcementId: 'test_announcement',
        title: 'Test Announcement 🧪',
        content:
            'This is a test announcement to verify the notification system is working properly.',
        imageUrl: null,
      );

      print('✅ Test notification sent successfully');
    } catch (e) {
      print('💥 Error sending test notification: $e');
      rethrow;
    }
  }
}
