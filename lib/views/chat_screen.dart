//views/chat_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import '../models/message_model.dart';
import '../models/post_model.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'package:the_shot2/views/widgets/shared_post_preview.dart';

class ChatScreen extends StatelessWidget {
  final String otherUserId;
  final String otherUsername;
  final String otherUserProfilePic;

  const ChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherUserProfilePic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(otherUserId: otherUserId),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: otherUserProfilePic.isNotEmpty
                    ? NetworkImage(otherUserProfilePic)
                    : const AssetImage('assets/default_profile.png') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Text(otherUsername),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatViewModel>(
                builder: (context, viewModel, _) {
                  if (viewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (viewModel.messages.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }
                  return ListView.builder(
                    reverse: true,
                    itemCount: viewModel.messages.length,
                    itemBuilder: (context, index) {
                      final message = viewModel.messages[index];
                      final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.purple[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: message.sharedPostId != null
                              ? SharedPostPreview(message: message)
                              : Text(message.text),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _MessageInputField(otherUserId: otherUserId),
          ],
        ),
      ),
    );
  }
}

class _MessageInputField extends StatefulWidget {
  final String otherUserId;
  const _MessageInputField({required this.otherUserId});

  @override
  State<_MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<_MessageInputField> {
  final _controller = TextEditingController();
  final listScrollController = ScrollController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    Provider.of<ChatViewModel>(context, listen: false).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedPostPreview extends StatelessWidget {
  final MessageModel message;

  const _SharedPostPreview({required this.message});


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to full post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(
              post: PostModel(
                id: message.sharedPostId!,
                userId: message.senderId,
                username: message.sharedPostOwnerUsername ?? '',
                userProfilePic: message.sharedPostOwnerProfilePic ?? '',
                imageUrl: message.sharedPostThumbnail ?? '',
                videoUrl: '',
                thumbnailUrl: '',
                caption: message.sharedPostCaption ?? '',
                timestamp: message.timestamp,
                hashtags: [],
                mentions: [],
                category: 'Uncategorized',
                type: 'image',
              ),

            ),
          ),
        );
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white70,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: message.sharedPostOwnerProfilePic != null
                      ? NetworkImage(message.sharedPostOwnerProfilePic!)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(message.sharedPostOwnerUsername ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            if (message.sharedPostThumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.sharedPostThumbnail!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 6),
            if ((message.sharedPostCaption ?? '').isNotEmpty)
              Text(
                message.sharedPostCaption!.length > 60
                    ? '${message.sharedPostCaption!.substring(0, 60)}...'
                    : message.sharedPostCaption!,
                style: const TextStyle(color: Colors.black87),
              ),
          ],
        ),
      ),
    );
  }
}
