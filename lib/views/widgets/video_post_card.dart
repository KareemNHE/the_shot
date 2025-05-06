//views/widgets/video_post_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'custom_video_player.dart';

class VideoPostCard extends StatefulWidget {
  final PostModel post;
  final bool isThumbnailOnly;
  final bool isGridView;
  final bool showMenuIcon;

  const VideoPostCard({
    Key? key,
    required this.post,
    this.isThumbnailOnly = false,
    this.isGridView = false,
    this.showMenuIcon = true,
  }) : super(key: key);

  @override
  _VideoPostCardState createState() => _VideoPostCardState();
}

class _VideoPostCardState extends State<VideoPostCard> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.post.id),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !_isVisible) {
          if (mounted) {
            setState(() {
              _isVisible = true;
              print('VideoPostCard: Visible, videoUrl=${widget.post.videoUrl}');
            });
          }
        } else if (info.visibleFraction <= 0.5 && _isVisible) {
          if (mounted) {
            setState(() {
              _isVisible = false;
              print('VideoPostCard: Not visible, pausing video');
            });
          }
        }
      },
      child: widget.isGridView
          ? Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.post.thumbnailUrl.isNotEmpty ? widget.post.thumbnailUrl : widget.post.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
            cacheManager: DefaultCacheManager(),
          ),
          Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 40,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.post.type == 'video' && widget.post.videoUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: widget.isThumbnailOnly || !_isVisible
                  ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.post.thumbnailUrl.isNotEmpty ? widget.post.thumbnailUrl : widget.post.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                    cacheManager: DefaultCacheManager(),
                  ),
                  Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 60,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              )
                  : CustomVideoPlayer(videoUrl: widget.post.videoUrl),
            ),
        ],
      ),
    );
  }
}

class CachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String) placeholder;
  final Widget Function(BuildContext, String, dynamic) errorWidget;
  final BaseCacheManager cacheManager;

  const CachedNetworkImage({
    Key? key,
    required this.imageUrl,
    required this.fit,
    this.width,
    this.height,
    required this.placeholder,
    required this.errorWidget,
    required this.cacheManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return errorWidget(context, imageUrl, 'Empty URL');
    }
    return FutureBuilder<FileInfo?>(
      future: cacheManager.getFileFromCache(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.file.existsSync()) {
          return Image.file(
            snapshot.data!.file,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) => errorWidget(context, imageUrl, error),
          );
        }
        return Image.network(
          imageUrl,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder(context, imageUrl);
          },
          errorBuilder: (context, error, stackTrace) => errorWidget(context, imageUrl, error),
        );
      },
    );
  }
}