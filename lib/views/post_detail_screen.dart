// views/post_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/theme.dart';
import '../models/post_model.dart';
import '../viewmodels/post_interaction_viewmodel.dart';
import '../viewmodels/post_detail_viewmodel.dart';
import '../viewmodels/saved_post_viewmodel.dart';
import '../views/comment_section_screen.dart';
import '../views/post_share_screen.dart';
import '../views/user_profile_screen.dart';
import '../views/widgets/video_post_card.dart';
import '../views/widgets/post_menu_widget.dart';
import 'category_feed_screen.dart';
import 'hashtag_feed_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel? post;
  final String? postId;
  final String? postOwnerId;
  final String? highlightCommentId;

  const PostDetailScreen({
    Key? key,
    this.post,
    this.postId,
    this.postOwnerId,
    this.highlightCommentId,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _showVideo = false;
  bool _isMounted = false;
  final ScrollController _commentScrollController = ScrollController();

  List<TextSpan> _buildCaptionTextSpans(BuildContext context, PostModel post) {
    final spans = <TextSpan>[];
    final words = post.caption.split(' ');

    spans.add(
      TextSpan(
        text: '${post.username}: ',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );

    for (var word in words) {
      if (word.startsWith('#')) {
        spans.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(
              fontSize: 16,
              color: kPrimaryAccent,
              fontWeight: FontWeight.normal,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HashtagFeedScreen(hashtag: word),
                  ),
                );
              },
          ),
        );
      } else if (word.startsWith('@')) {
        spans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(
              fontSize: 16,
              color: kPrimaryAccent,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final userSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isEqualTo: word.substring(1))
                    .limit(1)
                    .get();
                if (userSnapshot.docs.isNotEmpty) {
                  final userId = userSnapshot.docs.first.id;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: userId),
                    ),
                  );
                }
              },
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$word ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
    }

    return spans;
  }

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        final postDetailViewModel =
        Provider.of<PostDetailViewModel>(context, listen: false);
        final savedPostsViewModel =
        Provider.of<SavedPostsViewModel>(context, listen: false);
        if (widget.post != null) {
          postDetailViewModel.setPost(widget.post!);
        } else if (widget.postId != null && widget.postOwnerId != null) {
          postDetailViewModel.fetchPost(widget.postId!, widget.postOwnerId!);
        }
        savedPostsViewModel.checkIfPostIsSaved(
          widget.post?.id ?? widget.postId ?? '',
          FirebaseAuth.instance.currentUser?.uid ?? '',
        );
        if (widget.highlightCommentId != null) {
          _openCommentSection();
        }
      }
    });
  }

  void _openCommentSection() async {
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
            postId: widget.post?.id ?? widget.postId!,
            postOwnerId: widget.post?.userId ?? widget.postOwnerId!,
            scrollController: _commentScrollController,
            post: widget.post ??
                PostModel(
                  id: widget.postId!,
                  userId: widget.postOwnerId!,
                  username: '',
                  userProfilePic: '',
                  imageUrl: '',
                  videoUrl: '',
                  thumbnailUrl: '',
                  caption: '',
                  timestamp: DateTime.now(),
                  hashtags: [],
                  mentions: [],
                  category: 'Uncategorized',
                  type: 'image',
                ),
            highlightCommentId: widget.highlightCommentId,
          );
        },
      ),
    );
    if (_isMounted) {
      Provider.of<PostInteractionViewModel>(context, listen: false)
          .fetchInteractionData(
          '${widget.post?.userId ?? widget.postOwnerId}/posts/${widget.post?.id ?? widget.postId}');
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _commentScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PostDetailViewModel, PostInteractionViewModel>(
      builder: (context, postDetailViewModel, interactionViewModel, child) {
        if (postDetailViewModel.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (postDetailViewModel.post == null ||
            postDetailViewModel.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Post")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    postDetailViewModel.errorMessage ?? "Post not found or deleted.",
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (widget.postId != null && widget.postOwnerId != null) {
                        postDetailViewModel.fetchPost(
                            widget.postId!, widget.postOwnerId!);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final post = postDetailViewModel.post!;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isOwner = post.userId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                if (_isMounted && post.userId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: post.userId)),
                  );
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: post.userProfilePic.isNotEmpty
                        ? NetworkImage(post.userProfilePic)
                        : const AssetImage('assets/default_profile.png')
                    as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Text(post.username.isNotEmpty ? post.username : 'Unknown'),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => PostMenuWidget(
                    post: post,
                    isSavedScreen:
                    ModalRoute.of(context)?.settings.name == '/saved_posts',
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: _buildCaptionTextSpans(context, post),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (post.category != 'Uncategorized')
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CategoryFeedScreen(category: post.category),
                              ),
                            );
                          },
                          child: Chip(
                            label: Text(
                              post.category,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: kPrimaryAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            labelPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          interactionViewModel.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () => interactionViewModel.toggleLike(
                            post.id, post.userId),
                      ),
                      Text('${interactionViewModel.likeCount}'),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: post.commentsDisabled
                            ? null
                            : () => _openCommentSection(),
                      ),
                      Text('${interactionViewModel.commentCount}'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
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
                          await interactionViewModel.fetchInteractionData(
                              '${post.userId}/posts/${post.id}');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}