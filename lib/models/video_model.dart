class VideoModel {
  final String id;
  final String title;
  final String videoID;
  final String description;
  final String category;
  final String thumbnailUrl;
  final DateTime publishDate;

  VideoModel({
    required this.id,
    required this.title,
    required this.videoID,
    required this.description,
    required this.category,
    required this.thumbnailUrl,
    required this.publishDate,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String id) {
    return VideoModel(
      id: id,
      title: map['title'] ?? '',
      videoID: map['videoID'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      publishDate: map['publishDate']?.toDate() ?? DateTime.now(),
    );
  }
}
