import 'package:flutter/foundation.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../utils/image_helper.dart'; // Import ImageHelper

/// Cloudinary service for unsigned image uploads
///
/// This service handles image uploads to Cloudinary using unsigned upload presets.
/// It supports different upload scenarios:
/// - User avatars (with user-specific publicId)
/// - Product images (with product-specific publicId)
/// - Field images (with auto-generated publicId)
class CloudinaryService {
  CloudinaryService._internal();
  static final CloudinaryService instance = CloudinaryService._internal();

  // Cloudinary configuration
  static const String _cloudName = 'dndl9unee';

  // Upload presets
  static const String avatarPreset = 'letsplay_prod';
  static const String fieldsPreset = 'fields_unsigned';
  static const String productsPreset = 'products_unsigned';
  static const String academyPreset = 'academy_upload';
  static const String academyFolder = 'academy_ads';

  /// Upload image bytes to Cloudinary using unsigned upload
  ///
  /// Parameters:
  /// - [imageBytes]: Image data to upload
  /// - [uploadPreset]: Cloudinary upload preset name
  /// - [publicId]: Optional custom publicId for the uploaded image
  /// - [folder]: Optional folder path (usually handled by preset)
  ///
  /// Returns a Map containing 'url' and 'public_id'
  Future<Map<String, String>> uploadImage({
    required Uint8List imageBytes,
    required String uploadPreset,
    String? publicId,
    String? folder,
  }) async {
    try {
      debugPrint('📤 Cloudinary upload started');
      debugPrint('   Preset: $uploadPreset');
      debugPrint('   Image size: ${imageBytes.length} bytes');

      // Use CloudinaryPublic for a minimal and valid unsigned upload flow
      final cloudinary = CloudinaryPublic(
        _cloudName,
        uploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          imageBytes.buffer.asByteData(),
          identifier: publicId ?? 'upload', // Use unique ID as public_id
          folder: folder,
        ),
      );

      // Use ImageHelper to refresh URL with timestamp for cache busting
      final secureUrl = ImageHelper.refreshImageUrl(response.secureUrl);

      debugPrint('✅ Upload successful: $secureUrl');
      debugPrint('✅ Public ID: ${response.publicId}');

      return {'url': secureUrl, 'public_id': response.publicId};
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      throw CloudinaryException('Failed to upload image: $e');
    }
  }

  /// Upload user avatar
  /// Uses letsplay_prod preset with userId as publicId
  Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    // Keep uniqueId generation for cache busting on CDN
    final uniqueId = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final result = await uploadImage(
      imageBytes: imageBytes,
      uploadPreset: avatarPreset,
      publicId: uniqueId,
    );
    return result['url']!;
  }

  /// Upload product image
  /// Uses products_unsigned preset with productId as publicId
  Future<String> uploadProductImage({
    required Uint8List imageBytes,
    required String productId,
  }) async {
    // Keep uniqueId generation for cache busting on CDN
    final uniqueId = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    final result = await uploadImage(
      imageBytes: imageBytes,
      uploadPreset: productsPreset,
      publicId: uniqueId,
    );
    return result['url']!;
  }

  /// Upload field image
  /// Uses fields_unsigned preset with auto-generated publicId
  Future<String> uploadFieldImage({required Uint8List imageBytes}) async {
    final result = await uploadImage(
      imageBytes: imageBytes,
      uploadPreset: fieldsPreset,
      // No publicId - will be auto-generated
    );
    return result['url']!;
  }

  /// Upload academy announcement image
  /// Uses academy_upload preset and academy_ads folder
  Future<Map<String, String>> uploadAcademyAnnouncementImage({
    required Uint8List imageBytes,
  }) async {
    return uploadImage(
      imageBytes: imageBytes,
      uploadPreset: academyPreset,
      folder: academyFolder,
    );
  }
}

/// Custom exception for Cloudinary errors
class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);

  @override
  String toString() => 'CloudinaryException: $message';
}
