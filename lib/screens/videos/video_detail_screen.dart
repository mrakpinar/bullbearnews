import 'package:bullbearnews/models/video_model.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoDetailScreen extends StatefulWidget {
  final VideoModel video;

  const VideoDetailScreen({super.key, required this.video});

  @override
  _VideoDetailScreenState createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoID,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
        hideControls: false,
        hideThumbnail: false,
        showLiveFullscreenButton: false,
      ),
    )..addListener(() {
        if (_controller.value.hasError) {
          print('Error: ${_controller.value.errorCode}');
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.video.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
        ),
        titleTextStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_sharp,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.black
                : Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.share,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
                size: 20),
            onPressed: () {
              // Share functionality can be implemented here
            },
          ),
          IconButton(
            icon: Icon(
              Icons.save,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
              size: 20,
            ),
            onPressed: () {
              // Save functionality can be implemented here
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Theme.of(context).primaryColor,
              progressColors: ProgressBarColors(
                playedColor: Theme.of(context).primaryColor,
                handleColor: Theme.of(context).primaryColor,
                bufferedColor: Theme.of(context).primaryColor.withOpacity(0.5),
                backgroundColor:
                    Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withOpacity(0.1)
                        : Colors.white.withOpacity(0.1),
              ),
              onReady: () {
                _controller.addListener(() {});
              },
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.video.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
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
                          widget.video.category,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Theme.of(context).primaryColor
                                    : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "${widget.video.publishDate.day}.${widget.video.publishDate.month}.${widget.video.publishDate.year}",
                        style: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (widget.video.description.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.video.description,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
