// viewmodels/signup_viewmodel.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignUpViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Check if username is unique
  Future<bool> isUsernameAvailable(String username) async {
    var result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return result.docs.isEmpty; // true if username is available
  }

  // Upload profile picture to Firebase Storage
  Future<String?> _uploadProfilePicture(File? image, String userId) async {
    if (image == null) {
      print('No profile picture provided');
      return null;
    }

    try {
      Reference ref = _storage.ref().child('profile_pics/$userId.jpg');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Profile picture uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      print('Verification email sent to ${user.email}');
      return true;
    } catch (e) {
      print('Error sending verification email: $e');
      return false;
    }
  }

  // Sign-up user
  Future<bool> signUpUser({
    required String firstName,
    required String lastName,
    required String username,
    required String phoneNum,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    if (!await isUsernameAvailable(username)) {
      print('Username already taken!');
      return false;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;
      if (user == null) {
        print('User creation failed');
        return false;
      }

      String userId = user.uid;

      // Send email verification
      bool verificationSent = await sendEmailVerification(user);
      if (!verificationSent) {
        print('Failed to send verification email');
        return false;
      }

      // Upload profile picture if provided
      String? profilePicUrl = await _uploadProfilePicture(profileImage, userId);

      // Store user data to Firestore
      await _firestore.collection('users').doc(userId).set({
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'phone_num': phoneNum,
        'email': email,
        'profile_picture': profilePicUrl ?? '',
        'isEmailVerified': false, // Initially false
      });

      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  // Temporary function to manually verify email (for testing only)
  Future<bool> manuallyVerifyEmail(String uid) async {
    try {
      // Update Firestore
      await _firestore.collection('users').doc(uid).update({
        'isEmailVerified': true,
      });
      print('Firestore updated: isEmailVerified set to true for UID: $uid');
      return true;
    } catch (e) {
      print('Error manually verifying email: $e');
      return false;
    }
  }
}