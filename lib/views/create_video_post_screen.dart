//views/create_video_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/categories.dart';
import '../viewmodels/create_post_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../views/widgets/custom_video_player.dart';

class CreateVideoPostScreen extends StatefulWidget {
  final File videoFile;

  const CreateVideoPostScreen({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<CreateVideoPostScreen> createState() => _CreateVideoPostScreenState();
}

class _CreateVideoPostScreenState extends State<CreateVideoPostScreen> {
  final _captionController = TextEditingController();
  String? _selectedCategory;
  String? _thumbnailPath;
  bool _showThumbnail = true;
  File? _customThumbnail;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      if (mounted && _customThumbnail == null) {
        setState(() {
          _thumbnailPath = thumbnailPath;
        });
      }
    } catch (e) {
      print('Error generating thumbnail: $e');
      if (mounted) {
        setState(() {
          _showThumbnail = false;
        });
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          _customThumbnail = File(pickedFile.path);
          _thumbnailPath = pickedFile.path;
          _showThumbnail = true;
        });
      }
    } catch (e) {
      print('Error picking thumbnail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick thumbnail: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _categories = SportCategories.list;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: _showThumbnail && _thumbnailPath != null
                  ? GestureDetector(
                onTap: () {
                  setState(() {
                    _showThumbnail = false;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_thumbnailPath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 60,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              )
                  : CustomVideoPlayer(
                videoFile: widget.videoFile,
                isLocalFile: true,
              ),
            ),
            const SizedBox(height: 10),
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

                await createPostViewModel.uploadVideoPost(
                  videoFile: widget.videoFile,
                  caption: _captionController.text,
                  category: _selectedCategory ?? 'Uncategorized',
                  context: context,
                  homeViewModel: homeViewModel,
                  customThumbnail: _customThumbnail,
                );

                Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A56AC),
              ),
              child: const Text('Post!'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}