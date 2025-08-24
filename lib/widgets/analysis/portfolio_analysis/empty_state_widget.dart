import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isDark;
  const EmptyStateWidget({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF393E46).withOpacity(0.3)
                  : Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Assets Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFDFD0B8) : const Color(0xFF222831),
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add cryptocurrencies to your portfolio to start analysis',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }
}
