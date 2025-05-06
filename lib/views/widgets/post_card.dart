//views/widgets/post_card.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/viewmodels/post_viewmodel.dart';
import 'package:the_shot2/views/comment_section_screen.dart';
import 'package:the_shot2/views/edit_post_screen.dart';
import 'package:the_shot2/views/post_share_screen.dart';
import 'package:the_shot2/views/profile_screen.dart';
import 'package:the_shot2/views/user_profile_screen.dart';
import 'video_post_card.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({Key? key, required this.post}) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showVideo = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        Provider.of<PostViewModel>(context, listen: false)
            .fetchInteractionData('${widget.post.userId}/posts/${widget.post.id}');
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

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
                      if (confirm == true && _isMounted) {
                        await viewModel.deletePost(
                          postId: widget.post.id,
                          userId: widget.post.userId,
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
                          await viewModel.fetchArchivedPosts(widget.post.userId);
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.unarchive, color: Color(0xFF8A56AC)),
                    title: const Text('Show back on profile'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_isMounted) {
                        await viewModel.unarchivePost(
                          postId: widget.post.id,
                          userId: widget.post.userId,
                          context: context,
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
                          await viewModel.fetchArchivedPosts(widget.post.userId);
                        }
                      }
                    },
                  ),
                ]
                    : [
                  ListTile(
                    leading: const Icon(Icons.archive, color: Color(0xFF8A56AC)),
                    title: Text(widget.post.isArchived ? 'Unarchive Post' : 'Archive Post'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_isMounted) {
                        if (widget.post.isArchived) {
                          await viewModel.unarchivePost(
                            postId: widget.post.id,
                            userId: widget.post.userId,
                            context: context,
                          );
                        } else {
                          await viewModel.archivePost(
                            postId: widget.post.id,
                            userId: widget.post.userId,
                            archive: true,
                            context: context,
                          );
                        }
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.post.isArchived ? 'Post unarchived' : 'Post archived'),
                            ),
                          );
                          if (!widget.post.isArchived) {
                            await viewModel.fetchUserPosts(widget.post.userId);
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
                          postId: widget.post.id,
                          userId: widget.post.userId,
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
                          await viewModel.fetchUserPosts(widget.post.userId);
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
                            builder: (_) => EditPostScreen(post: widget.post),
                          ),
                        );
                        if (result == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post updated')),
                          );
                          await viewModel.fetchUserPosts(widget.post.userId);
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.comment, color: Color(0xFF8A56AC)),
                    title: Text(widget.post.commentsDisabled ? 'Enable Comments' : 'Disable Comments'),
                    onTap: () async {
                      Navigator.pop(context);
                      if (_isMounted) {
                        await viewModel.disableComments(
                          postId: widget.post.id,
                          userId: widget.post.userId,
                          disable: !widget.post.commentsDisabled,
                        );
                        if (viewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.post.commentsDisabled ? 'Comments enabled' : 'Comments disabled'),
                            ),
                          );
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
                      if (_isMounted) {
                        if (isSavedScreen) {
                          await viewModel.unsavePost(
                            postId: widget.post.id,
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
                            postId: widget.post.id,
                            postOwnerId: widget.post.userId,
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
    final isOwner = widget.post.userId == currentUserId;

    return ChangeNotifierProvider<PostViewModel>(
      create: (_) => PostViewModel(),
      child: Consumer<PostViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isMounted) {
                          if (isOwner) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.post.userId)),
                            );
                          }
                        }
                      },
                      child: CircleAvatar(
                        backgroundImage: widget.post.userProfilePic.isNotEmpty
                            ? NetworkImage(widget.post.userProfilePic)
                            : const AssetImage('assets/default_profile.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        if (_isMounted) {
                          if (isOwner) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.post.userId)),
                            );
                          }
                        }
                      },
                      child: Text(
                        widget.post.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        if (_isMounted) {
                          _showPostMenu(context, isOwner);
                        }
                      },
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_isMounted && widget.post.type == 'video') {
                    setState(() {
                      _showVideo = !_showVideo;
                    });
                  }
                },
                child: widget.post.type == 'video' && widget.post.videoUrl.isNotEmpty
                    ? VideoPostCard(post: widget.post, isThumbnailOnly: !_showVideo, showMenuIcon: false)
                    : widget.post.imageUrl.isNotEmpty
                    ? Image.network(
                  widget.post.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
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
                        text: '${widget.post.username}: ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.post.caption,
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
                      onPressed: () async {
                        if (_isMounted) {
                          await viewModel.toggleLike(widget.post.id, widget.post.userId);
                        }
                      },
                    ),
                    Text('${viewModel.likeCount}'),
                    const SizedBox(width: 16),
                    Tooltip(
                      message: widget.post.commentsDisabled ? 'Comments are disabled' : 'View comments',
                      child: IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: widget.post.commentsDisabled
                            ? null
                            : () async {
                          if (_isMounted) {
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
                                    postId: widget.post.id,
                                    postOwnerId: widget.post.userId,
                                    scrollController: scrollController,
                                    post: widget.post,
                                  );
                                },
                              ),
                            );
                            if (_isMounted) {
                              await viewModel.fetchInteractionData('${widget.post.userId}/posts/${widget.post.id}');
                            }
                          }
                        },
                      ),
                    ),
                    Text('${viewModel.commentCount}'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () async {
                        if (_isMounted) {
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
                                  post: widget.post,
                                  scrollController: scrollController,
                                );
                              },
                            ),
                          );
                          if (_isMounted) {
                            await viewModel.fetchInteractionData('${widget.post.userId}/posts/${widget.post.id}');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}
