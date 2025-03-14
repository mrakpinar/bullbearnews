import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String createdBy;
  final String createdByEmail;
  final int messageCount;
  final bool isActive;
  final List<String> users;
  final List<String> activeUsers;

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.createdBy,
    required this.createdByEmail,
    this.messageCount = 0,
    this.isActive = true,
    this.users = const [],
    this.activeUsers = const [],
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      createdByEmail: data['createdByEmail'] ?? '',
      messageCount: data['messageCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      users: List<String>.from(data['users'] ?? []),
      activeUsers: List<String>.from(data['activeUsers'] ?? []),
    );
  }
}
