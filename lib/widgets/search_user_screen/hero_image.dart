import 'package:bullbearnews/models/news_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HeroImage extends StatelessWidget {
  final bool isDark;
  final NewsModel? news;

  const HeroImage({super.key, required this.isDark, this.news});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    news!.imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 300,
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      width: 300,
                      height: 300,
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: news!.imageUrl,
            fit: BoxFit.cover,
            imageBuilder: (context, imageProvider) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              clipBehavior: Clip.hardEdge,
            ),
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF948979) : const Color(0xFF393E46),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? const Color(0xFF393E46) : Colors.grey[200],
              child: Icon(
                Icons.image,
                size: 50,
                color: isDark
                    ? const Color(0xFF948979)
                    : const Color(0xFF393E46).withOpacity(0.5),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
                tileMode: TileMode.clamp,
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16.0),
          ),
        ],
      ),
    );
  }
}
