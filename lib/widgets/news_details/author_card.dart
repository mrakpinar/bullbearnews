import 'package:bullbearnews/models/news_model.dart';
import 'package:flutter/material.dart';

class AuthorCard extends StatelessWidget {
  final NewsModel news;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;

  const AuthorCard(
      {super.key,
      required this.news,
      required this.cardColor,
      required this.textColor,
      required this.secondaryTextColor});

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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF393E46),
                  const Color(0xFF948979),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                news.author.isNotEmpty ? news.author[0].toUpperCase() : 'A',
                style: TextStyle(
                  color: const Color(0xFFDFD0B8),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Author',
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                news.author,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
