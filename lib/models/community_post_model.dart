import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String content;
  final DateTime timestamp;
  final int likes;
  final String? userProfileImage;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.content,
    required this.timestamp,
    this.likes = 0,
    this.userProfileImage,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'],
      username: data['username'],
      content: data['content'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      userProfileImage: data['userProfileImage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'userProfileImage': userProfileImage,
    };
  }
}
