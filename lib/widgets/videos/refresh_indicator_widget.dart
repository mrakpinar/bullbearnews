import 'package:bullbearnews/models/video_model.dart';
import 'package:bullbearnews/widgets/video_card.dart';
import 'package:flutter/material.dart';

class RefreshIndicatorWidget extends StatelessWidget {
  final bool isDark;
  final Future<void> Function() loadVideos; // Değişiklik burada
  final ScrollController scrollController;
  final List<VideoModel> filteredVideos;
  final bool isLoadingMore;

  const RefreshIndicatorWidget(
      {super.key,
      required this.isDark,
      required this.loadVideos,
      required this.scrollController,
      required this.filteredVideos,
      required this.isLoadingMore});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadVideos, // Artık direkt kullanabilirsiniz
      color: isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
      backgroundColor:
          isDark ? const Color(0xFF393E46) : const Color(0xFFDFD0B8),
      strokeWidth: 3,
      displacement: 40,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: filteredVideos.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the end
          if (index == filteredVideos.length) {
            return isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark
                              ? const Color(0xFF948979)
                              : const Color(0xFF393E46),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeOut,
            child: VideoCard(
              video: filteredVideos[index],
              key: ValueKey(filteredVideos[index].videoID),
            ),
          );
        },
      ),
    );
  }
}
