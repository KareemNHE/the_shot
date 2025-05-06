//views/edit_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:the_shot2/models/categories.dart';
import 'package:the_shot2/models/post_model.dart';
import 'package:the_shot2/viewmodels/post_actions_viewmodel.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  String? _selectedCategory;
  XFile? _customThumbnail;
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.post.caption;
    _selectedCategory = widget.post.category;
    _thumbnailPath = widget.post.thumbnailUrl;
  }

  Future<void> _pickThumbnail() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _customThumbnail = pickedFile;
          _thumbnailPath = pickedFile.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick thumbnail: $e')),
      );
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = SportCategories.list;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          TextButton(
            onPressed: () async {
              final postActionsViewModel = Provider.of<PostActionsViewModel>(context, listen: false);
              await postActionsViewModel.editPost(
                postId: widget.post.id,
                userId: widget.post.userId,
                caption: _captionController.text,
                category: _selectedCategory ?? widget.post.category,
                thumbnail: widget.post.type == 'video' ? _customThumbnail : null,
              );

              if (postActionsViewModel.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(postActionsViewModel.errorMessage!)),
                );
                postActionsViewModel.clearError();
              } else {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post updated')),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Color(0xFF8A56AC)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<PostActionsViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.post.type == 'video' && _thumbnailPath != null && _thumbnailPath!.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: GestureDetector(
                        onTap: _pickThumbnail,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _customThumbnail != null
                                ? Image.file(
                              File(_thumbnailPath!),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Image.network(
                                widget.post.thumbnailUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                                : Image.network(
                              widget.post.thumbnailUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.edit,
                                size: 40,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (widget.post.type == 'video')
                    TextButton.icon(
                      onPressed: _pickThumbnail,
                      icon: const Icon(Icons.image, color: Color(0xFF8A56AC)),
                      label: const Text(
                        'Pick Custom Thumbnail',
                        style: TextStyle(color: Color(0xFF8A56AC)),
                      ),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      labelText: 'Caption',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (viewModel.isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}