//viewmodel/post_viewmodel.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/profile_viewmodel.dart';

class PostViewModel extends ChangeNotifier {
  List<PostModel> _userPosts = [];
  List<PostModel> _archivedPosts = [];
  List<PostModel> _savedPosts = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool isLiked = false;
  bool isSaved = false;
  int likeCount = 0;
  int commentCount = 0;

  List<PostModel> get userPosts => _userPosts;
  List<PostModel> get archivedPosts => _archivedPosts;
  List<PostModel> get savedPosts => _savedPosts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserPosts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .where('isArchived', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      _userPosts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('Fetched ${_userPosts.length} posts for user $userId');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching user posts: $e';
      print('Error fetching user posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchArchivedPosts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archivedPosts')
          .orderBy('timestamp', descending: true)
          .get();

      _archivedPosts = querySnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('Fetched ${_archivedPosts.length} archived posts for user $userId');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching archived posts: $e';
      print('Error fetching archived posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSavedPosts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      QuerySnapshot savedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .get();

      _savedPosts = [];
      for (var doc in savedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final postRef = data['postRef'] as DocumentReference;
        final postDoc = await postRef.get();
        if (postDoc.exists) {
          _savedPosts.add(PostModel.fromFirestore(postDoc.data() as Map<String, dynamic>, postDoc.id));
        }
      }

      print('Fetched ${_savedPosts.length} saved posts for user $userId');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error fetching saved posts: $e';
      print('Error fetching saved posts: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkIfPostIsSaved(String postId, String userId) async {
    if (userId.isEmpty) {
      isSaved = false;
      notifyListeners();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .get();

      isSaved = doc.exists;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error checking saved status: $e';
      print('Error checking saved status: $e');
    }
  }

  Future<void> savePost({
    required String postId,
    required String postOwnerId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .set({
        'postRef': FirebaseFirestore.instance
            .collection('users')
            .doc(postOwnerId)
            .collection('posts')
            .doc(postId),
        'timestamp': FieldValue.serverTimestamp(),
      });
      isSaved = true;
    } catch (e) {
      _errorMessage = 'Failed to save post: $e';
      print('Error saving post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> unsavePost({
    required String postId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .delete();
      isSaved = false;
    } catch (e) {
      _errorMessage = 'Failed to unsave post: $e';
      print('Error unsaving post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPost({
    required String userId,
    required String username,
    required String userProfilePic,
    required String imageUrl,
    required String caption,
  }) async {
    try {
      DocumentReference postRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .add({
        'userId': userId,
        'username': username,
        'userProfilePic': userProfilePic,
        'imageUrl': imageUrl,
        'caption': caption,
        'timestamp': FieldValue.serverTimestamp(),
        'hashtags': [],
        'category': 'Uncategorized',
        'type': 'image',
        'isArchived': false,
        'commentsDisabled': false,
      });

      print('Post created with ID: ${postRef.id}, isArchived: false');
      // Verify post data
      final postDoc = await postRef.get();
      print('Verified post ${postRef.id}: ${postDoc.data()}');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error creating post: $e';
      print('Error creating post: $e');
    }
  }

  Future<void> fetchInteractionData(String postId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postId.split('/')[0])
          .collection('posts')
          .doc(postId.split('/')[2])
          .collection('likes')
          .doc(uid)
          .get();

      isLiked = likeDoc.exists;

      final likeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(postId.split('/')[0])
          .collection('posts')
          .doc(postId.split('/')[2])
          .collection('likes')
          .get();

      likeCount = likeSnapshot.docs.length;

      final commentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(postId.split('/')[0])
          .collection('posts')
          .doc(postId.split('/')[2])
          .collection('comments')
          .get();

      commentCount = commentSnapshot.docs.length;

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error fetching interaction data: $e';
      print('Error fetching interaction data: $e');
    }
  }

  Future<void> toggleLike(String postId, String postOwnerId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(uid);

    try {
      if (isLiked) {
        await ref.delete();
        likeCount--;
      } else {
        await ref.set({'timestamp': FieldValue.serverTimestamp()});
        await NotificationService.createNotification(
          recipientId: postOwnerId,
          type: 'like',
          relatedPostId: postId,
        );
        likeCount++;
      }

      isLiked = !isLiked;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error toggling like: $e';
      print('Error toggling like: $e');
    }
  }

  Future<void> editPost({
    required String postId,
    required String userId,
    required String caption,
    required String category,
    XFile? thumbnail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? thumbnailUrl;
      if (thumbnail != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('posts/$postId/thumbnail.jpg');
        await storageRef.putFile(File(thumbnail.path));
        thumbnailUrl = await storageRef.getDownloadURL();
      }

      final postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId);

      final updateData = <String, dynamic>{
        'caption': caption,
        'category': category,
        'hashtags': caption.split(' ').where((word) => word.startsWith('#')).toList(),
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'isArchived': false,
      };

      await postRef.update(updateData);

      final archivedPostRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archivedPosts')
          .doc(postId);
      if ((await archivedPostRef.get()).exists) {
        await archivedPostRef.update(updateData);
      }
    } catch (e) {
      _errorMessage = 'Failed to edit post: $e';
      print('Error editing post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePost({
    required String postId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archivedPosts')
          .doc(postId)
          .delete();

      await FirebaseStorage.instance
          .ref()
          .child('posts/$postId')
          .delete()
          .catchError((e) => print('No storage files to delete: $e'));
    } catch (e) {
      _errorMessage = 'Failed to delete post: $e';
      print('Error deleting post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> archivePost({
    required String postId,
    required String userId,
    required bool archive,
    BuildContext? context,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId);

      final postDoc = await postRef.get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      postData['isArchived'] = true;

      if (archive) {
        print('Archiving post $postId for user $userId');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('archivedPosts')
            .doc(postId)
            .set(postData);

        await postRef.update({'isArchived': true});
        print('Post $postId archived: isArchived=true');

        await fetchUserPosts(userId);
        await fetchArchivedPosts(userId);
        if (context != null) {
          Provider.of<ProfileViewModel>(context, listen: false).fetchUserProfile();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to archive post: $e';
      print('Error archiving post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> unarchivePost({
    required String postId,
    required String userId,
    BuildContext? context,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Unarchiving post $postId for user $userId');
      final archivedPostRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archivedPosts')
          .doc(postId);
      if (await archivedPostRef.get().then((doc) => doc.exists)) {
        await archivedPostRef.delete();
        print('Post $postId removed from archivedPosts');
      } else {
        print('Post $postId not found in archivedPosts');
      }

      final postRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId);
      if (await postRef.get().then((doc) => doc.exists)) {
        await postRef.update({'isArchived': false});
        print('Post $postId updated: isArchived=false');
      } else {
        print('Post $postId not found in posts');
      }

      await fetchUserPosts(userId);
      await fetchArchivedPosts(userId);
      if (context != null) {
        Provider.of<ProfileViewModel>(context, listen: false).fetchUserProfile();
      } else {
        print('Context is null, skipping ProfileViewModel.fetchUserProfile');
      }
    } catch (e) {
      _errorMessage = 'Failed to unarchive post: $e';
      print('Error unarchiving post: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> disableComments({
    required String postId,
    required String userId,
    required bool disable,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('posts')
          .doc(postId)
          .update({'commentsDisabled': disable});

      final archivedPostRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('archivedPosts')
          .doc(postId);
      if ((await archivedPostRef.get()).exists) {
        await archivedPostRef.update({'commentsDisabled': disable});
      }
    } catch (e) {
      _errorMessage = 'Failed to ${disable ? 'disable' : 'enable'} comments: $e';
      print('Error ${disable ? 'disabling' : 'enabling'} comments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}