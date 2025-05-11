//views/notification_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import 'widgets/notification_tile.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              Provider.of<NotificationViewModel>(context, listen: false).markAllAsRead();
            },
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = viewModel.notifications;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications available."));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationTile(
                notification: notification,
                onTap: () {
                  Provider.of<NotificationViewModel>(context, listen: false)
                      .markAsRead(notification.id);

                  if (['like', 'comment', 'tag'].contains(notification.type)) {
                    if (notification.relatedPostId != null && notification.postOwnerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(
                            postId: notification.relatedPostId,
                            postOwnerId: notification.postOwnerId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post not found.")),
                      );
                    }
                  } else if (notification.type == 'follow') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: notification.senderId),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
