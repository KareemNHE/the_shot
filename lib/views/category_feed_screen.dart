//views/category_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import 'package:the_shot2/views/widgets/search_widgets/search_app_bar.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';
import '../../viewmodels/category_viewmodel.dart';
import '../../viewmodels/search_viewmodel.dart';
import '../../services/category_service.dart';

class CategoryFeedScreen extends StatefulWidget {
  final String category;

  const CategoryFeedScreen({Key? key, required this.category}) : super(key: key);

  @override
  _CategoryFeedScreenState createState() => _CategoryFeedScreenState();
}

class _CategoryFeedScreenState extends State<CategoryFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.category; // Pre-fill with category
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryViewModel(service: CategoryService(), category: widget.category),
      child: Scaffold(
        appBar: SearchAppBar(
          searchController: _searchController,
          showTabs: false, // No tabs for category feed
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
                widget.category,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8A56AC),
                ),
              ),
            ),
            Expanded(
              child: Consumer<CategoryViewModel>(
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
                            onPressed: () => viewModel.fetchPostsByCategory(widget.category),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (viewModel.posts.isEmpty) {
                    return const Center(child: Text('No posts found for this category'));
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