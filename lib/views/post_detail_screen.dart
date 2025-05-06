// views/post_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/viewmodels/post_viewmodel.dart';
import 'package:the_shot2/views/comment_section_screen.dart';
import 'package:the_shot2/views/edit_post_screen.dart';
import 'package:the_shot2/views/post_share_screen.dart';
import 'package:the_shot2/views/user_profile_screen.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel? post;
  final String? postId;
  final String? postOwnerId;

  const PostDetailScreen({Key? key, this.post, this.postId, this.postOwnerId}) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  PostModel? _post;
  bool _isLoading = true;
  bool _showVideo = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    if (widget.post != null) {
      _post = widget.post!;
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMounted) {
          Provider.of<PostViewModel>(context, listen: false)
              .checkIfPostIsSaved(_post!.id, FirebaseAuth.instance.currentUser?.uid ?? '');
        }
      });
    } else {
      _fetchPost();
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _fetchPost() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.postOwnerId)
          .collection('posts')
          .doc(widget.postId)
          .get();

      final data = doc.data();
      if (data != null) {
        PostModel post = PostModel.fromFirestore(data, doc.id);

        if (post.username == 'Unknown' || post.userProfilePic.isEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(post.userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            post = PostModel(
              id: post.id,
              userId: post.userId,
              username: userData['username'] ?? 'Unknown',
              userProfilePic: userData['profile_picture'] ?? '',
              imageUrl: post.imageUrl,
              videoUrl: post.videoUrl,
              thumbnailUrl: post.thumbnailUrl,
              caption: post.caption,
              timestamp: post.timestamp,
              hashtags: post.hashtags,
              category: post.category,
              type: post.type,
              isArchived: post.isArchived,
              commentsDisabled: post.commentsDisabled,
            );
          }
        }

        if (_isMounted) {
          setState(() {
            _post = post;
            _isLoading = false;
          });
          Provider.of<PostViewModel>(context, listen: false)
              .checkIfPostIsSaved(post.id, FirebaseAuth.instance.currentUser?.uid ?? '');
        }
      } else {
        _showPostNotFound();
      }
    } catch (e) {
      _showPostNotFound();
    }
  }

  void _showPostNotFound() {
    if (_isMounted) {
      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isMounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Post not found"),
              content: const Text("This post may have been deleted or doesn't exist."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      });
    }
  }

  void _showPostMenu(BuildContext context, bool isOwner) {
    final viewModel = Provider.of<PostViewModel>(context, listen: false);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSavedScreen = ModalRoute.of(context)?.settings.name == '/saved_posts';

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
                children: isOwner
                    ? [
                  ListTile(
                    leading: const Icon(Icons.archive, color: Color(0xFF8A56AC)),
                    title: Text(_post!.isArchived ? 'Unarchive Post' : 'Archive Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_post!.isArchived) {
                        await viewModel.unarchivePost(
                          postId: _post!.id,
                          userId: _post!.userId,
                          context: context,
                        );
                        if (_isMounted) {
                          if (viewModel.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(viewModel.errorMessage!)),
                            );
                            viewModel.clearError();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post unarchived')),
                            );
                            setState(() {
                              _post = PostModel(
                                id: _post!.id,
                                userId: _post!.userId,
                                username: _post!.username,
                                userProfilePic: _post!.userProfilePic,
                                imageUrl: _post!.imageUrl,
                                videoUrl: _post!.videoUrl,
                                thumbnailUrl: _post!.thumbnailUrl,
                                caption: _post!.caption,
                                timestamp: _post!.timestamp,
                                hashtags: _post!.hashtags,
                                category: _post!.category,
                                type: _post!.type,
                                isArchived: false,
                                commentsDisabled: _post!.commentsDisabled,
                              );
                            });
                          }
                        }
                      } else {
                        await viewModel.archivePost(
                          postId: _post!.id,
                          userId: _post!.userId,
                          archive: true,
                          context: context,
                        );
                        if (_isMounted) {
                          if (viewModel.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(viewModel.errorMessage!)),
                            );
                            viewModel.clearError();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post archived')),
                            );
                            setState(() {
                              _post = PostModel(
                                id: _post!.id,
                                userId: _post!.userId,
                                username: _post!.username,
                                userProfilePic: _post!.userProfilePic,
                                imageUrl: _post!.imageUrl,
                                videoUrl: _post!.videoUrl,
                                thumbnailUrl: _post!.thumbnailUrl,
                                caption: _post!.caption,
                                timestamp: _post!.timestamp,
                                hashtags: _post!.hashtags,
                                category: _post!.category,
                                type: _post!.type,
                                isArchived: true,
                                commentsDisabled: _post!.commentsDisabled,
                              );
                            });
                          }
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
                      if (confirm == true && _isMounted) {
                        await viewModel.deletePost(
                          postId: _post!.id,
                          userId: _post!.userId,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post deleted')),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF8A56AC)),
                    title: const Text('Edit Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_isMounted) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditPostScreen(post: _post!),
                          ),
                        );
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post updated')),
                          );
                          await _fetchPost();
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.comment, color: Color(0xFF8A56AC)),
                    title: Text(_post!.commentsDisabled ? 'Enable Comments' : 'Disable Comments'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_isMounted) {
                        await viewModel.disableComments(
                          postId: _post!.id,
                          userId: _post!.userId,
                          disable: !_post!.commentsDisabled,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_post!.commentsDisabled ? 'Comments enabled' : 'Comments disabled'),
                            ),
                          );
                          setState(() {
                            _post = PostModel(
                              id: _post!.id,
                              userId: _post!.userId,
                              username: _post!.username,
                              userProfilePic: _post!.userProfilePic,
                              imageUrl: _post!.imageUrl,
                              videoUrl: _post!.videoUrl,
                              thumbnailUrl: _post!.thumbnailUrl,
                              caption: _post!.caption,
                              timestamp: _post!.timestamp,
                              hashtags: _post!.hashtags,
                              category: _post!.category,
                              type: _post!.type,
                              isArchived: _post!.isArchived,
                              commentsDisabled: !_post!.commentsDisabled,
                            );
                          });
                        }
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
                      if (_isMounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feature coming soon!')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.thumb_down, color: Color(0xFF8A56AC)),
                    title: const Text('Not Interested'),
                    onTap: () {
                      Navigator.pop(context);
                      if (_isMounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feature coming soon!')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.red),
                    title: const Text('Report'),
                    onTap: () {
                      Navigator.pop(context);
                      if (_isMounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feature coming soon!')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      viewModel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: Color(0xFF8A56AC),
                    ),
                    title: Text(isSavedScreen ? 'Unsave Post' : (viewModel.isSaved ? 'Unsave Post' : 'Save Post')),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_isMounted && currentUserId != null) {
                        if (isSavedScreen || viewModel.isSaved) {
                          await viewModel.unsavePost(
                            postId: _post!.id,
                            userId: currentUserId,
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
                            if (isSavedScreen) {
                              await viewModel.fetchSavedPosts(currentUserId);
                            }
                          }
                        } else {
                          await viewModel.savePost(
                            postId: _post!.id,
                            postOwnerId: _post!.userId,
                            userId: currentUserId,
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Post")),
        body: const Center(child: Text("Post not found or deleted.")),
      );
    }

    final post = _post!;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = post.userId == currentUserId;

    return ChangeNotifierProvider(
      create: (_) => PostViewModel()..fetchInteractionData('${post.userId}/posts/${post.id}'),
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () {
              if (_isMounted && post.userId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.userId)),
                );
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: post.userProfilePic.isNotEmpty
                      ? NetworkImage(post.userProfilePic)
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                const SizedBox(width: 8),
                Text(post.username.isNotEmpty ? post.username : 'Unknown'),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPostMenu(context, isOwner),
            ),
          ],
        ),
        body: Consumer<PostViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isMounted && post.type == 'video') {
                        setState(() {
                          _showVideo = !_showVideo;
                        });
                      }
                    },
                    child: post.type == 'video' && post.videoUrl.isNotEmpty
                        ? VideoPostCard(post: post, isThumbnailOnly: !_showVideo)
                        : post.imageUrl.isNotEmpty
                        ? Image.network(
                      post.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox(
                          height: 200,
                          child: Center(child: Icon(Icons.broken_image)),
                        );
                      },
                    )
                        : const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${post.username}: ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: post.caption,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            viewModel.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () => viewModel.toggleLike(post.id, post.userId),
                        ),
                        Text('${viewModel.likeCount}'),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.comment),
                          onPressed: post.commentsDisabled
                              ? null
                              : () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.6,
                                minChildSize: 0.4,
                                maxChildSize: 0.95,
                                expand: false,
                                builder: (context, scrollController) {
                                  return CommentSectionSheet(
                                    postId: post.id,
                                    postOwnerId: post.userId,
                                    scrollController: scrollController,
                                    post: post,
                                  );
                                },
                              ),
                            );
                            await viewModel.fetchInteractionData('${post.userId}/posts/${post.id}');
                          },
                        ),
                        Text('${viewModel.commentCount}'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () async {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (context) => DraggableScrollableSheet(
                                initialChildSize: 0.6,
                                minChildSize: 0.4,
                                maxChildSize: 0.95,
                                expand: false,
                                builder: (context, scrollController) {
                                  return PostShareScreen(
                                    post: post,
                                    scrollController: scrollController,
                                  );
                                },
                              ),
                            );
                            await viewModel.fetchInteractionData('${post.userId}/posts/${post.id}');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}