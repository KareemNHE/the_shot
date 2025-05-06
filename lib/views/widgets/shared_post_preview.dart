//views/widgets/shared_post_preview.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../models/post_model.dart';
import '../post_detail_screen.dart';

class SharedPostPreview extends StatelessWidget {
  final MessageModel message;

  const SharedPostPreview({required this.message});


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
