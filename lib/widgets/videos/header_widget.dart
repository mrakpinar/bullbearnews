import 'package:bullbearnews/models/video_model.dart';
import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final bool isDark;
  final Animation<double> headerAnimation;
  final List<VideoModel> filteredVideos;
  const HeaderWidget(
      {super.key,
      required this.isDark,
      required this.headerAnimation,
      required this.filteredVideos});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: headerAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - headerAnimation.value)),
          child: Opacity(
            opacity: headerAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF393E46),
                                    const Color(0xFF948979),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill,
                                color: Color(0xFFDFD0B8),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Crypto Videos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? const Color(0xFFDFD0B8)
                                    : const Color(0xFF222831),
                                letterSpacing: -0.5,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Educational crypto content 🎥',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF948979)
                                    : const Color(0xFF393E46),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'DMSerif',
                              ),
                            ),
                            if (filteredVideos.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF393E46)
                                      : const Color(0xFF948979),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${filteredVideos.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDFD0B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
