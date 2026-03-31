import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_service.dart';

/// Dialog for uploading user avatar
///
/// This dialog allows users to:
/// - Select an image from gallery or camera
/// - Preview the selected image
/// - Upload to Cloudinary
/// - Save the URL to Firestore
class AvatarUploadDialog extends StatefulWidget {
  final String userId;
  final String? currentAvatarUrl;

  const AvatarUploadDialog({
    super.key,
    required this.userId,
    this.currentAvatarUrl,
  });

  @override
  State<AvatarUploadDialog> createState() => _AvatarUploadDialogState();
}

class _AvatarUploadDialogState extends State<AvatarUploadDialog> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService.instance;
  final FirebaseService _firebase = FirebaseService.instance;

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _error = null;
      });

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      setState(() {
        _error = 'Failed to pick image';
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      // Upload to Cloudinary
      debugPrint('📤 Uploading avatar for user: ${widget.userId}');
      final imageUrl = await _cloudinary.uploadAvatar(
        imageBytes: _selectedImageBytes!,
        userId: widget.userId,
      );

      // Save URL to Firestore
      debugPrint('💾 Saving avatar URL to Firestore');
      await _firebase.updateUserData(widget.userId, {'avatarUrl': imageUrl});

      debugPrint('✅ Avatar updated successfully');

      if (mounted) {
        Navigator.of(context).pop(imageUrl);
      }
    } catch (e) {
      debugPrint('❌ Upload failed: $e');
      setState(() {
        _isUploading = false;
        _error = 'Upload failed. Please try again.';
      });
    }
  }

  void _showImageSourceDialog() {
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

    return AlertDialog(
      title: const Text('Update Avatar'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview
            GestureDetector(
              onTap: _isUploading ? null : _showImageSourceDialog,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: _buildPreview(theme),
              ),
            ),
            const SizedBox(height: 16),
            // Error message
            if (_error != null)
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            // Upload button
            if (_selectedImageBytes != null && !_isUploading)
              ElevatedButton.icon(
                onPressed: _uploadAndSave,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Avatar'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildPreview(ThemeData theme) {
    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Uploading...'),
          ],
        ),
      );
    }

    if (_selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
      );
    }

    if (widget.currentAvatarUrl != null &&
        widget.currentAvatarUrl!.isNotEmpty &&
        (widget.currentAvatarUrl!.startsWith('http') ||
            widget.currentAvatarUrl!.startsWith('https'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          widget.currentAvatarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(theme);
          },
        ),
      );
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to select',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Shows the avatar upload dialog
Future<String?> showAvatarUploadDialog({
  required BuildContext context,
  required String userId,
  String? currentAvatarUrl,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        AvatarUploadDialog(userId: userId, currentAvatarUrl: currentAvatarUrl),
  );
}
