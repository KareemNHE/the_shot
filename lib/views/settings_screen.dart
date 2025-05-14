//views/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/settings_viewmodel.dart';
import 'package:the_shot2/views/archived_post_screen.dart';
import 'package:the_shot2/views/blocked_users_screen.dart';
import 'package:the_shot2/views/widgets/settings_item.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(viewModel.errorMessage!),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: viewModel.clearError,
                  ),
                ),
              );
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SettingsItem(
                  icon: Icons.lock,
                  title: 'Private Profile',
                  trailing: Switch(
                    value: viewModel.isPrivate,
                    onChanged: (value) => viewModel.toggleProfileVisibility(value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.archive,
                  title: 'Archived Posts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArchivedPostsScreen(),
                      ),
                    );
                  },
                ),
                SettingsItem(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlockedUsersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Text(
                  'Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SettingsItem(
                  icon: Icons.brightness_6,
                  title: 'Theme',
                  trailing: DropdownButton<String>(
                    value: viewModel.themePreference,
                    items: const [
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      if (value != null) viewModel.toggleTheme(value);
                    },
                  ),
                ),
                SettingsItem(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: DropdownButton<String>(
                    value: viewModel.language,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                    ],
                    onChanged: (value) {
                      if (value != null) viewModel.setLanguage(value);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SettingsItem(
                  icon: Icons.favorite,
                  title: 'Likes',
                  trailing: Switch(
                    value: viewModel.notificationSettings['likes'] ?? true,
                    onChanged: (value) => viewModel.toggleNotificationSetting('likes', value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.comment,
                  title: 'Comments',
                  trailing: Switch(
                    value: viewModel.notificationSettings['comments'] ?? true,
                    onChanged: (value) => viewModel.toggleNotificationSetting('comments', value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.person_add,
                  title: 'Follows',
                  trailing: Switch(
                    value: viewModel.notificationSettings['follows'] ?? true,
                    onChanged: (value) => viewModel.toggleNotificationSetting('follows', value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.message,
                  title: 'Messages',
                  trailing: Switch(
                    value: viewModel.notificationSettings['messages'] ?? true,
                    onChanged: (value) => viewModel.toggleNotificationSetting('messages', value),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Security',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SettingsItem(
                  icon: Icons.security,
                  title: 'Two-Factor Authentication',
                  trailing: Switch(
                    value: viewModel.twoFactorAuth,
                    onChanged: (value) => viewModel.toggleTwoFactorAuth(value),
                  ),
                ),
                SettingsItem(
                  icon: Icons.data_saver_off,
                  title: 'Data Saver',
                  trailing: Switch(
                    value: viewModel.dataSaver,
                    onChanged: (value) => viewModel.toggleDataSaver(value),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SettingsItem(
                  icon: Icons.delete_forever,
                  title: 'Delete Account',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Account'),
                        content: const Text('Are you sure? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await viewModel.deleteAccount();
                              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}