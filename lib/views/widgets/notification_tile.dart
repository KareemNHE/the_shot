//views/widgets/notification_tile.dart
import 'package:flutter/material.dart';
import 'package:the_shot2/models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      trailing: notification.isRead
          ? null
          : const Icon(Icons.circle, size: 10, color: Colors.red),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(notification.senderProfilePic),
      ),
      title: Text(_getNotificationText(notification)),
      subtitle: Text(_formatTime(notification.timestamp)),
      onTap: onTap,
    );
  }

  String _getNotificationText(AppNotification notification) {
    switch (notification.type) {
      case 'like':
        return '${notification.senderUsername} liked your post.';
      case 'comment':
        return '${notification.senderUsername} commented on your post.';
      case 'follow':
        return '${notification.senderUsername} followed you.';
      case 'tag':
        return '${notification.senderUsername} tagged you.';
      case 'follow_request':
        return '${notification.senderUsername} requested to follow you.';
      default:
        return 'You have a new notification.';
    }
  }

  String _formatTime(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inHours < 1) return '${duration.inMinutes}m ago';
    if (duration.inDays < 1) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}