import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/field.dart';

/// Repository for managing fields in Firestore
class FieldRepository {
  FieldRepository._internal();
  static final FieldRepository instance = FieldRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionName = 'fields';

  /// Get all fields
  Future<List<Field>> getAllFields() async {
    try {
      debugPrint('⚽ Loading all fields');
      final snapshot = await _db
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      final fields = snapshot.docs
          .map((doc) => Field.fromFirestore(doc.data(), doc.id))
          .toList();

      debugPrint('✅ Loaded ${fields.length} fields');
      return fields;
    } catch (e) {
      debugPrint('❌ Error loading fields: $e');
      rethrow;
    }
  }

  /// Get a single field by ID
  Future<Field?> getField(String fieldId) async {
    try {
      debugPrint('⚽ Loading field: $fieldId');
      final doc = await _db.collection(_collectionName).doc(fieldId).get();

      if (!doc.exists) {
        debugPrint('⚠️ Field not found');
        return null;
      }

      final field = Field.fromFirestore(doc.data()!, doc.id);
      debugPrint('✅ Field loaded');
      return field;
    } catch (e) {
      debugPrint('❌ Error loading field: $e');
      rethrow;
    }
  }

  /// Create a new field
  Future<String> createField(Field field) async {
    try {
      debugPrint('⚽ Creating field: ${field.name}');
      final docRef = await _db
          .collection(_collectionName)
          .add(field.toFirestore());

      debugPrint('✅ Field created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating field: $e');
      rethrow;
    }
  }

  /// Update an existing field
  Future<void> updateField(Field field) async {
    try {
      debugPrint('⚽ Updating field: ${field.id}');
      await _db
          .collection(_collectionName)
          .doc(field.id)
          .update(field.toFirestore());

      debugPrint('✅ Field updated');
    } catch (e) {
      debugPrint('❌ Error updating field: $e');
      rethrow;
    }
  }

  /// Delete a field
  Future<void> deleteField(String fieldId) async {
    try {
      debugPrint('⚽ Deleting field: $fieldId');
      await _db.collection(_collectionName).doc(fieldId).delete();

      debugPrint('✅ Field deleted');
    } catch (e) {
      debugPrint('❌ Error deleting field: $e');
      rethrow;
    }
  }

  /// Add image to field's images array
  Future<void> addFieldImage(String fieldId, String imageUrl) async {
    try {
      debugPrint('⚽ Adding image to field: $fieldId');
      await _db.collection(_collectionName).doc(fieldId).update({
        'images': FieldValue.arrayUnion([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Image added to field');
    } catch (e) {
      debugPrint('❌ Error adding field image: $e');
      rethrow;
    }
  }

  /// Remove image from field's images array
  Future<void> removeFieldImage(String fieldId, String imageUrl) async {
    try {
      debugPrint('⚽ Removing image from field: $fieldId');
      await _db.collection(_collectionName).doc(fieldId).update({
        'images': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Image removed from field');
    } catch (e) {
      debugPrint('❌ Error removing field image: $e');
      rethrow;
    }
  }

  /// Update field images array completely
  Future<void> updateFieldImages(String fieldId, List<String> images) async {
    try {
      debugPrint('⚽ Updating field images: $fieldId');
      await _db.collection(_collectionName).doc(fieldId).update({
        'images': images,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Field images updated');
    } catch (e) {
      debugPrint('❌ Error updating field images: $e');
      rethrow;
    }
  }

  /// Get fields stream for real-time updates
  Stream<List<Field>> getFieldsStream() {
    return _db
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Field.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }
}
