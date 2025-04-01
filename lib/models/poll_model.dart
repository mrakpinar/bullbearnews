import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String question;
  final List<PollOption> options;
  final Timestamp createdAt;
  final bool isActive;
  final String createdBy;
  final List<String> votedUserIds; // Yeni eklenen alan

  bool canShowResults(String userId) {
    return votedUserIds.contains(userId);
  }

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.createdAt,
    required this.isActive,
    required this.createdBy,
    required this.votedUserIds,
  });

  factory Poll.fromMap(String id, Map<String, dynamic> map) {
    return Poll(
      id: id,
      question: map['question'] ?? '',
      options: (map['options'] as List<dynamic>?)
              ?.map((opt) => PollOption.fromMap(opt))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp),
      isActive: map['isActive'] ?? false,
      createdBy: map['createdBy'] ?? '',
      votedUserIds: List<String>.from(map['votedUserIds'] ?? []),
    );
  }

  bool hasUserVoted(String userId) {
    return votedUserIds.contains(userId);
  }
}

class PollOption {
  final String text;
  final int votes;

  PollOption({
    required this.text,
    required this.votes,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    return PollOption(
      text: map['text'] ?? '',
      votes: map['votes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'votes': votes,
    };
  }
}
