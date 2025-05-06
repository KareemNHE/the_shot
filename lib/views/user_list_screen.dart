// views/user_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_list_viewmodel.dart';

class UserListScreen extends StatelessWidget {
  final String title;
  final List<String> userIds;

  const UserListScreen({required this.title, required this.userIds, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserListViewModel()..fetchUsersFromIds(userIds),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Consumer<UserListViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              itemCount: viewModel.users.length,
              itemBuilder: (context, index) {
                final user = viewModel.users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profile_picture.startsWith('http')
                        ? NetworkImage(user.profile_picture)
                        : AssetImage(user.profile_picture) as ImageProvider,
                  ),
                  title: Text(user.username),
                  subtitle: Text('${user.first_name} ${user.last_name}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
