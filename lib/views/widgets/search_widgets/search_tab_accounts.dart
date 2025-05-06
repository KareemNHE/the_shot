//views/widgets/search_widgets/search_tab_accounts.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/search_viewmodel.dart';
import 'package:the_shot2/views/user_profile_screen.dart';

class SearchTabAccounts extends StatelessWidget {
  const SearchTabAccounts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();
    final users = viewModel.filteredUsers;

    if (users.isEmpty) {
      return const Center(child: Text('No accounts found'));
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: user.id),
                  ),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.profile_picture.isNotEmpty
                        ? (user.profile_picture.startsWith('http')
                        ? NetworkImage(user.profile_picture)
                        : AssetImage(user.profile_picture) as ImageProvider)
                        : const AssetImage('assets/default_profile.png'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${user.first_name} ${user.last_name}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}