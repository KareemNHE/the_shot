import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DemoHome(),
    );
  }
}

class ThumbnailRequest {
  final String video;
  final String? thumbnailPath;
  final ImageFormat imageFormat;
  final int maxHeight;
  final int maxWidth;
  final int timeMs;
  final int quality;

  const ThumbnailRequest({
    required this.video,
    this.thumbnailPath,
    required this.imageFormat,
    required this.maxHeight,
    required this.maxWidth,
    required this.timeMs,
    required this.quality,
  });
}

class ThumbnailResult {
  final Image image;
  final int dataSize;
  final int height;
  final int width;
  const ThumbnailResult({
    required this.image,
    required this.dataSize,
    required this.height,
    required this.width,
  });
}

Future genThumbnail(ThumbnailRequest r) async {
  Uint8List bytes;
  final Completer completer = Completer();
  if (r.thumbnailPath != null) {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: r.video,
      thumbnailPath: r.thumbnailPath,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    );

    print("thumbnail file is located: $thumbnailPath");

    final file = File(thumbnailPath!);
    bytes = await file.readAsBytes();
  } else {
    bytes = (await VideoThumbnail.thumbnailData(
      video: r.video,
      imageFormat: r.imageFormat,
      maxHeight: r.maxHeight,
      maxWidth: r.maxWidth,
      timeMs: r.timeMs,
      quality: r.quality,
    ))!;
  }

  int _imageDataSize = bytes.length;
  print("image size: $_imageDataSize");

  final _image = Image.memory(bytes);
  _image.image
      .resolve(const ImageConfiguration())
      .addListener(ImageStreamListener((ImageInfo info, bool _) {
    completer.complete(ThumbnailResult(
      image: _image,
      dataSize: _imageDataSize,
      height: info.image.height,
      width: info.image.width,
    ));
  }));
  return completer.future;
}

class GenThumbnailImage extends StatefulWidget {
  final ThumbnailRequest thumbnailRequest;

  const GenThumbnailImage({super.key, required this.thumbnailRequest});

  @override
  _GenThumbnailImageState createState() => _GenThumbnailImageState();
}

class _GenThumbnailImageState extends State {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: genThumbnail(widget.thumbnailRequest),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final _image = snapshot.data.image;
          final _width = snapshot.data.width;
          final _height = snapshot.data.height;
          final _dataSize = snapshot.data.dataSize;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Text(
                    "Image ${widget.thumbnailRequest.thumbnailPath == null ? 'data size' : 'file size'}: $_dataSize, width:$_width, height:$_height"),
              ),
              Container(
                color: Colors.grey,
                height: 1.0,
              ),
              _image,
            ],
          );
        } else if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.red,
            child: Text(
              "Error:\n${snapshot.error.toString()}",
            ),
          );
        } else {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text("Generating the thumbnail..."),
              SizedBox(height: 10.0),
              CircularProgressIndicator(),
            ],
          );
        }
      },
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  _DemoHomeState createState() => _DemoHomeState();
}

class _DemoHomeState extends State {
  final _editNode = FocusNode();
  final _video = TextEditingController(
      text:
          "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4");
  ImageFormat _format = ImageFormat.JPEG;
  int _quality = 50;
  int _sizeH = 0;
  int _sizeW = 0;
  int _timeMs = 0;

  GenThumbnailImage? _futureImage;

  String? _tempDir;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((d) => _tempDir = d.path);
  }

  @override
  Widget build(BuildContext context) {
    final _settings = [
      Slider(
        value: _sizeH * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _sizeH = v.toInt();
        }),
        max: 256.0,
        divisions: 256,
        label: "$_sizeH",
      ),
      Center(
        child: (_sizeH == 0)
            ? const Text(
                "Original of the video's height or scaled by the source aspect ratio")
            : Text("Max height: $_sizeH(px)"),
      ),
      Slider(
        value: _sizeW * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _sizeW = v.toInt();
        }),
        max: 256.0,
        divisions: 256,
        label: "$_sizeW",
      ),
      Center(
        child: (_sizeW == 0)
            ? const Text(
                "Original of the video's width or scaled by source aspect ratio")
            : Text("Max width: $_sizeW(px)"),
      ),
      Slider(
        value: _timeMs * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _timeMs = v.toInt();
        }),
        max: 10.0 * 1000,
        divisions: 1000,
        label: "$_timeMs",
      ),
      Center(
        child: (_timeMs == 0)
            ? const Text("The beginning of the video")
            : Text("The closest frame at $_timeMs(ms) of the video"),
      ),
      Slider(
        value: _quality * 1.0,
        onChanged: (v) => setState(() {
          _editNode.unfocus();
          _quality = v.toInt();
        }),
        max: 100.0,
        divisions: 100,
        label: "$_quality",
      ),
      Center(child: Text("Quality: $_quality")),
      Padding(
        padding: const EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 8.0),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            isDense: true,
            labelText: "Thumbnail Format",
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    groupValue: _format,
                    value: ImageFormat.JPEG,
                    onChanged: (v) => setState(() {
                      _format = v!;
                      _editNode.unfocus();
                    }),
                  ),
                  const Text("JPEG"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    groupValue: _format,
                    value: ImageFormat.PNG,
                    onChanged: (v) => setState(() {
                      _format = v!;
                      _editNode.unfocus();
                    }),
                  ),
                  const Text("PNG"),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio(
                    groupValue: _format,
                    value: ImageFormat.WEBP,
                    onChanged: (v) => setState(() {
                      _format = v!;
                      _editNode.unfocus();
                    }),
                  ),
                  const Text("WebP"),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thumbnail Plugin example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 8.0),
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                isDense: true,
                labelText: "Video URI",
              ),
              maxLines: null,
              controller: _video,
              focusNode: _editNode,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onEditingComplete: () {
                _editNode.unfocus();
              },
            ),
          ),
          for (var i in _settings) i,
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_futureImage != null) _futureImage!,
                    const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text("Settings"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            for (var i in _settings) i,
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async {
              final picker = ImagePicker();
              final video = await picker.pickVideo(source: ImageSource.camera);
              setState(() {
                _video.text = video?.path ?? '';
              });
            },
            child: const Icon(Icons.videocam),
            tooltip: "Capture a video",
          ),
          const SizedBox(width: 5.0),
          FloatingActionButton(
            onPressed: () async {
              final picker = ImagePicker();
              final video = await picker.pickVideo(source: ImageSource.gallery);
              setState(() {
                _video.text = video?.path ?? '';
              });
            },
            child: const Icon(Icons.local_movies),
            tooltip: "Pick a video",
          ),
          const SizedBox(width: 20.0),
          FloatingActionButton(
            tooltip: "Generate a data of thumbnail",
            onPressed: () async {
              setState(() {
                _futureImage = GenThumbnailImage(
                  thumbnailRequest: ThumbnailRequest(
                    video: _video.text,
                    thumbnailPath: null,
                    imageFormat: _format,
                    maxHeight: _sizeH,
                    maxWidth: _sizeW,
                    timeMs: _timeMs,
                    quality: _quality,
                  ),
                );
              });
            },
            child: const Text("Data"),
          ),
          const SizedBox(width: 5.0),
          FloatingActionButton(
            tooltip: "Generate a file of thumbnail",
            onPressed: () async {
              setState(() {
                _futureImage = GenThumbnailImage(
                  thumbnailRequest: ThumbnailRequest(
                    video: _video.text,
                    thumbnailPath: _tempDir,
                    imageFormat: _format,
                    maxHeight: _sizeH,
                    maxWidth: _sizeW,
                    timeMs: _timeMs,
                    quality: _quality,
                  ),
                );
              });
            },
            child: const Text("File"),
          ),
        ],
      ),
    );
  }
}
