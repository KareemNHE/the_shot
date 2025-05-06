//views/widgets/custom_video_player.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CustomVideoPlayer extends StatefulWidget {
  final String? videoUrl;
  final File? videoFile;
  final bool isLocalFile;

  const CustomVideoPlayer({
    Key? key,
    this.videoUrl,
    this.videoFile,
    this.isLocalFile = false,
  }) : super(key: key);

  @override
  _CustomVideoPlayerState createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _isVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialization delayed until widget is visible
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.isLocalFile && widget.videoFile != null) {
        _videoPlayerController = VideoPlayerController.file(widget.videoFile!);
      } else if (widget.videoUrl != null) {
        final fileInfo = await DefaultCacheManager().getFileFromCache(widget.videoUrl!);
        if (fileInfo != null && fileInfo.file.existsSync()) {
          _videoPlayerController = VideoPlayerController.file(fileInfo.file);
        } else {
          _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
          await DefaultCacheManager().getSingleFile(widget.videoUrl!);
        }
      } else {
        throw Exception('No video URL or file provided');
      }

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error loading video: $errorMessage',
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize video: $e';
        });
      }
      print('Error initializing video: ${widget.videoUrl ?? widget.videoFile?.path}, Error: $e');
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.videoUrl ?? widget.videoFile?.path ?? ''),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.5 && !_isInitialized && !_isVisible) {
          if (!mounted) return;
          setState(() {
            _isVisible = true;
          });
          _initializePlayer();
        } else if (info.visibleFraction <= 0.5 && _isVisible) {
          if (!mounted) return;
          setState(() {
            _isVisible = false;
          });
          _chewieController?.pause();
        }
      },
      child: _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : _isInitialized && _chewieController != null
          ? GestureDetector(
        onTap: () {
          if (_chewieController!.isPlaying) {
            _chewieController!.pause();
          } else {
            _chewieController!.play();
          }
        },
        child: Chewie(controller: _chewieController!),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}