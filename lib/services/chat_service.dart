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

  // Mesaj gönder
  Future<void> sendMessage(String roomId, String content) async {
    if (_auth.currentUser == null) {
      throw Exception('Mesaj göndermek için giriş yapmalısınız.');
    }

    final user = _auth.currentUser!;

    // Kullanıcının nickname'ini Firestore'dan çekme
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final nickname = userDoc.data()?['nickname'] ?? 'Anonim Kullanıcı';

    await _firestore
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'roomId': roomId,
      'userId': user.uid,
      'username': nickname,
      'userProfileImage': user.photoURL,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
    });
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
}
