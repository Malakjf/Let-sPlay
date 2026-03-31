import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<dynamic> photos; // each item is either Uint8List or String path
  final int initialIndex;
  const PhotoViewerScreen({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImage(dynamic p) {
    if (p is List<int> || p is Uint8List) {
      final bytes = p is Uint8List ? p : Uint8List.fromList(p as List<int>);
      return InteractiveViewer(
        maxScale: 4.0,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } else if (p is String) {
      // Check if it's a URL or file path
      if (p.startsWith('http://') || p.startsWith('https://')) {
        // It's a URL from Cloudinary
        return InteractiveViewer(
          maxScale: 4.0,
          child: Image.network(
            p,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 60, color: Colors.white54),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        // It's a local file path (mobile only)
        return InteractiveViewer(
          maxScale: 4.0,
          child: Image.file(File(p), fit: BoxFit.contain),
        );
      }
    } else {
      return const Center(
        child: Text('Unsupported image', style: TextStyle(color: Colors.white)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${_index + 1} / $total'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) {
          final p = widget.photos[i];
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: _buildImage(p),
          );
        },
      ),
    );
  }
}
