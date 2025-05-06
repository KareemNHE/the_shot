//views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/message_list_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import 'message_screen.dart';
import 'notification_screen.dart';
import 'widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: const TextStyle(color: Colors.black),
        title: Image.asset(
          'assets/text.png',
          height: 120,
        ),
        elevation: 0.0,
        actions: <Widget>[
          Consumer<NotificationViewModel>(
            builder: (context, notifViewModel, _) {
              final unread = notifViewModel.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Consumer<MessageListViewModel>(
            builder: (context, msgViewModel, _) {
              final unread = msgViewModel.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.messenger_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MessagesScreen()),
                      );
                    },
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, homeViewModel, child) {
          print('HomeScreen: isLoading=${homeViewModel.isLoading}, posts=${homeViewModel.posts.length}');
          if (homeViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (homeViewModel.posts.isEmpty) {
            return const Center(child: Text('No posts available. Try refreshing.'));
          }
          return RefreshIndicator(
            onRefresh: () => homeViewModel.fetchPosts(),
            child: ListView.builder(
              itemCount: homeViewModel.posts.length,
              itemBuilder: (context, index) {
                final post = homeViewModel.posts[index];
                print('Rendering post ${post.id}: isArchived=${post.isArchived}');
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}