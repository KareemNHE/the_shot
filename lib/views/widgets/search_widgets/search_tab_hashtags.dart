//views/widgets/search_widgets/search_tab_hashtags.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/search_viewmodel.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';

class SearchTabHashtags extends StatelessWidget {
  const SearchTabHashtags({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();
    final posts = viewModel.filteredHashtagPosts;

    if (posts.isEmpty) {
      return const Center(child: Text('No hashtag posts found'));
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.hardEdge,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(post: post),
                ),
              );
            },
            child: post.type == 'video'
                ? VideoPostCard(
              post: post,
              isThumbnailOnly: true,
              isGridView: true,
            )
                : Image.network(
              post.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image),
            ),
          ),
        );
      },
    );
  }
}