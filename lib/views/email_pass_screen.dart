


//'views/email_pass_screen.dart'

import 'package:flutter/material.dart';
import 'package:the_shot2/components/LIbutton.dart';
import 'package:the_shot2/components/textfield.dart';
import 'package:the_shot2/viewmodels/email_pass_viewmodel.dart';
import 'package:the_shot2/views/login_screen.dart';

class EmailPass extends StatelessWidget {
  final emailPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'A temporary password has been sent to your email.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.0),
            MyTextField(
              controller: emailPasswordController,
              hintText: 'Temporary Password',
              obscuretext: true,
            ),
            SizedBox(height: 16.0),
            MyButton(
              onTap: () => _verifyEmailPassword(context),
              child: Text(
                'Verify',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyEmailPassword(BuildContext context) async {
    final emailPassword = emailPasswordController.text;

    // Perform verification logic here
    // For example, verify the temporary password with the backend

    // If verification succeeds, navigate to the next screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>
          Login()), // Replace NextScreen with your desired screen
    );
  }
}