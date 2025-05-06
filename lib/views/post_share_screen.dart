//views/post_share_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../viewmodels/post_share_viewmodel.dart';

class PostShareScreen extends StatelessWidget {
  final PostModel post;
  final ScrollController scrollController;

  const PostShareScreen({
    Key? key,
    required this.post,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PostShareViewModel(post: post),
      child: Consumer<PostShareViewModel>(
        builder: (context, viewModel, _) {
          final users = viewModel.isSearching
              ? viewModel.searchedUsers
              : viewModel.recentUsers;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: viewModel.searchUsers,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isSelected =
                          viewModel.selectedUserIds.contains(user.id);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.profile_picture),
                        ),
                        title: Text(user.username),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => viewModel.toggleSelection(user.id),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await viewModel
                        .sendPostToSelectedUsers(context); // pass context
                    if (context.mounted) {
                      Navigator.pop(context); // close the modal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Post shared successfully!')),
                      );
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
