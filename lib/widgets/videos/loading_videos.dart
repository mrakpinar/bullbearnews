import 'package:flutter/material.dart';

class LoadingVideos extends StatelessWidget {
  final bool isDark;
  const LoadingVideos({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF393E46).withOpacity(0.1),
                  const Color(0xFF948979).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading crypto videos...',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🎥 Educational content loading',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontSize: 14,
              fontFamily: 'DMSerif',
            ),
          ),
        ],
      ),
    );
  }
}
