import 'package:bullbearnews/models/video_model.dart';
import 'package:flutter/material.dart';

class CategoryFilter extends StatelessWidget {
  final bool isDark;
  final String selectedCategory;
  final List<VideoModel> allVideos;
  final Animation<double> categoryAnimation;
  final Function(String) onCategorySelected;
  CategoryFilter({
    super.key,
    required this.isDark,
    required this.categoryAnimation,
    required this.selectedCategory,
    required this.allVideos,
    required this.onCategorySelected,
  });

  final List<Map<String, String>> _categories = [
    {'name': 'All', 'icon': '🎬'},
    {'name': 'Tutorial', 'icon': '📚'},
    {'name': 'News', 'icon': '📰'},
    {'name': 'Analysis', 'icon': '📊'},
    {'name': 'Interview', 'icon': '🎤'},
    {'name': 'Review', 'icon': '⭐'},
    {'name': 'Trading', 'icon': '📈'},
    {'name': 'DeFi', 'icon': '🏦'},
    {'name': 'NFT', 'icon': '🎨'},
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: categoryAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - categoryAnimation.value)),
          child: Opacity(
            opacity: categoryAnimation.value,
            child: Container(
              height: 58,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final categoryName = category['name']!;
                  final categoryIcon = category['icon']!;
                  final isSelected = categoryName == selectedCategory;

                  int categoryCount = 0;
                  if (categoryName == 'All') {
                    categoryCount = allVideos.length;
                  } else {
                    categoryCount = allVideos
                        .where((video) =>
                            video.category.toLowerCase() ==
                            categoryName.toLowerCase())
                        .length;
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onCategorySelected(categoryName),
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      const Color(0xFF393E46),
                                      const Color(0xFF948979),
                                    ],
                                  )
                                : null,
                            color: !isSelected
                                ? (isDark
                                    ? const Color(0xFF393E46).withOpacity(0.3)
                                    : Colors.white.withOpacity(0.7))
                                : null,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : (isDark
                                      ? const Color(0xFF948979).withOpacity(0.3)
                                      : const Color(0xFF393E46)
                                          .withOpacity(0.2)),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF948979)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                categoryIcon,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categoryName,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFDFD0B8)
                                      : (isDark
                                          ? const Color(0xFF948979)
                                          : const Color(0xFF393E46)),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  fontFamily: 'DMSerif',
                                ),
                              ),
                              if (categoryCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFDFD0B8)
                                            .withOpacity(0.2)
                                        : (isDark
                                            ? const Color(0xFF948979)
                                                .withOpacity(0.2)
                                            : const Color(0xFF393E46)
                                                .withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$categoryCount',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFDFD0B8)
                                          : (isDark
                                              ? const Color(0xFF948979)
                                              : const Color(0xFF393E46)),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
