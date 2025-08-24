import 'package:bullbearnews/models/news_model.dart';
import 'package:flutter/material.dart';

class TitleCard extends StatelessWidget {
  final NewsModel news;
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  const TitleCard(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            news.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
              height: 1.3,
              letterSpacing: -0.5,
              fontFamily: 'Mono',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF393E46),
                      const Color(0xFF948979),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  news.category,
                  style: TextStyle(
                    color: const Color(0xFFDFD0B8),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Mono',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: secondaryTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(news.publishDate),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final Map<DateTime, String> _dateCache = {};

  String _formatDate(DateTime date) {
    return _dateCache[date] ??= '${date.day}.${date.month}.${date.year}';
  }
}
