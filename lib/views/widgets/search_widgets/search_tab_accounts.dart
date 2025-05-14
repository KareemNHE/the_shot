//views/widgets/search_widgets/search_tab_accounts.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/search_viewmodel.dart';
import 'package:the_shot2/views/user_profile_screen.dart';

class SearchTabAccounts extends StatelessWidget {
  const SearchTabAccounts({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isRefreshing) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = viewModel.filteredUsers;

        if (users.isEmpty) {
          return const Center(child: Text('No accounts found'));
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
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: user.profilePicture.isNotEmpty
                      ? (user.profilePicture.startsWith('http')
                      ? NetworkImage(user.profilePicture)
                      : AssetImage(user.profilePicture) as ImageProvider)
                      : const AssetImage('assets/default_profile.png'),
                ),
                title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.firstName} ${user.lastName}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: user.id),
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