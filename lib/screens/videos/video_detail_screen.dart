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
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
        hideControls: false,
        hideThumbnail: false,
        showLiveFullscreenButton: false,
      ),
    )..addListener(_onPlayerStateChange);
  }

  void _onPlayerStateChange() {
    if (_controller.value.hasError) {
      debugPrint('YouTube Player Error: ${_controller.value.errorCode}');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final textColor = isLight ? Colors.black : Colors.white;

    return Scaffold(
      appBar: _buildAppBar(context, theme, isLight, textColor),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoPlayer(theme),
            _buildVideoInfo(theme, isLight, textColor),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, ThemeData theme, bool isLight, Color textColor) {
    return AppBar(
      title: Text(
        widget.video.title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_sharp,
          color: textColor,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: textColor, size: 20),
          onPressed: _onSharePressed,
        ),
        IconButton(
          icon: Icon(Icons.save, color: textColor, size: 20),
          onPressed: _onSavePressed,
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildVideoPlayer(ThemeData theme) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: theme.primaryColor,
      progressColors: ProgressBarColors(
        playedColor: theme.primaryColor,
        handleColor: theme.primaryColor,
        bufferedColor: theme.primaryColor.withOpacity(0.5),
        backgroundColor: theme.brightness == Brightness.light
            ? Colors.black.withOpacity(0.1)
            : Colors.white.withOpacity(0.1),
      ),
      onReady: () {
        // Video hazır olduğunda gerekli işlemler
      },
    );
  }

  Widget _buildVideoInfo(ThemeData theme, bool isLight, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.video.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildVideoMetadata(theme, isLight),
          if (widget.video.description.isNotEmpty)
            _buildDescription(theme, isLight),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVideoMetadata(ThemeData theme, bool isLight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.video.category,
            style: TextStyle(
              color: isLight ? theme.primaryColor : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.5,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          _formatDate(widget.video.publishDate),
          style: TextStyle(
            color: isLight
                ? Colors.black.withOpacity(0.7)
                : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme, bool isLight) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withOpacity(0.1)
                : Colors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        widget.video.description,
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: isLight
              ? Colors.black.withOpacity(0.7)
              : Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          fontFamily: 'Mono',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}.${date.month}.${date.year}";
  }

  void _onSharePressed() {
    // Share functionality implementation
  }

  void _onSavePressed() {
    // Save functionality implementation
  }
}
