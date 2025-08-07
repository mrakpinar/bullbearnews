import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'push_notification_service.dart'; // Yukarıda oluşturduğumuz servisi import edin

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Bildirim türleri
  static const String FOLLOW_TYPE = 'follow';
  static const String UNFOLLOW_TYPE = 'unfollow';
  static const String LIKE_PORTFOLIO_TYPE = 'like_portfolio';
  static const String SHARE_PORTFOLIO_TYPE = 'share_portfolio';
  static const String NEW_ANNOUNCEMENT_TYPE = 'new_announcement';

  // Takip bildirimi gönder
  Future<void> sendFollowNotification(String targetUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == targetUserId) return;

    try {
      // Mevcut kullanıcının bilgilerini al
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) return;

      final currentUserData = currentUserDoc.data()!;

      // Bildirim oluştur
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': FOLLOW_TYPE,
        'senderId': currentUser.uid,
        'senderName': currentUserData['name'] ?? 'Unknown User',
        'senderNickname': currentUserData['nickname'] ?? 'Unknown',
        'senderProfileImage': currentUserData['profileImageUrl'] ?? '',
        'message': '${currentUserData['nickname']} started following you',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Hedef kullanıcının okunmamış bildirim sayısını artır
      await _incrementUnreadCount(targetUserId);

      // Push notification gönder
      await PushNotificationService.sendPushNotification(
        targetUserId: targetUserId,
        title: 'New Follower!',
        body: '${currentUserData['nickname']} started following you',
        data: {
          'type': FOLLOW_TYPE,
          'senderId': currentUser.uid,
          'senderNickname': currentUserData['nickname'],
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );

      print('Follow notification sent successfully');
    } catch (e) {
      print('Follow notification error: $e');
    }
  }

  // Portfolio paylaşım bildirimi gönder
  Future<void> sendSharePortfolioNotification(
      String walletName, String walletId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    print('Sending notification for wallet: $walletName with ID: $walletId');

    try {
      // Mevcut kullanıcının bilgilerini al
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) return;

      final currentUserData = currentUserDoc.data()!;
      final followers = (currentUserData['followers'] as List?) ?? [];

      print('User has ${followers.length} followers');

      // Her takipçiye bildirim gönder
      List<String> followerIds = [];

      for (String followerId in followers) {
        print('Sending notification to follower: $followerId');

        await _firestore
            .collection('users')
            .doc(followerId)
            .collection('notifications')
            .add({
          'type': SHARE_PORTFOLIO_TYPE,
          'senderId': currentUser.uid,
          'senderName': currentUserData['name'] ?? 'Unknown User',
          'senderNickname': currentUserData['nickname'] ?? 'Unknown',
          'senderProfileImage': currentUserData['profileImageUrl'] ?? '',
          'walletName': walletName,
          'walletId': walletId,
          'message':
              '${currentUserData['nickname']} shared a new portfolio "$walletName"',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('Notification sent successfully to: $followerId');

        // Takipçinin okunmamış bildirim sayısını artır
        await _incrementUnreadCount(followerId);

        // Follower ID'sini listeye ekle
        followerIds.add(followerId);
      }

      // Tüm takipçilere push notification gönder
      if (followerIds.isNotEmpty) {
        await PushNotificationService.sendMulticastNotification(
          userIds: followerIds,
          title: 'New Portfolio Shared!',
          body: '${currentUserData['nickname']} shared "$walletName"',
          data: {
            'type': SHARE_PORTFOLIO_TYPE,
            'senderId': currentUser.uid,
            'senderNickname': currentUserData['nickname'],
            'walletId': walletId,
            'walletName': walletName,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );
      }

      print('Share portfolio notifications sent successfully');
    } catch (e) {
      print('Share portfolio notification error: $e');
    }
  }

  Future<void> sendLikePortfolioNotification(
      String portfolioOwnerId, String walletName,
      [String? walletId]) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid == portfolioOwnerId) return;

    try {
      // Mevcut kullanıcının bilgilerini al
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) return;

      final currentUserData = currentUserDoc.data()!;

      // Bildirim oluştur
      await _firestore
          .collection('users')
          .doc(portfolioOwnerId)
          .collection('notifications')
          .add({
        'type': LIKE_PORTFOLIO_TYPE,
        'senderId': currentUser.uid,
        'senderName': currentUserData['name'] ?? 'Unknown User',
        'senderNickname': currentUserData['nickname'] ?? 'Unknown',
        'senderProfileImage': currentUserData['profileImageUrl'] ?? '',
        'walletName': walletName,
        'walletId': walletId,
        'message':
            '${currentUserData['nickname']} liked your portfolio "$walletName"',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Hedef kullanıcının okunmamış bildirim sayısını artır
      await _incrementUnreadCount(portfolioOwnerId);

      // Push notification gönder
      await PushNotificationService.sendPushNotification(
        targetUserId: portfolioOwnerId,
        title: 'Portfolio Liked!',
        body:
            '${currentUserData['nickname']} liked your portfolio "$walletName"',
        data: {
          'type': LIKE_PORTFOLIO_TYPE,
          'senderId': currentUser.uid,
          'senderNickname': currentUserData['nickname'],
          'walletName': walletName,
          'walletId': walletId ?? '',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );

      print('Like portfolio notification sent successfully');
    } catch (e) {
      print('Like portfolio notification error: $e');
    }
  }

  // YENİ: Duyuru bildirimi gönder (tüm kullanıcılara)
  Future<void> sendAnnouncementNotification({
    required String announcementId,
    required String title,
    required String content,
    String? imageUrl,
    List<String>?
        targetUserIds, // Belirli kullanıcılara göndermek için (opsiyonel)
  }) async {
    try {
      print('📢 Sending announcement notification...');
      print('Title: $title');
      print(
          'Content preview: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}');

      List<String> userIds = [];

      if (targetUserIds != null && targetUserIds.isNotEmpty) {
        // Belirli kullanıcılara gönder
        userIds = targetUserIds;
        print('🎯 Sending to specific ${userIds.length} users');
      } else {
        // Tüm aktif kullanıcılara gönder
        final usersQuery = await _firestore
            .collection('users')
            .where('isActive', isEqualTo: true) // Aktif kullanıcılar
            .limit(1000) // Güvenlik için limit
            .get();

        userIds = usersQuery.docs.map((doc) => doc.id).toList();
        print('📊 Sending to all ${userIds.length} active users');
      }

      if (userIds.isEmpty) {
        print('❌ No users found to send announcement');
        return;
      }

      // Batch işlemi için grupları oluştur
      const batchSize = 100; // Firestore batch limit
      final batches = <List<String>>[];

      for (int i = 0; i < userIds.length; i += batchSize) {
        final end =
            (i + batchSize < userIds.length) ? i + batchSize : userIds.length;
        batches.add(userIds.sublist(i, end));
      }

      print('📦 Processing ${batches.length} batches');

      // Her batch'i işle
      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = batches[batchIndex];
        print(
            '📦 Processing batch ${batchIndex + 1}/${batches.length} (${batch.length} users)');

        // Firestore batch
        final firestoreBatch = _firestore.batch();

        // Her kullanıcı için bildirim oluştur
        for (String userId in batch) {
          final notificationRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc(); // Otomatik ID

          firestoreBatch.set(notificationRef, {
            'type': NEW_ANNOUNCEMENT_TYPE,
            'senderId': 'system', // Sistem bildirimi
            'senderName': 'Bull Bear News',
            'senderNickname': 'BullBearNews',
            'senderProfileImage': '', // Sistem için boş
            'announcementId': announcementId,
            'title': title,
            'content': content,
            'imageUrl': imageUrl ?? '',
            'message': 'New announcement: $title',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Okunmamış sayacı artır
          final userRef = _firestore.collection('users').doc(userId);
          firestoreBatch.update(userRef, {
            'unreadNotificationCount': FieldValue.increment(1),
          });
        }

        // Batch'i commit et
        await firestoreBatch.commit();
        print('✅ Batch ${batchIndex + 1} committed successfully');

        // Rate limiting için kısa bekleme
        if (batchIndex < batches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      print('📱 Sending push notifications...');

      // Push notification gönder (gruplar halinde)
      const pushBatchSize = 50; // Push notification için daha küçük batch
      final pushBatches = <List<String>>[];

      for (int i = 0; i < userIds.length; i += pushBatchSize) {
        final end = (i + pushBatchSize < userIds.length)
            ? i + pushBatchSize
            : userIds.length;
        pushBatches.add(userIds.sublist(i, end));
      }

      for (int i = 0; i < pushBatches.length; i++) {
        final pushBatch = pushBatches[i];
        print('📱 Sending push batch ${i + 1}/${pushBatches.length}');

        await PushNotificationService.sendMulticastNotification(
          userIds: pushBatch,
          title: '📢 New Announcement',
          body: title,
          data: {
            'type': NEW_ANNOUNCEMENT_TYPE,
            'announcementId': announcementId,
            'title': title,
            'content': content,
            'imageUrl': imageUrl ?? '',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
        );

        // Rate limiting
        if (i < pushBatches.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      print(
          '✅ Announcement notification sent successfully to ${userIds.length} users');

      // İstatistik kaydet
      await _firestore
          .collection('announcement_stats')
          .doc(announcementId)
          .set({
        'sentCount': userIds.length,
        'sentAt': FieldValue.serverTimestamp(),
        'title': title,
      });
    } catch (e) {
      print('💥 Announcement notification error: $e');
      rethrow;
    }
  }

  // Kullanıcının bildirimlerini getir (unfollow hariç)
  Stream<QuerySnapshot> getUserNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('notifications')
        .where('type',
            whereNotIn: [UNFOLLOW_TYPE]) // Unfollow bildirimlerini filtrele
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Okunmamış bildirim sayısını azalt
      await _decrementUnreadCount(currentUser.uid);
    } catch (e) {
      print('Mark as read error: $e');
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final batch = _firestore.batch();

      final unreadNotifications = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // Okunmamış bildirim sayısını sıfırla
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({'unreadNotificationCount': 0});
    } catch (e) {
      print('Mark all as read error: $e');
    }
  }

  // Bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final notificationRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId);

      final notificationDoc = await notificationRef.get();
      if (notificationDoc.exists && !notificationDoc.data()!['isRead']) {
        await _decrementUnreadCount(currentUser.uid);
      }

      await notificationRef.delete();
    } catch (e) {
      print('Delete notification error: $e');
    }
  }

  // Okunmamış bildirim sayısını getir
  Stream<int> getUnreadNotificationCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data()!.containsKey('unreadNotificationCount')) {
        return doc.data()!['unreadNotificationCount'] as int;
      }
      return 0;
    });
  }

  // Okunmamış bildirim sayısını artır
  Future<void> _incrementUnreadCount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'unreadNotificationCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Eğer field yoksa oluştur
      await _firestore.collection('users').doc(userId).set({
        'unreadNotificationCount': 1,
      }, SetOptions(merge: true));
    }
  }

  // Okunmamış bildirim sayısını azalt
  Future<void> _decrementUnreadCount(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final currentCount =
            userDoc.data()!['unreadNotificationCount'] as int? ?? 0;
        final newCount = currentCount > 0 ? currentCount - 1 : 0;

        await _firestore.collection('users').doc(userId).update({
          'unreadNotificationCount': newCount,
        });
      }
    } catch (e) {
      print('Decrement unread count error: $e');
    }
  }
}
