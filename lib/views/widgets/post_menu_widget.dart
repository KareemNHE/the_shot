//views/widgets/post_menu_widget.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../viewmodels/archived_post_viewmodel.dart';
import '../../viewmodels/post_actions_viewmodel.dart';
import '../../viewmodels/saved_post_viewmodel.dart';
import '../../viewmodels/user_post_viewmodel.dart';
import '../edit_post_screen.dart';

class PostMenuWidget extends StatelessWidget {
  final PostModel post;
  final bool isArchivedScreen;
  final bool isSavedScreen;

  const PostMenuWidget({
    Key? key,
    required this.post,
    this.isArchivedScreen = false,
    this.isSavedScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = post.userId == currentUserId;
    final postActionsViewModel = Provider.of<PostActionsViewModel>(context, listen: false);
    final savedPostsViewModel = Provider.of<SavedPostsViewModel>(context, listen: false);

    return DraggableScrollableSheet(
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
                      await postActionsViewModel.deletePost(
                        postId: post.id,
                        userId: post.userId,
                      );
                      if (postActionsViewModel.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(postActionsViewModel.errorMessage!)),
                        );
                        postActionsViewModel.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post deleted')),
                        );
                        await Provider.of<ArchivedPostsViewModel>(context, listen: false)
                            .fetchArchivedPosts(post.userId);
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.unarchive, color: Color(0xFF8A56AC)),
                  title: const Text('Show back on profile'),
                  onTap: () async {
                    Navigator.pop(context);
                    await postActionsViewModel.unarchivePost(
                      postId: post.id,
                      userId: post.userId,
                      context: context,
                    );
                    if (postActionsViewModel.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(postActionsViewModel.errorMessage!)),
                      );
                      postActionsViewModel.clearError();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post unarchived')),
                      );
                      await Provider.of<ArchivedPostsViewModel>(context, listen: false)
                          .fetchArchivedPosts(post.userId);
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
                    if (post.isArchived) {
                      await postActionsViewModel.unarchivePost(
                        postId: post.id,
                        userId: post.userId,
                        context: context,
                      );
                    } else {
                      await postActionsViewModel.archivePost(
                        postId: post.id,
                        userId: post.userId,
                        archive: true,
                        context: context,
                      );
                    }
                    if (postActionsViewModel.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(postActionsViewModel.errorMessage!)),
                      );
                      postActionsViewModel.clearError();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(post.isArchived ? 'Post unarchived' : 'Post archived'),
                        ),
                      );
                      if (!post.isArchived) {
                        await Provider.of<UserPostsViewModel>(context, listen: false)
                            .fetchUserPosts(post.userId);
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
                      await postActionsViewModel.deletePost(
                        postId: post.id,
                        userId: post.userId,
                      );
                      if (postActionsViewModel.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(postActionsViewModel.errorMessage!)),
                        );
                        postActionsViewModel.clearError();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post deleted')),
                        );
                        await Provider.of<UserPostsViewModel>(context, listen: false)
                            .fetchUserPosts(post.userId);
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
                      await Provider.of<UserPostsViewModel>(context, listen: false)
                          .fetchUserPosts(post.userId);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.comment, color: Color(0xFF8A56AC)),
                  title: Text(post.commentsDisabled ? 'Enable Comments' : 'Disable Comments'),
                  onTap: () async {
                    Navigator.pop(context);
                    await postActionsViewModel.disableComments(
                      postId: post.id,
                      userId: post.userId,
                      disable: !post.commentsDisabled,
                    );
                    if (postActionsViewModel.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(postActionsViewModel.errorMessage!)),
                      );
                      postActionsViewModel.clearError();
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
                  leading: Icon(
                    savedPostsViewModel.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Color(0xFF8A56AC),
                  ),
                  title: Text(isSavedScreen ? 'Unsave Post' : (savedPostsViewModel.isSaved ? 'Unsave Post' : 'Save Post')),
                  onTap: () async {
                    Navigator.pop(context);
                    if (currentUserId != null) {
                      if (isSavedScreen || savedPostsViewModel.isSaved) {
                        await savedPostsViewModel.unsavePost(
                          postId: post.id,
                          userId: currentUserId,
                        );
                        if (savedPostsViewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(savedPostsViewModel.errorMessage!)),
                          );
                          savedPostsViewModel.clearError();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Post unsaved')),
                          );
                          if (isSavedScreen) {
                            await savedPostsViewModel.fetchSavedPosts(currentUserId);
                          }
                        }
                      } else {
                        await savedPostsViewModel.savePost(
                          postId: post.id,
                          postOwnerId: post.userId,
                          userId: currentUserId,
                        );
                        if (savedPostsViewModel.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(savedPostsViewModel.errorMessage!)),
                          );
                          savedPostsViewModel.clearError();
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
    );
  }
}