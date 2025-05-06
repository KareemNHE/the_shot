
//views/login_screen.dart

import 'package:flutter/material.dart';
import 'package:the_shot2/views/bnb.dart';
import 'package:the_shot2/components/LIbutton.dart';
import 'package:the_shot2/components/textfield.dart';
import 'package:the_shot2/viewmodels/login_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_shot2/views/signup_screen.dart';

import 'forgot_pass_screen.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final LoginViewModel _viewModel = LoginViewModel();

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _logIn() async {
    String input = _emailController.text.trim();
    String password = _passwordController.text.trim();

    User? user = await _viewModel.loginUser(input, password);

    if (user != null) {
      print("User successfully logged in with UID: ${user.uid}");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showError('Invalid username/email or password');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              Image.asset(
                'assets/logo.png',
                height: 300,
                width: 300,
              ),
              MyTextField(
                controller: _emailController,
                hintText: 'Email',
                obscuretext: false,
              ),
              SizedBox(height: 10),
              MyTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscuretext: true,
              ),

              //Forgot Password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ForgotPassScreen()));
                      },
                      child: Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25.0),
              MyButton(
                onTap: () => _logIn(),
                child: const Text('Log in'),
              ),
              SizedBox(height: 50.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Not a member? ', style: TextStyle(color: Colors.grey[700])),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => Signup()));
                    },
                    child: Text(
                      'Sign up here',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFAE3BE3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}