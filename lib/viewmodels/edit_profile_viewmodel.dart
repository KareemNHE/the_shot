// viewmodels/edit_profile_viewmodel.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class EditProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _username;
  String? _bio;
  String? _address;
  String _profilePictureUrl = '';
  bool _isLoading = true;

  // Getters
  String? get username => _username;
  String? get bio => _bio;
  String? get address => _address;
  String get profilePictureUrl => _profilePictureUrl;
  bool get isLoading => _isLoading;

  // Load User Data
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _username = userDoc['username'] ?? '';
          _bio = userDoc.data()?['bio'] ?? '';
          _address = userDoc.data()?['address'] ?? '';
          _profilePictureUrl = userDoc['profile_picture'] ??
              'assets/default_profile.png'; // Default profile pic
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update User Profile
  Future<bool> updateUserProfile({
    required String username,
    required String bio,
    required String address,
    File? profileImage,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String? profilePicUrl = _profilePictureUrl;

        // Upload profile picture if updated
        if (profileImage != null) {
          profilePicUrl = await _uploadProfilePicture(profileImage, user.uid);
        }

        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'username': username,
          'bio': bio,
          'address': address,
          'profile_picture': profilePicUrl,
        });

        // Update local data
        _username = username;
        _bio = bio;
        _address = address;
        _profilePictureUrl = profilePicUrl ?? _profilePictureUrl;
        notifyListeners();

        return true;
      }
    } catch (e) {
      print('Error updating profile: $e');
    }

    return false;
  }

  // Upload Profile Picture to Firebase Storage
  Future<String?> _uploadProfilePicture(File image, String userId) async {
    try {
      Reference ref = _storage.ref().child('profile_pics/$userId.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }
}
