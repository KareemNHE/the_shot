//views/user_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/services/settings_service.dart';
import 'package:the_shot2/viewmodels/settings_viewmodel.dart';
import 'package:the_shot2/views/post_detail_screen.dart';
import 'package:the_shot2/views/user_list_screen.dart';
import 'package:the_shot2/views/widgets/video_post_card.dart';
import '../viewmodels/user_profile_viewmodel.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileViewModel()..fetchUserProfile(userId)),
        ChangeNotifierProvider(create: (_) => SettingsViewModel(settingsService: SettingsService())),
      ],
      child: Consumer2<UserProfileViewModel, SettingsViewModel>(
        builder: (context, profileViewModel, settingsViewModel, child) {
          print('UserProfileScreen: isLoading=${profileViewModel.isLoading}, posts=${profileViewModel.posts.length}');
          if (profileViewModel.isLoading || settingsViewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = profileViewModel.user;
          final posts = profileViewModel.posts;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final isBlocked = settingsViewModel.blockedUsers.any((u) => u.id == userId);

          if (currentUserId != userId && isBlocked) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: const Center(child: Text('This user is blocked.')),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(user?.username ?? 'User'),
              actions: currentUserId != userId
                  ? [
                IconButton(
                  icon: const Icon(Icons.block),
                  onPressed: () async {
                    await settingsViewModel.unblockUser(userId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unblocked @${user?.username}')),
                    );
                  },
                ),
              ]
                  : null,
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await profileViewModel.fetchUserProfile(userId);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(user!.profile_picture),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.username,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('${user.first_name} ${user.last_name}'),
                    Text(user.bio, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final snapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.id)
                                .collection('followers')
                                .get();
                            final ids = snapshot.docs.map((doc) => doc.id).toList();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserListScreen(title: "Followers", userIds: ids),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text('${profileViewModel.followersCount}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Followers'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 30),
                        GestureDetector(
                          onTap: () async {
                            final snapshot = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.id)
                                .collection('following')
                                .get();
                            final ids = snapshot.docs.map((doc) => doc.id).toList();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserListScreen(title: "Following", userIds: ids),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text('${profileViewModel.followingCount}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Following'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (currentUserId != userId) ...[
                      ElevatedButton(
                        onPressed: () async {
                          await profileViewModel.toggleFollow(user.id);
                          final msg = profileViewModel.isFollowing
                              ? 'You are now following @${user.username}'
                              : 'You unfollowed @${user.username}';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
                          );
                          await profileViewModel.fetchUserProfile(userId);
                        },
                        child: Text(profileViewModel.isFollowing ? "Unfollow" : "Follow"),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          await settingsViewModel.unblockUser(user.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Blocked @${user.username}')),
                          );
                          await settingsViewModel.fetchSettings();
                          Navigator.pop(context);
                        },
                        child: const Text('Block User'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                    const Divider(height: 30),
                    posts.isEmpty
                        ? const Center(child: Text('No posts available. Try refreshing.'))
                        : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(10.0),
                      itemCount: posts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        print('Rendering profile post ${post.id}: isArchived=${post.isArchived}');
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          clipBehavior: Clip.hardEdge,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostDetailScreen(post: post),
                                ),
                              );
                            },
                            child: post.type == 'video' && post.videoUrl.isNotEmpty
                                ? VideoPostCard(
                              post: post,
                              isThumbnailOnly: true,
                              isGridView: true,
                            )
                                : post.imageUrl.isNotEmpty
                                ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                            )
                                : const SizedBox(
                              height: 200,
                              child: Center(child: Icon(Icons.broken_image)),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}