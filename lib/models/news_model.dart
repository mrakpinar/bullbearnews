import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'news_model.g.dart';

@HiveType(typeId: 0)
class NewsModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final DateTime publishDate;

  @HiveField(6)
  final String author;

  NewsModel({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.publishDate,
    required this.author,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
      publishDate: json['publishDate'] != null
          ? (json['publishDate'] as Timestamp).toDate()
          : DateTime.now(),
      author: json['author'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'publishDate': publishDate.toIso8601String(),
      'author': author,
    };
  }
}
