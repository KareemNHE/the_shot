//views/search_user_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/search_model.dart';
import 'package:the_shot2/viewmodels/search_viewmodel.dart';
import 'package:the_shot2/views/user_profile_screen.dart';

class SearchUserListScreen extends StatelessWidget {
  final String query;

  const SearchUserListScreen({Key? key, required this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();
    final users = viewModel.filteredUsers;

    return Scaffold(
      appBar: AppBar(
        title: Text('Users matching "$query"'),
      ),
      body: users.isEmpty
          ? const Center(child: Text('No users found'))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePicture.isNotEmpty
                  ? (user.profilePicture.startsWith('http')
                  ? NetworkImage(user.profilePicture)
                  : AssetImage(user.profilePicture) as ImageProvider)
                  : const AssetImage('assets/default_profile.png'),
            ),
            title: Text(user.username),
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
  }
}