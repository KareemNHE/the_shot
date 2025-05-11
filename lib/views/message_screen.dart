// views/messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/message_list_viewmodel.dart';
import '../views/chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays >= 1) return '${diff.inDays}d';
    if (diff.inHours >= 1) return '${diff.inHours}h';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageListViewModel()..loadChats(),
      child: Consumer<MessageListViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Messages'),
              backgroundColor: Colors.grey[100],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: viewModel.searchUsers,
                  ),
                ),
                if (viewModel.isSearching)
                  Expanded(
                    child: ListView.builder(
                      itemCount: viewModel.searchedUsers.length,
                      itemBuilder: (context, index) {
                        final user = viewModel.searchedUsers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(user.profile_picture),
                          ),
                          title: Text(user.username),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: user.id,
                                  otherUsername: user.username,
                                  otherUserProfilePic: user.profile_picture,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: viewModel.recentChats.length,
                      itemBuilder: (context, index) {
                        final chat = viewModel.recentChats[index];
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(chat.receiverProfilePic),
                                radius: 24,
                              ),
                              if (chat.isUnread)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            chat.receiverUsername,
                            style: TextStyle(
                              fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            chat.lastMessage == null || chat.lastMessage!.isEmpty
                                ? 'New message'
                                : chat.isLastMessageFromMe
                                ? 'Sent ${_timeAgo(chat.timestamp!)}'
                                : 'Received ${_timeAgo(chat.timestamp!)}',
                            style: TextStyle(
                              fontWeight: chat.isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUserId: chat.receiverId,
                                  otherUsername: chat.receiverUsername,
                                  otherUserProfilePic: chat.receiverProfilePic,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
