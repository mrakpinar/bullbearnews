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

  ChatRoom({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.createdBy,
    required this.createdByEmail,
    this.messageCount = 0,
    this.isActive = true,
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
      isActive: data['isActive'] ?? true, // Load isActive from Firestore
    );
  }
}
