//views/create_image_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/create_post_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/categories.dart';

class CreateImagePostScreen extends StatefulWidget {
  final String imagePath;

  const CreateImagePostScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<CreateImagePostScreen> createState() => _CreateImagePostScreenState();
}

class _CreateImagePostScreenState extends State<CreateImagePostScreen> {
  final _captionController = TextEditingController();
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final List<String> _categories = SportCategories.list;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Image')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.file(File(widget.imagePath), errorBuilder: (context, error, stackTrace) {
                return const Text('Error loading image');
              }),
              const SizedBox(height: 20),
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(labelText: 'Caption'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
                  final createPostViewModel = Provider.of<CreatePostViewModel>(context, listen: false);

                  if (_selectedCategory == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a category')),
                    );
                    return;
                  }

                  await createPostViewModel.uploadImagePost(
                    imageFile: File(widget.imagePath),
                    caption: _captionController.text,
                    category: _selectedCategory!,
                    context: context,
                    homeViewModel: homeViewModel,
                  );

                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
                  final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
                  await profileViewModel.fetchUserProfile();
                },
                child: const Text('Upload Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
