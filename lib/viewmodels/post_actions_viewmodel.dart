//viewmodels/post_actions_viewmodel.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';

class PostActionsViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      final postData = postDoc.data() as Map<String, dynamic>?;
      print('Verified post ${postRef.id}: isArchived=${postData?['isArchived']}, type=${postData?['type']}');
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error creating post: $e';
      print('Error creating post: $e');
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

      final updatedPostDoc = await postRef.get();
      final updatedPostData = updatedPostDoc.data() as Map<String, dynamic>?;
      print('Post $postId edited: isArchived=${updatedPostData?['isArchived']}, type=${updatedPostData?['type']}');
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

      final updatedPostDoc = await postRef.get();
      final updatedPostData = updatedPostDoc.data() as Map<String, dynamic>?;
      print('Post $postId unarchived: isArchived=${updatedPostData?['isArchived']}, type=${updatedPostData?['type']}');

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