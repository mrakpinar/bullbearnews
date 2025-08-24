import 'package:flutter/material.dart';

class SentimentChipWidget extends StatelessWidget {
  final String sentiment;
  final double confidence;
  final bool isDark;
  const SentimentChipWidget({
    super.key,
    required this.sentiment,
    required this.confidence,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    IconData chipIcon;

    switch (sentiment.toLowerCase()) {
      case 'bullish':
        chipColor = Colors.green;
        chipIcon = Icons.trending_up;
        break;
      case 'bearish':
        chipColor = Colors.red;
        chipIcon = Icons.trending_down;
        break;
      default:
        chipColor = Colors.orange;
        chipIcon = Icons.trending_flat;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: chipColor, size: 16),
          const SizedBox(width: 4),
          Text(
            sentiment,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(confidence * 100).toInt()}%',
            style: TextStyle(
              color: chipColor.withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }
}
