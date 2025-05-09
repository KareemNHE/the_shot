//user_auth/firebase_auth_implementation/firebase_auth_services.dart
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      } else {
        print('Error: ${e.code}');
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  // Login
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      } else {
        print('Error: ${e.code}');
      }
    } catch (e) {
      print('Error: $e');
    }
    return null;
  }

  // Send Password Reset Email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://eauth-5e352.web.app/reset-password',
          handleCodeInApp: true,
          iOSBundleId: 'com.example.theshot', // Replace with your iOS bundle ID
          androidPackageName: 'com.example.theshot', // Replace with your Android package name
          androidInstallApp: true,
          androidMinimumVersion: '1',
        ),
      );
      print('Password reset email sent to $email');
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }
}