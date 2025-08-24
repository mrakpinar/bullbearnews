import 'package:bullbearnews/models/news_model.dart';
import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  final NewsModel news;
  final Color cardColor;
  final Color textColor;
  const ContentCard(
      {super.key,
      required this.news,
      required this.cardColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        news.content,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textColor.withOpacity(0.9),
          height: 1.6,
          fontFamily: 'Mono',
        ),
      ),
    );
  }
}
