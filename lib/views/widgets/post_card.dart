//views/widgets/post_card.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/viewmodels/post_interaction_viewmodel.dart';
import 'package:the_shot2/viewmodels/saved_post_viewmodel.dart';
import 'package:the_shot2/views/comment_section_screen.dart';
import 'package:the_shot2/views/edit_post_screen.dart';
import 'package:the_shot2/views/post_share_screen.dart';
import 'package:the_shot2/views/profile_screen.dart';
import 'package:the_shot2/views/user_profile_screen.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';
import 'package:the_shot2/views/widgets/post_menu_widget.dart';
import 'package:the_shot2/views/post_detail_screen.dart';

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
        Provider.of<PostInteractionViewModel>(context, listen: false)
            .fetchInteractionData('${widget.post.userId}/posts/${widget.post.id}');
        Provider.of<SavedPostsViewModel>(context, listen: false)
            .checkIfPostIsSaved(widget.post.id, FirebaseAuth.instance.currentUser?.uid ?? '');
      }
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = widget.post.userId == currentUserId;

    return Consumer2<PostInteractionViewModel, SavedPostsViewModel>(
      builder: (context, interactionViewModel, savedPostsViewModel, child) {
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
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => PostMenuWidget(
                            post: widget.post,
                            isArchivedScreen: ModalRoute.of(context)?.settings.name == '/archived_posts',
                            isSavedScreen: ModalRoute.of(context)?.settings.name == '/saved_posts',
                          ),
                        );
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
                } else if (_isMounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: widget.post),
                    ),
                  );
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
                      interactionViewModel.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      if (_isMounted) {
                        await interactionViewModel.toggleLike(widget.post.id, widget.post.userId);
                      }
                    },
                  ),
                  Text('${interactionViewModel.likeCount}'),
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
                            await interactionViewModel
                                .fetchInteractionData('${widget.post.userId}/posts/${widget.post.id}');
                          }
                        }
                      },
                    ),
                  ),
                  Text('${interactionViewModel.commentCount}'),
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
                          await interactionViewModel
                              .fetchInteractionData('${widget.post.userId}/posts/${widget.post.id}');
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
    );
  }
}