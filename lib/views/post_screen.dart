// views/post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:the_shot2/views/camera_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:the_shot2/views/create_image_post_screen.dart';
import 'create_video_post_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';
import 'package:mime/mime.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  List<AssetEntity> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndFetchAlbums();
  }

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<void> _requestPermissionsAndFetchAlbums() async {
    await requestPermissions();
    await _fetchAlbums();
  }

  Future<void> requestPermissions() async {
    final PermissionState result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      print("Media permission granted");
    } else {
      PhotoManager.openSetting();
      print("Media permission denied");
    }
  }

  Future<void> _fetchAlbums() async {
    try {
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.all,
        filterOption: FilterOptionGroup(
          videoOption: const FilterOption(durationConstraint: DurationConstraint(min: Duration(seconds: 1))),
          imageOption: const FilterOption(),
          orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
        ),
      );
      if (albums.isEmpty) {
        setState(() {
          _albums = [];
          _loading = false;
        });
        return;
      }

      final mediaList = await albums[0].getAssetListPaged(page: 0, size: 60);

      List<AssetEntity> allMedia = [];

      for (final album in albums) {
        final media = await album.getAssetListPaged(page: 0, size: 60);
        allMedia.addAll(media);
      }

      setState(() {
        _albums = allMedia;
        _loading = false;
      });
    } catch (e) {
      print("Gallery access error: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickMedia(
      requestFullMetadata: true,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final mimeType = lookupMimeType(file.path);
      final ext = file.path.split('.').last.toLowerCase();

      // Check MIME type first, then fall back to extension
      bool isVideo = (mimeType != null && mimeType.startsWith('video/')) ||
          ['mp4', 'mov', '3gp', '3gpp', 'avi', 'mkv', 'mpeg'].contains(ext);

      if (isVideo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateVideoPostScreen(videoFile: file),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateImagePostScreen(imagePath: file.path),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAlbums,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_albums.isEmpty)
            ? const Center(child: Text('No media found'))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _albums.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final asset = _albums[index];
                  return GestureDetector(
                    onTap: () async {
                      final file = await asset.file;
                      if (file != null) {
                        // Use asset.type for reliable video detection
                        bool isVideo = asset.type == AssetType.video;

                        // Fallback to MIME type or extension if needed
                        if (!isVideo) {
                          final mimeType = lookupMimeType(file.path);
                          final extension = file.path.split('.').last.toLowerCase();
                          isVideo = (mimeType != null && mimeType.startsWith('video/')) ||
                              ['mp4', 'mov', 'mkv', 'mpeg', '3gp', '3gpp', 'avi'].contains(extension);
                        }

                        print('${asset.title} | type: ${asset.type} | isVideo: $isVideo');

                        if (isVideo) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateVideoPostScreen(videoFile: file),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateImagePostScreen(imagePath: file.path),
                            ),
                          );
                        }
                      }
                    },
                    child: FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            snapshot.hasData &&
                            snapshot.data != null &&
                            snapshot.data!.isNotEmpty) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              if (asset.type == AssetType.video)
                                const Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Icon(Icons.videocam, color: Colors.white),
                                ),
                            ],
                          );
                        } else {
                          return const Center(child: Icon(Icons.broken_image));
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _pickMedia,
            child: const Icon(Icons.perm_media),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'open_camera',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}