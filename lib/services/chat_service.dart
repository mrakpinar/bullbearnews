import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';
import 'notification_service.dart'; // NotificationService'i import et

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService =
      NotificationService(); // NotificationService instance

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  bool isCurrentUser(String userId) {
    return _auth.currentUser?.uid == userId;
  }

  Stream<List<ChatRoom>> getChatRooms() {
    return _firestore
        .collection('chatRooms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
    });
  }

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

  // Mesajdaki mention'ları parse et
  Future<Map<String, dynamic>> _parseMentions(
      String content, String roomId) async {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(content);

    List<String> mentionedUserIds = [];
    Map<String, String> mentionedUsers = {};

    if (matches.isNotEmpty) {
      try {
        // Room'daki kullanıcıları al
        final roomDoc =
            await _firestore.collection('chatRooms').doc(roomId).get();

        if (!roomDoc.exists) {
          print('Debug - Room not found: $roomId');
          return {
            'mentionedUserIds': mentionedUserIds,
            'mentionedUsers': mentionedUsers,
          };
        }

        final roomData = roomDoc.data();
        final userIds = List<String>.from(roomData?['users'] ?? []);

        print('Debug - Room users: $userIds');

        // Tüm kullanıcı bilgilerini toplu olarak çek
        final userDocs = await Future.wait(
          userIds.map(
              (userId) => _firestore.collection('users').doc(userId).get()),
        );

        // Kullanıcı bilgilerini map'e çevir
        final userDataMap = <String, Map<String, dynamic>>{};
        for (int i = 0; i < userIds.length; i++) {
          if (userDocs[i].exists) {
            userDataMap[userIds[i]] =
                userDocs[i].data() as Map<String, dynamic>;
          }
        }

        print('Debug - User data map: $userDataMap');

        // Her mention için kullanıcı bilgilerini kontrol et
        for (final match in matches) {
          final username = match.group(1)!;
          print('Debug - Processing mention: @$username');

          // Username'e göre kullanıcıyı bul
          for (final entry in userDataMap.entries) {
            final userId = entry.key;
            final userData = entry.value;
            final userNickname = (userData['nickname'] ?? '').toString();

            print('Debug - Checking user: $userId, nickname: $userNickname');

            if (userNickname.toLowerCase() == username.toLowerCase()) {
              if (!mentionedUserIds.contains(userId)) {
                mentionedUserIds.add(userId);
                mentionedUsers[userId] = userNickname;
                print('Debug - Added mention: $userId -> $userNickname');
              }
              break;
            }
          }
        }

        print('Debug - Final mentioned users: $mentionedUsers');
        print('Debug - Final mentioned user IDs: $mentionedUserIds');
      } catch (e) {
        print('Debug - Error parsing mentions: $e');
      }
    }

    return {
      'mentionedUserIds': mentionedUserIds,
      'mentionedUsers': mentionedUsers,
    };
  }

  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final roomDoc =
          await _firestore.collection('chatRooms').doc(roomId).get();

      if (!roomDoc.exists) {
        return null;
      }

      return ChatRoom.fromFirestore(roomDoc);
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  // YENİ: Mention bildirimi gönder
  Future<void> _sendMentionNotifications(
    List<String> mentionedUserIds,
    String roomId,
    String messageContent,
    String senderUsername,
    String messageId,
  ) async {
    if (mentionedUserIds.isEmpty) return;

    try {
      // Room bilgilerini al
      final roomDoc =
          await _firestore.collection('chatRooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final roomData = roomDoc.data()!;
      final roomName = roomData['name'] ?? 'Chat Room';

      print(
          '🔔 Sending mention notifications to ${mentionedUserIds.length} users in room: $roomName');

      // Her mention edilen kullanıcıya bildirim gönder
      for (final userId in mentionedUserIds) {
        print('📤 Sending mention notification to: $userId');

        await _notificationService.sendChatMentionNotification(
          mentionedUserId: userId,
          roomId: roomId,
          roomName: roomName,
          messageContent: messageContent,
          messageId: messageId,
        );

        print('✅ Mention notification sent to: $userId');
      }

      print('🎉 All mention notifications sent successfully');
    } catch (e) {
      print('❌ Error sending mention notifications: $e');
    }
  }

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

    // Mention'ları parse et
    final mentionData = await _parseMentions(content, roomId);
    final mentionedUserIds = mentionData['mentionedUserIds'] as List<String>;
    final mentionedUsers = mentionData['mentionedUsers'] as Map<String, String>;

    Map<String, dynamic> messageData = {
      'roomId': roomId,
      'userId': user.uid,
      'username': nickname,
      'userProfileImage': profileImageUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'mentionedUserIds': mentionedUserIds,
      'mentionedUsers': mentionedUsers,
    };

    // Reply bilgilerini ekle
    if (replyToMessage != null) {
      messageData.addAll({
        'replyToMessageId': replyToMessage.id,
        'replyToContent': replyToMessage.content,
        'replyToUsername': replyToMessage.username,
      });
    }

    // Mesajı Firestore'a kaydet
    final messageRef = await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .add(messageData);

    // Mention bildirimlerini gönder
    if (mentionedUserIds.isNotEmpty) {
      await _sendMentionNotifications(
        mentionedUserIds,
        roomId,
        content,
        nickname,
        messageRef.id, // Mesajın ID'sini geç
      );
    }
  }

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

  Future<void> joinRoom(String roomId) async {
    if (_auth.currentUser == null) return;

    final user = _auth.currentUser!;

    // Kullanıcının banned olup olmadığını kontrol et
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();
    final roomData = roomDoc.data();
    final List<String> bannedUsers =
        List<String>.from(roomData?['bannedUsers'] ?? []);

    if (bannedUsers.contains(user.uid)) {
      throw Exception('You cannot join this room, You are banned!!.');
    }

    await _firestore.collection('chatRooms').doc(roomId).update({
      'users': FieldValue.arrayUnion([user.uid]),
      'activeUsers': FieldValue.arrayUnion([user.uid]),
    });
  }

  Future<void> leaveRoom(String roomId) async {
    if (_auth.currentUser == null) return;

    final user = _auth.currentUser!;

    await _firestore.collection('chatRooms').doc(roomId).update({
      'activeUsers': FieldValue.arrayRemove([user.uid]),
      'users': FieldValue.arrayRemove([user.uid]),
    });
  }

  // Admin metodları...
  Future<List<Map<String, dynamic>>> getAllMessages({int? limit}) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    List<Map<String, dynamic>> allMessages = [];

    final roomsSnapshot = await _firestore.collection('chatRooms').get();

    for (var roomDoc in roomsSnapshot.docs) {
      final roomData = roomDoc.data();

      Query messagesQuery = _firestore
          .collection('chatRooms')
          .doc(roomDoc.id)
          .collection('messages')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        messagesQuery = messagesQuery.limit(100);
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

      if (!bannedUsers.contains(userId)) {
        bannedUsers.add(userId);
      }

      users.remove(userId);
      activeUsers.remove(userId);

      transaction.update(roomRef, {
        'bannedUsers': bannedUsers,
        'users': users,
        'activeUsers': activeUsers,
      });
    });
  }

  Future<void> unbanUserFromRoom(String userId, String roomId) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    await _firestore.collection('chatRooms').doc(roomId).update({
      'bannedUsers': FieldValue.arrayRemove([userId]),
    });
  }

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
          'bannedAt': DateTime.now(),
        });
      }
    }

    return bannedUsersList;
  }

  Future<void> clearRoomMessages(String roomId) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    final messagesSnapshot = await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .get();

    WriteBatch batch = _firestore.batch();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

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

  Future<List<Map<String, dynamic>>> getMessagesByDateRange(
      DateTime startDate, DateTime endDate,
      {String? roomId}) async {
    if (_auth.currentUser == null) {
      throw Exception('Yetkisiz erişim');
    }

    List<Map<String, dynamic>> messages = [];

    if (roomId != null) {
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

  Future<bool> isUserBannedFromRoom(String userId, String roomId) async {
    final roomDoc = await _firestore.collection('chatRooms').doc(roomId).get();

    if (!roomDoc.exists) return false;

    final roomData = roomDoc.data()!;
    final List<String> bannedUsers =
        List<String>.from(roomData['bannedUsers'] ?? []);

    return bannedUsers.contains(userId);
  }

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
