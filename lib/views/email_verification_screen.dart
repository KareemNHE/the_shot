// views/email_verification_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_shot2/viewmodels/signup_viewmodel.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final SignUpViewModel _viewModel = SignUpViewModel();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  // Periodically check if email is verified
  Future<void> _checkEmailVerification() async {
    setState(() {
      _isVerifying = true;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Refresh user data
      if (user.emailVerified) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isEmailVerified': true});
        Navigator.pushReplacementNamed(context, '/home');
      }
    }

    setState(() {
      _isVerifying = false;
    });
  }

  // Resend verification email
  Future<void> _resendEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      bool success = await _viewModel.sendEmailVerification(user);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Verification email sent!'
              : 'Failed to send verification email.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email, size: 100, color: Colors.grey),
                const SizedBox(height: 20),
                const Text(
                  'Verify Your Email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'A verification email has been sent to ${_auth.currentUser?.email ?? ''}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isVerifying ? null : _checkEmailVerification,
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Check Verification'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _resendEmail,
                  child: const Text(
                    'Resend Verification Email',
                    style: TextStyle(
                      color: Color(0xFFAE3BE3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    _auth.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}