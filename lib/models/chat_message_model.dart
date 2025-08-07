import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? userProfileImage;
  final String content;
  final DateTime timestamp;
  final int likes;
  final String? replyToMessageId; // Yanıtlanan mesaj ID'si
  final String? replyToContent; // Yanıtlanan mesaj içeriği
  final String? replyToUsername; // Yanıtlanan mesajın kullanıcı adı

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.content,
    required this.timestamp,
    required this.likes,
    this.replyToMessageId,
    this.replyToContent,
    this.replyToUsername,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      userProfileImage: data['userProfileImage'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      replyToMessageId: data['replyToMessageId'],
      replyToContent: data['replyToContent'],
      replyToUsername: data['replyToUsername'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
      'replyToMessageId': replyToMessageId,
      'replyToContent': replyToContent,
      'replyToUsername': replyToUsername,
    };
  }

  bool get hasReply => replyToMessageId != null && replyToContent != null;
}
