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

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.content,
    required this.timestamp,
    this.likes = 0,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatMessage(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImage: data['userProfileImage'],
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
    );
  }
}
