//views/widgets/video_post_card.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/viewmodels/post_viewmodel.dart';
import 'package:the_shot2/views/edit_post_screen.dart';
import 'custom_video_player.dart';

class VideoPostCard extends StatelessWidget {
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

  void _showPostMenu(BuildContext context, bool isOwner) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isArchivedScreen = currentRoute == '/archived_posts';
    final isSavedScreen = currentRoute == '/saved_posts';
    final viewModel = Provider.of<PostViewModel>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: isOwner && !isSavedScreen
                    ? isArchivedScreen
                    ? [
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text('Are you sure you want to delete this post?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await viewModel.deletePost(
                          postId: post.id,
                          userId: post.userId,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post deleted')),
                          );
                          await viewModel.fetchArchivedPosts(post.userId);
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.unarchive, color: Color(0xFF8A56AC)),
                    title: const Text('Show back on profile'),
                    onTap: () async {
                      Navigator.pop(context);
                      await viewModel.unarchivePost(
                        postId: post.id,
                        userId: post.userId,
                      );
                      if (viewModel.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage!)),
                        );
                        viewModel.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post unarchived')),
                        );
                        await viewModel.fetchArchivedPosts(post.userId);
                      }
                    },
                  ),
                ]
                    : [
                  ListTile(
                    leading: const Icon(Icons.archive, color: Color(0xFF8A56AC)),
                    title: Text(post.isArchived ? 'Unarchive Post' : 'Archive Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      await viewModel.archivePost(
                        postId: post.id,
                        userId: post.userId,
                        archive: !post.isArchived,
                      );
                      if (viewModel.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage!)),
                        );
                        viewModel.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(post.isArchived ? 'Post unarchived' : 'Post archived'),
                          ),
                        );
                        if (!post.isArchived) {
                          await viewModel.fetchUserPosts(post.userId);
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text('Are you sure you want to delete this post?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await viewModel.deletePost(
                          postId: post.id,
                          userId: post.userId,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post deleted')),
                          );
                          await viewModel.fetchUserPosts(post.userId);
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF8A56AC)),
                    title: const Text('Edit Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditPostScreen(post: post),
                        ),
                      );
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post updated')),
                        );
                        await viewModel.fetchUserPosts(post.userId);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.comment, color: Color(0xFF8A56AC)),
                    title: Text(post.commentsDisabled ? 'Enable Comments' : 'Disable Comments'),
                    onTap: () async {
                      Navigator.pop(context);
                      await viewModel.disableComments(
                        postId: post.id,
                        userId: post.userId,
                        disable: !post.commentsDisabled,
                      );
                      if (viewModel.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(viewModel.errorMessage!)),
                        );
                        viewModel.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(post.commentsDisabled ? 'Comments enabled' : 'Comments disabled'),
                          ),
                        );
                      }
                    },
                  ),
                ]
                    : [
                  ListTile(
                    leading: const Icon(Icons.thumb_up, color: Color(0xFF8A56AC)),
                    title: const Text('Interested'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feature coming soon!')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.thumb_down, color: Color(0xFF8A56AC)),
                    title: const Text('Not Interested'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feature coming soon!')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.red),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feature coming soon!')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bookmark, color: Color(0xFF8A56AC)),
                    title: Text(isSavedScreen ? 'Unsave Post' : 'Save Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (isSavedScreen) {
                        await viewModel.unsavePost(
                          postId: post.id,
                          userId: currentUserId!,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post unsaved')),
                          );
                          await viewModel.fetchSavedPosts(currentUserId);
                        }
                      } else {
                        await viewModel.savePost(
                          postId: post.id,
                          postOwnerId: post.userId,
                          userId: currentUserId!,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post saved')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = post.userId == currentUserId;

    return isGridView
        ? Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: post.thumbnailUrl.isNotEmpty ? post.thumbnailUrl : post.imageUrl,
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
        if (showMenuIcon)
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showPostMenu(context, isOwner),
            ),
          ),
      ],
    )
        : Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.type == 'video' && post.videoUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: isThumbnailOnly && post.thumbnailUrl.isNotEmpty
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: post.thumbnailUrl,
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
                    : CustomVideoPlayer(videoUrl: post.videoUrl),
              ),
          ],
        ),
        if (showMenuIcon)
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () => _showPostMenu(context, isOwner),
            ),
          ),
      ],
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