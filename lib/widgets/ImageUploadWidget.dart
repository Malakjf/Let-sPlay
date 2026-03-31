import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

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
  final Function(String imageUrl) onUploadSuccess;

  /// Callback when upload fails
  final Function(String error)? onUploadError;

  /// Initial image URL to display
  final String? initialImageUrl;

  /// Width of the upload area
  final double? width;

  /// Height of the upload area
  final double? height;

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
    this.folder,
    this.onUploadError,
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
        maxWidth: 1920,
        maxHeight: 1920,
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

    try {
      debugPrint('📤 Starting upload');
      final imageUrl = await _cloudinary.uploadImage(
        imageBytes: _imageBytes!,
        uploadPreset: widget.uploadPreset,
        publicId: widget.publicId,
        folder: widget.folder,
      );

      debugPrint('✅ Upload successful: $imageUrl');

      if (mounted) {
        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });
        widget.onUploadSuccess(imageUrl);
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
        InkWell(
          onTap: _isUploading ? null : _showImageSourceDialog,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _error != null
                    ? theme.colorScheme.error
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _buildContent(theme),
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

    // Show preview of selected image (before upload completes)
    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 2),
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // Show uploaded image
    if (_imageUrl != null &&
        _imageUrl!.isNotEmpty &&
        (_imageUrl!.startsWith('http') || _imageUrl!.startsWith('https'))) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius - 2),
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(theme);
              },
            ),
          ),
          // Change/Edit overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius - 2),
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 32),
            ),
          ),
        ],
      );
    }

    // Show placeholder
    return _buildPlaceholder(theme);
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
          'Tap to upload',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
