//views/hashtag_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_app_bar.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';
import '../../viewmodels/hashtag_viewmodel.dart';
import '../../services/hashtag_service.dart';

class HashtagFeedScreen extends StatefulWidget {
  final String hashtag;

  const HashtagFeedScreen({Key? key, required this.hashtag}) : super(key: key);

  @override
  _HashtagFeedScreenState createState() => _HashtagFeedScreenState();
}

class _HashtagFeedScreenState extends State<HashtagFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.hashtag; // Pre-fill with hashtag
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HashtagViewModel(service: HashtagService(), hashtag: widget.hashtag),
      child: Scaffold(
        appBar: SearchAppBar(
          searchController: _searchController,
          showTabs: false, // No tabs for hashtag feed
          onClear: () {
            Navigator.pop(context); // Navigate back to SearchScreen
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.hashtag,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8A56AC),
                ),
              ),
            ),
            Expanded(
              child: Consumer<HashtagViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (viewModel.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(viewModel.errorMessage!),
                          ElevatedButton(
                            onPressed: () => viewModel.fetchPostsByHashtag(widget.hashtag),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (viewModel.posts.isEmpty) {
                    return const Center(child: Text('No posts found for this hashtag'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                      childAspectRatio: 1,
                    ),
                    itemCount: viewModel.posts.length,
                    itemBuilder: (context, index) {
                      final post = viewModel.posts[index];
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
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}