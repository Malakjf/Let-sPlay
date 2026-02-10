import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance =
      FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload multiple images to Firebase Storage
  Future<List<String>> uploadFieldImages(
    List<dynamic> images,
    String fieldName,
  ) async {
    if (images.isEmpty) return [];

    final List<String> urls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFieldName = fieldName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    for (int i = 0; i < images.length; i++) {
      try {
        final fileName = 'field_${cleanFieldName}_${timestamp}_$i.jpg';
        final path = 'field_photos/$fileName';
        final photo = images[i];

        UploadTask uploadTask;

        if (kIsWeb && photo is Uint8List) {
          // Web upload from bytes
          uploadTask = _storage
              .ref()
              .child(path)
              .putData(
                photo,
                SettableMetadata(
                  contentType: 'image/jpeg',
                  customMetadata: {
                    'field_name': fieldName,
                    'upload_timestamp': timestamp.toString(),
                    'image_index': i.toString(),
                  },
                ),
              );
        } else {
          // Mobile/Desktop upload from file
          final filePath = photo as String;
          final file = File(filePath);
          uploadTask = _storage
              .ref()
              .child(path)
              .putFile(
                file,
                SettableMetadata(
                  contentType: 'image/jpeg',
                  customMetadata: {
                    'field_name': fieldName,
                    'upload_timestamp': timestamp.toString(),
                    'image_index': i.toString(),
                  },
                ),
              );
        }

        // Wait for upload to complete
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        urls.add(downloadUrl);

        if (kDebugMode) {
          print('✅ Uploaded image $i: $downloadUrl');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to upload image $i: $e');
        }
        urls.add(''); // Add empty string for failed upload
      }
    }

    return urls;
  }
}
