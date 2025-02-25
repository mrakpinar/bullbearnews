import 'package:cloud_firestore/cloud_firestore.dart';

class NewsModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String category;
  final DateTime publishDate;
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
      publishDate: json['publishDate'] != null
          ? (json['publishDate'] as Timestamp).toDate()
          : DateTime.now(),
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
      'publishDate': publishDate.toIso8601String(),
      'author': author,
    };
  }
}
