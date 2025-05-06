//views/blocked_users_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/settings_viewmodel.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, _) {
          final blockedUsers = viewModel.blockedUsers;

          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (blockedUsers.isEmpty) {
            return const Center(child: Text('No blocked users.'));
          }

          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profile_picture.startsWith('http')
                      ? NetworkImage(user.profile_picture)
                      : AssetImage(user.profile_picture) as ImageProvider,
                ),
                title: Text(user.username),
                subtitle: Text('${user.first_name} ${user.last_name}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    await viewModel.unblockUser(user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unblocked @${user.username}')),
                    );
                  },
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}