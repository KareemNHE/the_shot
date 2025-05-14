// views/comment_section_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../viewmodels/comment_viewmodel.dart';
import 'widgets/comment_tile.dart';

class CommentSection extends StatelessWidget {
  final String postId;
  final String postOwnerId;
  final PostModel post;
  final String? highlightCommentId;

  const CommentSection({
    Key? key,
    required this.postId,
    required this.postOwnerId,
    required this.post,
    this.highlightCommentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentViewModel(postId: postId, postOwnerId: postOwnerId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Comments')),
        body: Column(
          children: [
            Expanded(
              child: Consumer<CommentViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (viewModel.comments.isEmpty) {
                    return const Center(child: Text('No comments yet.'));
                  }

                  return ListView.builder(
                    itemCount: viewModel.comments.length,
                    itemBuilder: (context, index) {
                      final comment = viewModel.comments[index];
                      final isHighlighted = comment.id == highlightCommentId;
                      return CommentTile(
                        comment: comment,
                        postId: postId,
                        postOwnerId: postOwnerId,
                        isHighlighted: isHighlighted,
                      );
                    },
                  );
                },
              ),
            ),
            Consumer<CommentViewModel>(
              builder: (context, viewModel, _) {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final isOwner = currentUserId == postOwnerId;
                if (viewModel.errorMessage != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(viewModel.errorMessage!)),
                    );
                    viewModel.clearError();
                  });
                }
                if (post.commentsDisabled && !isOwner) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Comments are disabled for this post.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return _CommentInputField(postId: postId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentInputField extends StatefulWidget {
  final String postId;

  const _CommentInputField({required this.postId});

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  final TextEditingController _controller = TextEditingController();

  void _submitComment() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      await Provider.of<CommentViewModel>(context, listen: false).addComment(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _submitComment,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class CommentSectionSheet extends StatelessWidget {
  final String postId;
  final String postOwnerId;
  final ScrollController scrollController;
  final PostModel post;
  final String? highlightCommentId;

  const CommentSectionSheet({
    required this.postId,
    required this.postOwnerId,
    required this.scrollController,
    required this.post,
    this.highlightCommentId,
    Key? key,
  }) : super(key: key);

  Future<bool> _shouldHighlightComment(BuildContext context) async {
    if (highlightCommentId == null) return false;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final notificationQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('commentId', isEqualTo: highlightCommentId)
          .where('type', isEqualTo: 'mention')
          .limit(1)
          .get();

      if (notificationQuery.docs.isEmpty) return false;

      final notificationDoc = notificationQuery.docs.first;
      final data = notificationDoc.data();
      final highlightViewed = data['highlightViewed'] as bool? ?? false;

      if (!highlightViewed) {
        // Mark as viewed
        await notificationDoc.reference.update({'highlightViewed': true});
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking highlightViewed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentViewModel(postId: postId, postOwnerId: postOwnerId),
      child: Consumer<CommentViewModel>(
        builder: (context, viewModel, _) {
          return FutureBuilder<bool>(
            future: _shouldHighlightComment(context),
            builder: (context, snapshot) {
              final isHighlightedComment = snapshot.data ?? false;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (highlightCommentId != null && viewModel.comments.isNotEmpty) {
                  final index = viewModel.comments
                      .indexWhere((comment) => comment.id == highlightCommentId);
                  if (index != -1) {
                    scrollController.animateTo(
                      index * 80.0, // Approximate height of a comment tile
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              });

              return Column(
                children: [
                  Expanded(
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      controller: scrollController,
                      itemCount: viewModel.comments.length,
                      itemBuilder: (context, index) {
                        final comment = viewModel.comments[index];
                        final isHighlighted = isHighlightedComment && comment.id == highlightCommentId;
                        return CommentTile(
                          comment: comment,
                          postId: postId,
                          postOwnerId: postOwnerId,
                          isHighlighted: isHighlighted,
                        );
                      },
                    ),
                  ),
                  Consumer<CommentViewModel>(
                    builder: (context, viewModel, _) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      final isOwner = currentUserId == postOwnerId;
                      if (viewModel.errorMessage != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(viewModel.errorMessage!)),
                          );
                          viewModel.clearError();
                        });
                      }
                      if (post.commentsDisabled && !isOwner) {
                        return const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Comments are disabled for this post.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                      return _CommentInputField(postId: postId);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}