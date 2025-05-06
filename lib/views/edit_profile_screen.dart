
// views/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/viewmodels/edit_profile_viewmodel.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<EditProfileViewModel>(context, listen: false);
    viewModel.loadUserData();

    // Initialize controllers with default values
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _addressController = TextEditingController();

    // Listen for data updates
    viewModel.addListener(() {
      if (mounted) {
        setState(() {
          _usernameController.text = viewModel.username ?? '';
          _bioController.text = viewModel.bio ?? '';
          _addressController.text = viewModel.address ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Pick Profile Picture
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // Save Profile Changes
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final viewModel = Provider.of<EditProfileViewModel>(context, listen: false);

      bool success = await viewModel.updateUserProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
        profileImage: _profileImage,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating profile. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<EditProfileViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Picture
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!) as ImageProvider
                        : NetworkImage(viewModel.profilePictureUrl),
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Bio Field
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),

                // Save Button
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAE3BE3),
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, color: Colors.white),
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
