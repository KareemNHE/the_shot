import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/viewmodels/post_viewmodel.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        Provider.of<PostViewModel>(context, listen: false).fetchSavedPosts(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Posts'),
      ),
      body: Consumer<PostViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          }
          if (viewModel.savedPosts.isEmpty) {
            return const Center(child: Text('No saved posts'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await viewModel.fetchSavedPosts(userId);
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 1,
              ),
              itemCount: viewModel.savedPosts.length,
              itemBuilder: (context, index) {
                final post = viewModel.savedPosts[index];
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
                    child: post.type == 'video' && post.videoUrl.isNotEmpty
                        ? VideoPostCard(
                      post: post,
                      isThumbnailOnly: true,
                      isGridView: true,
                    )
                        : post.imageUrl.isNotEmpty
                        ? Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                    )
                        : const SizedBox(
                      height: 200,
                      child: Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}