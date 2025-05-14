//views/widgets/search_widgets/search_tab_hashtags.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/search_viewmodel.dart';
import '../../hashtag_feed_screen.dart';

class SearchTabHashtags extends StatelessWidget {
  const SearchTabHashtags({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isRefreshing) {
          return const Center(child: CircularProgressIndicator());
        }

        final hashtags = viewModel.filteredHashtagPosts
            .expand((post) => post.hashtags)
            .toSet()
            .toList();

        if (hashtags.isEmpty) {
          return const Center(child: Text('No hashtags found'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.fetchAllUserPosts(isRefresh: true);
            viewModel.search(Provider.of<TextEditingController>(context, listen: false).text);
          },
          color: const Color(0xFF8A56AC),
          backgroundColor: Colors.white,
          displacement: 40.0,
          child: ListView.builder(
            itemCount: hashtags.length,
            itemBuilder: (context, index) {
              final hashtag = hashtags[index];
              return ListTile(
                title: Text(hashtag),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HashtagFeedScreen(hashtag: hashtag),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}