//views/widgets/comment_tile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/theme.dart';
import '../../models/comment_model.dart';
import '../../viewmodels/comment_interaction_viewmodel.dart';
import '../user_profile_screen.dart';

class CommentTile extends StatefulWidget {
  final CommentModel comment;
  final String postId;
  final String postOwnerId;
  final bool isHighlighted;

  const CommentTile({
    Key? key,
    required this.comment,
    required this.postId,
    required this.postOwnerId,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> with SingleTickerProviderStateMixin {
  AnimationController? _blinkController;
  Animation<double>? _blinkAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.isHighlighted) {
      _blinkController = AnimationController(
        duration: const Duration(milliseconds: 250),
        vsync: this,
      );
      _blinkAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(_blinkController!)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _blinkController!.reverse();
          } else if (status == AnimationStatus.dismissed) {
            if (_blinkController!.value == 0.0 && _blinkController!.status == AnimationStatus.dismissed) {
              _blinkController!.forward();
            }
          }
        });

      // Run animation twice (4 cycles: show, hide, show, hide)
      _blinkController!.forward().then((_) {
        _blinkController!.forward().then((_) {
          _blinkController!.stop();
          _blinkController!.dispose();
          _blinkController = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _blinkController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentInteractionViewModel(
        postId: widget.postId,
        commentId: widget.comment.id,
        postOwnerId: widget.postOwnerId,
      ),
      child: Consumer<CommentInteractionViewModel>(
        builder: (context, commentViewModel, _) {
          return Container(
            decoration: BoxDecoration(
              border: widget.isHighlighted && _blinkController != null
                  ? Border.all(
                color: kPrimaryAccent.withOpacity(_blinkAnimation?.value ?? 3.0),
                width: 2,
              )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: widget.comment.userProfilePic.isNotEmpty
                    ? NetworkImage(widget.comment.userProfilePic)
                    : const AssetImage('assets/default_profile.png') as ImageProvider,
              ),
              title: Text(widget.comment.username),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommentText(context, widget.comment.text, widget.comment.mentions),
                  Row(
                    children: [
                      Text(
                        TimeOfDay.fromDateTime(widget.comment.timestamp).format(context),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => commentViewModel.toggleLike(),
                        child: Icon(
                          commentViewModel.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${commentViewModel.likeCount}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentText(BuildContext context, String text, List<String> mentions) {
    final spans = <TextSpan>[];
    final mentionRegex = RegExp(r'@(\w+)');

    int lastIndex = 0;
    for (final match in mentionRegex.allMatches(text)) {
      final beforeMention = text.substring(lastIndex, match.start);
      final mentionText = match.group(0)!;
      final username = match.group(1)!;

      if (beforeMention.isNotEmpty) {
        spans.add(TextSpan(text: beforeMention));
      }

      spans.add(
        TextSpan(
          text: mentionText,
          style: TextStyle(color: kPrimaryAccent, fontWeight: FontWeight.bold),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              if (mentions.contains(username)) {
                final userSnapshot = await FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isEqualTo: username)
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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not found')),
                  );
                }
              }
            },
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}