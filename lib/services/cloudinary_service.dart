import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  // Upload presets
  static const String avatarPreset = 'letsplay_prod';
  static const String fieldsPreset = 'fields_unsigned';
  static const String productsPreset = 'products_unsigned';

  /// Upload image bytes to Cloudinary using unsigned upload
  ///
  /// Parameters:
  /// - [imageBytes]: Image data to upload
  /// - [uploadPreset]: Cloudinary upload preset name
  /// - [publicId]: Optional custom publicId for the uploaded image
  /// - [folder]: Optional folder path (usually handled by preset)
  ///
  /// Returns the secure_url of the uploaded image
  Future<String> uploadImage({
    required Uint8List imageBytes,
    required String uploadPreset,
    String? publicId,
    String? folder,
  }) async {
    try {
      debugPrint('📤 Cloudinary upload started');
      debugPrint('   Preset: $uploadPreset');
      debugPrint('   PublicId: ${publicId ?? "auto"}');
      debugPrint('   Image size: ${imageBytes.length} bytes');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add required fields
      request.fields['upload_preset'] = uploadPreset;

      // Add optional fields
      if (publicId != null && publicId.isNotEmpty) {
        request.fields['public_id'] = publicId;
      }
      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'upload.jpg',
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Cloudinary response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final secureUrl = jsonResponse['secure_url'] as String;

        debugPrint('✅ Upload successful');
        debugPrint('   URL: $secureUrl');

        return secureUrl;
      } else {
        final errorBody = response.body;
        debugPrint('❌ Upload failed: ${response.statusCode}');
        debugPrint('   Error: $errorBody');
        throw CloudinaryException(
          'Upload failed with status ${response.statusCode}: $errorBody',
        );
      }
    } catch (e) {
      debugPrint('❌ Cloudinary upload error: $e');
      if (e is CloudinaryException) {
        rethrow;
      }
      throw CloudinaryException('Failed to upload image: $e');
    }
  }

  /// Upload user avatar
  /// Uses letsplay_prod preset with userId as publicId
  Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String userId,
  }) async {
    return uploadImage(
      imageBytes: imageBytes,
      uploadPreset: avatarPreset,
      publicId: userId,
    );
  }

  /// Upload product image
  /// Uses products_unsigned preset with productId as publicId
  Future<String> uploadProductImage({
    required Uint8List imageBytes,
    required String productId,
  }) async {
    return uploadImage(
      imageBytes: imageBytes,
      uploadPreset: productsPreset,
      publicId: productId,
    );
  }

  /// Upload field image
  /// Uses fields_unsigned preset with auto-generated publicId
  Future<String> uploadFieldImage({required Uint8List imageBytes}) async {
    return uploadImage(
      imageBytes: imageBytes,
      uploadPreset: fieldsPreset,
      // No publicId - will be auto-generated
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
