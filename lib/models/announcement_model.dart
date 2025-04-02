import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.isActive,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    return Announcement(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? false,
    );
  }
}
