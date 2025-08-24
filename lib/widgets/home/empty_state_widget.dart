import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isDark;
  final String selectedCategory;
  final bool isRefreshing;
  final VoidCallback refreshNews;
  const EmptyStateWidget(
      {super.key,
      required this.isDark,
      required this.selectedCategory,
      required this.isRefreshing,
      required this.refreshNews});

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
              Icons.article_outlined,
              size: 64,
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No ${selectedCategory == 'All' ? 'crypto' : selectedCategory} news',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '📱 Pull down to refresh for latest updates',
            style: TextStyle(
              color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
              fontSize: 14,
              fontFamily: 'DMSerif',
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: refreshNews,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF393E46), Color(0xFF948979)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRefreshing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFDFD0B8)),
                        ),
                      )
                    else
                      const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFFDFD0B8),
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      isRefreshing ? 'Refreshing...' : 'Refresh Now',
                      style: const TextStyle(
                        color: Color(0xFFDFD0B8),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'DMSerif',
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
