import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/cloudinary_service.dart';
import '../utils/image_helper.dart';

/// Reusable image upload widget that works on Web + Mobile
///
/// This widget handles:
/// - Image selection via ImagePicker
/// - Preview of selected image
/// - Upload to Cloudinary
/// - Loading indicators
/// - Error handling
class ImageUploadWidget extends StatefulWidget {
  /// The upload preset to use (required)
  final String uploadPreset;

  /// Optional publicId for the upload
  final String? publicId;

  /// Optional folder path
  final String? folder;

  /// Callback when upload is successful
  final Function(String imageUrl, String publicId) onUploadSuccess;

  /// Callback when upload fails
  final Function(String error)? onUploadError;

  /// Callback when upload process starts
  final VoidCallback? onUploadStarted;

  /// Callback when image is removed
  final VoidCallback? onDelete;

  /// Initial image URL to display
  final String? initialImageUrl;

  /// Width of the upload area
  final double? width;

  /// Height of the upload area
  final double? height;

  /// Aspect ratio of the preview card (e.g., 16/9 for banners)
  final double? aspectRatio;

  /// Border radius
  final double borderRadius;

  /// Show a label above the upload area
  final String? label;

  /// Icon to show when no image is selected
  final IconData placeholderIcon;

  /// Allow selecting from camera (mobile only)
  final bool allowCamera;

  const ImageUploadWidget({
    super.key,
    required this.uploadPreset,
    required this.onUploadSuccess,
    this.publicId,
    this.onUploadStarted,
    this.folder,
    this.onUploadError,
    this.onDelete,
    this.aspectRatio,
    this.initialImageUrl,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.label,
    this.placeholderIcon = Icons.add_photo_alternate,
    this.allowCamera = true,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService.instance;

  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _error = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        debugPrint('📸 No image selected');
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imageUrl = null; // Clear previous URL
      });

      // Automatically upload after selection
      await _uploadImage();
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      setState(() {
        _error = 'Failed to pick image';
      });
      widget.onUploadError?.call('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    widget.onUploadStarted?.call();

    try {
      debugPrint('📤 Starting upload');
      // Evict current image from cache if it exists
      if (_imageUrl != null) await ImageHelper.evictImage(_imageUrl);
      // ImageHelper.evictImage already clears PaintingBinding.instance.imageCache

      final result = await _cloudinary.uploadImage(
        imageBytes: _imageBytes!,
        uploadPreset: widget.uploadPreset,
        publicId: widget.publicId,
        folder: widget.folder,
      );

      final imageUrl = result['url']!;
      final publicId = result['public_id']!;

      debugPrint('✅ Upload successful: $imageUrl');

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });
        widget.onUploadSuccess(imageUrl, publicId);
      }
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _error = 'Upload failed';
        });
        widget.onUploadError?.call('Upload failed: $e');
      }
    }
  }

  void _showImageSourceDialog() {
    if (!widget.allowCamera || kIsWeb) {
      // On web or if camera not allowed, go straight to gallery
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
        ],
        AspectRatio(
          aspectRatio:
              widget.aspectRatio ?? (widget.height == null ? 16 / 9 : 1.0),
          child: InkWell(
            onTap: _isUploading ? null : _showImageSourceDialog,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border:
                    (_imageUrl != null || _imageBytes != null || _isUploading)
                    ? Border.all(
                        color: _error != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: 2,
                      )
                    : Border.all(
                        color: _error != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline.withOpacity(0.2),
                        width: 1.5,
                      ),
                boxShadow: [
                  if (_imageUrl != null || _imageBytes != null)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              child: CustomPaint(
                painter:
                    (_imageUrl == null && _imageBytes == null && !_isUploading)
                    ? DashedBorderPainter(
                        color: _error != null
                            ? theme.colorScheme.error
                            : theme.colorScheme.outline.withOpacity(0.3),
                        borderRadius: widget.borderRadius,
                        dash: 8,
                        gap: 4,
                      )
                    : null,
                child: _buildContent(theme),
              ),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Show loading indicator
    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Uploading...', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Prepare image content
    Widget? imageContent;
    if (_imageBytes != null) {
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 2),
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_imageUrl != null &&
        _imageUrl!.isNotEmpty &&
        (_imageUrl!.startsWith('http') || _imageUrl!.startsWith('https'))) {
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 2),
        child: CachedNetworkImage(
          imageUrl: ImageHelper.refreshImageUrl(_imageUrl!),
          cacheKey: '${_imageUrl!}_${DateTime.now().millisecondsSinceEpoch}',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => _buildPlaceholder(theme),
        ),
      );
    }

    if (imageContent != null) {
      return Stack(
        children: [
          Positioned.fill(child: imageContent),
          // Top-right floating controls
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  onTap: _showImageSourceDialog,
                  color: Colors.white,
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    onTap: () {
                      setState(() {
                        _imageUrl = null;
                        _imageBytes = null;
                      });
                      widget.onDelete!();
                    },
                    color: Colors.redAccent,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.placeholderIcon,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to upload image',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2.0,
    this.gap = 5.0,
    this.dash = 10.0,
    this.borderRadius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
