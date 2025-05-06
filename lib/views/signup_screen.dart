
// views/signup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_shot2/components/SUbutton.dart';
import 'package:the_shot2/components/textfield.dart';
import 'package:the_shot2/viewmodels/signup_viewmodel.dart';
import 'package:the_shot2/views/login_screen.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final SignUpViewModel _viewModel = SignUpViewModel();

  // Profile Picture Variables
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Pick Profile Picture
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      print('No image selected');
      return;
    }

    setState(() {
      _image = File(image.path);
      print('Image selected: ${_image!.path}');
    });
  }


  // Sign-Up User
  void _signUp() async {
    String username = _usernameController.text.trim();

    // Debug: Check if the username already exists
    bool isAvailable = await _viewModel.isUsernameAvailable(username);
    print('Is username available? $isAvailable');

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username already taken!')),
      );
      return;
    }

    // Proceed with sign-up
    bool success = await _viewModel.signUpUser(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: username,
      phoneNum: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      profileImage: _image,
    );

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => Login()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred during sign-up!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _image == null
                      ? AssetImage('assets/default_profile.png') // Default image
                      : FileImage(_image!) as ImageProvider,
                ),
              ),
              SizedBox(height: 10),
              Text('Select Profile Picture', style: TextStyle(color: Colors.grey[700])),

              SizedBox(height: 20),

              // First Name
              MyTextField(
                controller: _firstNameController,
                hintText: 'First Name',
                obscuretext: false,
              ),
              SizedBox(height: 10),

              // Last Name
              MyTextField(
                controller: _lastNameController,
                hintText: 'Last Name',
                obscuretext: false,
              ),
              SizedBox(height: 10),

              // Username
              MyTextField(
                controller: _usernameController,
                hintText: 'Username',
                obscuretext: false,
              ),
              SizedBox(height: 10),

              // Phone Number
              MyTextField(
                controller: _phoneController,
                hintText: 'Phone Number',
                obscuretext: false,
              ),
              SizedBox(height: 10),

              // Email
              MyTextField(
                controller: _emailController,
                hintText: 'Email',
                obscuretext: false,
              ),
              SizedBox(height: 10),

              // Password
              MyTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscuretext: true,
              ),
              SizedBox(height: 10),

              // Confirm Password
              MyTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscuretext: true,
              ),
              SizedBox(height: 25.0),

              // Sign Up Button
              MyButton(
                onTap: () => _signUp(),
                child: const Text(
                  'Sign up',
                ),
              ),
              SizedBox(height: 20),

              // Go to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already a member? ', style: TextStyle(color: Colors.grey[700])),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => Login()));                    },
                    child: Text(
                      'Login here',
                      style: TextStyle(color: Color(0xFFAE3BE3), fontWeight: FontWeight.bold),
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
