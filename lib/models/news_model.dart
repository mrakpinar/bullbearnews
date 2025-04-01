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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? '',
      publishDate: (json['publishDate'] as Timestamp).toDate(),
      author: json['author'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'publishDate': Timestamp.fromDate(publishDate),
      'author': author,
    };
  }
}
