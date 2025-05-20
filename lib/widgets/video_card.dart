import 'package:bullbearnews/screens/videos/video_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;

  const VideoCard({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.2),
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.grey.withOpacity(0.2)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoDetailScreen(video: video),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    video.thumbnailUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                    },
                  ),
                  // Play button overlay
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    // Play icon
                    child: Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Video details
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (video.description.isNotEmpty)
                    Text(
                      video.description,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          video.category,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        "${video.publishDate.day}.${video.publishDate.month}.${video.publishDate.year}",
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black.withOpacity(0.7)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
