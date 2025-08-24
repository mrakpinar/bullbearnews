import 'package:flutter/material.dart';

class EmptyVideos extends StatelessWidget {
  final bool isDark;
  final String selectedCategory;
  final VoidCallback onRefresh;

  const EmptyVideos({
    super.key,
    required this.isDark,
    required this.selectedCategory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF393E46).withOpacity(0.1),
                  const Color(0xFF948979).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.video_library_outlined,
              size: 64,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            selectedCategory == 'All'
                ? 'No crypto videos available'
                : 'No ${selectedCategory.toLowerCase()} videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            selectedCategory == 'All'
                ? '📺 Check back later for new content'
                : '🔄 Try selecting a different category',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? const Color(0xFF948979).withOpacity(0.7)
                  : const Color(0xFF393E46).withOpacity(0.7),
              fontFamily: 'DMSerif',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF393E46),
                      const Color(0xFF948979),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF948979).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: const Color(0xFFDFD0B8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Refresh Videos',
                      style: TextStyle(
                        color: const Color(0xFFDFD0B8),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DMSerif',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
