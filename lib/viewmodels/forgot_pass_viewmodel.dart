//viewmodels/forgot_pass_viewmodel.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_shot2/user_auth/firebase_auth_implementation/firebase_auth_services.dart';

class ForgotPasswordViewModel {
  final FirebaseAuthService _authService = FirebaseAuthService();

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    if (!_isValidEmail(email)) {
      print('Invalid email format: $email');
      throw Exception('Please enter a valid email address.');
    }

    try {
      bool success = await _authService.sendPasswordResetEmail(email);
      if (success) {
        print('Password reset email sent to $email');
        return true;
      } else {
        print('Failed to send password reset email');
        throw Exception('Failed to send password reset email.');
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth error: ${e.code} - ${e.message}');
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is invalid.');
      }
      throw Exception('Error sending password reset email: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('An unexpected error occurred.');
    }
  }
}