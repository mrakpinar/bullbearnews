import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Yeni eklenen metod: Mesajın geçerli kullanıcıya ait olup olmadığını kontrol eder
  bool isCurrentUser(String userId) {
    return _auth.currentUser?.uid == userId;
  }

  // Tüm sohbet odalarını getir
  Stream<List<ChatRoom>> getChatRooms() {
    return _firestore
        .collection('chatRooms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

  // Belirli bir odadaki mesajları getir
  Stream<List<ChatMessage>> getChatMessages(String roomId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Mesaj gönder (Reply desteği ile)
  Future<void> sendMessage(
    String roomId,
    String content, {
    ChatMessage? replyToMessage,
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Mesaj göndermek için giriş yapmalısınız.');
    }

    final user = _auth.currentUser!;

    // Kullanıcının banned olup olmadığını kontrol et
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    final roomData = roomDoc.data();
    final List<String> bannedUsers =
        List<String>.from(roomData?['bannedUsers'] ?? []);

    if (bannedUsers.contains(user.uid)) {
      throw Exception('Bu odadan yasaklandığınız için mesaj gönderemezsiniz.');
    }

    // Kullanıcının nickname ve profil fotoğrafını Firestore'dan çekme
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final nickname = userDoc.data()?['nickname'] ?? 'Anonim Kullanıcı';
    final profileImageUrl = userDoc.data()?['profileImageUrl'];

    Map<String, dynamic> messageData = {
      'roomId': roomId,
      'userId': user.uid,
      'username': nickname,
      'userProfileImage': profileImageUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    };

    // Reply bilgilerini ekle
    if (replyToMessage != null) {
      messageData.addAll({
        'replyToMessageId': replyToMessage.id,
        'replyToContent': replyToMessage.content,
        'replyToUsername': replyToMessage.username,
      });
    }

    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .add(messageData);
  }

  // Mesaja beğeni ekle
  Future<void> likeMessage(ChatMessage message) async {
    if (_auth.currentUser == null) return;

    await _firestore
        .collection('chatRooms')
        .doc(message.roomId)
        .collection('messages')
        .doc(message.id)
        .update({
      'likes': FieldValue.increment(1),
    });
  }

  // kullanıcıyı sohbet odasına ekle
  Future<void> joinRoom(String roomId) async {
    if (_auth.currentUser == null) return;

    final user = _auth.currentUser!;

    // Kullanıcının banned olup olmadığını kontrol et
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    final roomData = roomDoc.data();
    final List<String> bannedUsers =
        List<String>.from(roomData?['bannedUsers'] ?? []);

    if (bannedUsers.contains(user.uid)) {
      throw Exception('Bu odaya katılamazsınız, yasaklısınız.');
    }

    await _firestore.collection('chatRooms').doc(roomId).update({
      'users': FieldValue.arrayUnion([user.uid]),
      'activeUsers': FieldValue.arrayUnion([user.uid]),
    });
  }

  // Kullanıcıyı sohbet odasından çıkar
  Future<void> leaveRoom(String roomId) async {
    if (_auth.currentUser == null) return;

    final user = _auth.currentUser!;

    await _firestore.collection('chatRooms').doc(roomId).update({
      'activeUsers': FieldValue.arrayRemove([user.uid]),
      'users': FieldValue.arrayRemove([user.uid]),
    });
  }

  // ADMIN MESAJ YÖNETİMİ METOTLARİ

  // Tüm mesajları getir (Admin için)
  Future<List<Map<String, dynamic>>> getAllMessages({int? limit}) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    List<Map<String, dynamic>> allMessages = [];

    // Tüm chat room'ları al
    final roomsSnapshot = await _firestore.collection('chatRooms').get();

    for (var roomDoc in roomsSnapshot.docs) {
      final roomData = roomDoc.data();

      // Her room için mesajları al
      Query messagesQuery = _firestore
          .collection('chatRooms')
          .doc(roomDoc.id)
          .collection('messages')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        messagesQuery =
            messagesQuery.limit(100); // Her room'dan maksimum 100 mesaj
      }

      final messagesSnapshot = await messagesQuery.get();

      for (var messageDoc in messagesSnapshot.docs) {
        final messageData = messageDoc.data() as Map<String, dynamic>;
        allMessages.add({
          'messageId': messageDoc.id,
          'roomId': roomDoc.id,
          'roomName': roomData['name'] ?? 'Unknown Room',
          ...messageData,
        });
      }
    }

    // Tüm mesajları timestamp'e göre sırala
    allMessages.sort((a, b) {
      final aTimestamp = a['timestamp'] as Timestamp?;
      final bTimestamp = b['timestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp);
    });

    if (limit != null && allMessages.length > limit) {
      allMessages = allMessages.take(limit).toList();
    }

    return allMessages;
  }

  // Belirli bir mesajı sil (Admin için)
  Future<void> deleteMessage(String roomId, String messageId) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Kullanıcıyı odadan yasakla (Admin için)
  Future<void> banUserFromRoom(String userId, String roomId) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    final roomRef = _firestore.collection('chatRooms').doc(roomId);

    await _firestore.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);

      if (!roomDoc.exists) {
        throw Exception('Oda bulunamadı');
      }

      final roomData = roomDoc.data()!;
      final List<String> bannedUsers =
          List<String>.from(roomData['bannedUsers'] ?? []);
      final List<String> users = List<String>.from(roomData['users'] ?? []);
      final List<String> activeUsers =
          List<String>.from(roomData['activeUsers'] ?? []);

      // Kullanıcıyı banned listesine ekle
      if (!bannedUsers.contains(userId)) {
        bannedUsers.add(userId);
      }

      // Kullanıcıyı aktif listelerden çıkar
      users.remove(userId);
      activeUsers.remove(userId);

      transaction.update(roomRef, {
        'bannedUsers': bannedUsers,
        'users': users,
        'activeUsers': activeUsers,
      });
    });
  }

  // Kullanıcının yasağını kaldır (Admin için)
  Future<void> unbanUserFromRoom(String userId, String roomId) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    await _firestore.collection('chatRooms').doc(roomId).update({
      'bannedUsers': FieldValue.arrayRemove([userId]),
    });
  }

  // Yasaklı kullanıcıları getir (Admin için)
  Future<List<Map<String, dynamic>>> getBannedUsers() async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    List<Map<String, dynamic>> bannedUsersList = [];

    final roomsSnapshot = await _firestore.collection('chatRooms').get();

    for (var roomDoc in roomsSnapshot.docs) {
      final roomData = roomDoc.data();
      final List<String> bannedUsers =
          List<String>.from(roomData['bannedUsers'] ?? []);

      for (String userId in bannedUsers) {
        bannedUsersList.add({
          'userId': userId,
          'roomId': roomDoc.id,
          'roomName': roomData['name'] ?? 'Unknown Room',
          'bannedAt':
              DateTime.now(), // Gerçek ban tarihi için ayrı alan eklenebilir
        });
      }
    }

    return bannedUsersList;
  }

  // Odadaki tüm mesajları temizle (Admin için)
  Future<void> clearRoomMessages(String roomId) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    final messagesSnapshot = await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .get();

    // Batch ile tüm mesajları sil
    WriteBatch batch = _firestore.batch();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Kullanıcının belirli bir odadaki mesajlarını getir
  Stream<List<ChatMessage>> getUserMessagesInRoom(
      String roomId, String userId) {
    return _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Mesaj istatistikleri getir (Admin için)
  Future<Map<String, dynamic>> getMessageStats() async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    int totalMessages = 0;
    int totalRooms = 0;
    Map<String, int> roomMessageCounts = {};

    final roomsSnapshot = await _firestore.collection('chatRooms').get();
    totalRooms = roomsSnapshot.docs.length;

    for (var roomDoc in roomsSnapshot.docs) {
      final roomData = roomDoc.data();
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(roomDoc.id)
          .collection('messages')
          .get();

      int messageCount = messagesSnapshot.docs.length;
      totalMessages += messageCount;
      roomMessageCounts[roomData['name'] ?? 'Unknown Room'] = messageCount;
    }

    return {
      'totalMessages': totalMessages,
      'totalRooms': totalRooms,
      'roomMessageCounts': roomMessageCounts,
      'averageMessagesPerRoom':
          totalRooms > 0 ? (totalMessages / totalRooms).round() : 0,
    };
  }

  Future<void> reportMessage({
    required String roomId,
    required String messageId,
    required String messageContent,
    required String messageUserId,
    required String messageUserName,
    required String reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('reportedMessages').add({
      'messageId': messageId,
      'roomId': roomId,
      'messageContent': messageContent,
      'messageUserId': messageUserId,
      'messageUserName': messageUserName,
      'reportedBy': user.uid,
      'reportedByName': user.displayName ?? '',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Belirli tarih aralığındaki mesajları getir
  Future<List<Map<String, dynamic>>> getMessagesByDateRange(
      DateTime startDate, DateTime endDate,
      {String? roomId}) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    List<Map<String, dynamic>> messages = [];

    if (roomId != null) {
      // Belirli bir room için
      final messagesSnapshot = await _firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      final roomDoc =
          await _firestore.collection('chatRooms').doc(roomId).get();
      final roomName = roomDoc.data()?['name'] ?? 'Unknown Room';

      for (var messageDoc in messagesSnapshot.docs) {
        final messageData = messageDoc.data();
        messages.add({
          'messageId': messageDoc.id,
          'roomId': roomId,
          'roomName': roomName,
          ...messageData,
        });
      }
    } else {
      // Tüm room'lar için
      final roomsSnapshot = await _firestore.collection('chatRooms').get();

      for (var roomDoc in roomsSnapshot.docs) {
        final roomData = roomDoc.data();
        final messagesSnapshot = await _firestore
            .collection('chatRooms')
            .doc(roomDoc.id)
            .collection('messages')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .orderBy('timestamp', descending: true)
            .get();

        for (var messageDoc in messagesSnapshot.docs) {
          final messageData = messageDoc.data();
          messages.add({
            'messageId': messageDoc.id,
            'roomId': roomDoc.id,
            'roomName': roomData['name'] ?? 'Unknown Room',
            ...messageData,
          });
        }
      }

      // Tüm mesajları timestamp'e göre sırala
      messages.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;
        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;
        return bTimestamp.compareTo(aTimestamp);
      });
    }

    return messages;
  }

  // Kullanıcının odadan yasaklı olup olmadığını kontrol et
  Future<bool> isUserBannedFromRoom(String userId, String roomId) async {
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();

    if (!roomDoc.exists) return false;

    final roomData = roomDoc.data()!;
    final List<String> bannedUsers =
        List<String>.from(roomData['bannedUsers'] ?? []);

    return bannedUsers.contains(userId);
  }

  // Toplu mesaj silme (Admin için)
  Future<void> deleteBulkMessages(
      List<Map<String, String>> messageReferences) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    WriteBatch batch = _firestore.batch();

    for (var messageRef in messageReferences) {
      final roomId = messageRef['roomId']!;
      final messageId = messageRef['messageId']!;

      batch.delete(_firestore
          .collection('chatRooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId));
    }

    await batch.commit();
  }
}
