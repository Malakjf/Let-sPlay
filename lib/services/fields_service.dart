import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FieldsService extends ChangeNotifier {
  FieldsService._internal();
  static final FieldsService _instance = FieldsService._internal();
  factory FieldsService() => _instance;

  final List<Map<String, dynamic>> _fields = [];
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<Map<String, dynamic>> get fields => List.unmodifiable(_fields);

  void addField(Map<String, dynamic> field) {
    final f = Map<String, dynamic>.from(field);
    f['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    _fields.insert(0, f);
    notifyListeners();
  }

  void setFields(List<Map<String, dynamic>> list) {
    _fields
      ..clear()
      ..addAll(list.map((e) => Map<String, dynamic>.from(e)));
    notifyListeners();
  }

  void clear() {
    _fields.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getAllFields() {
    return List.unmodifiable(_fields);
  }

  void updateField(Map<String, dynamic> updatedField) {
    // Preserve the original ID if not present
    updatedField['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();

    // Find the existing field by ID or create a new one
    final existingIndex = _fields.indexWhere(
      (field) =>
          field['id'] == updatedField['id'] ||
          field['name'] == updatedField['name'],
    );

    if (existingIndex != -1) {
      _fields[existingIndex] = Map<String, dynamic>.from(updatedField);
    } else {
      _fields.insert(0, Map<String, dynamic>.from(updatedField));
    }
    notifyListeners();
  }

  void deleteField(dynamic identifier) {
    if (identifier is Map<String, dynamic>) {
      // If it's a field object, remove by reference or ID
      _fields.removeWhere(
        (f) => f == identifier || f['id'] == identifier['id'],
      );
    } else if (identifier is String) {
      // If it's a string identifier (ID or name)
      _fields.removeWhere(
        (f) => f['id'] == identifier || f['name'] == identifier,
      );
    }
    notifyListeners();
  }

  // Additional helper methods
  Map<String, dynamic>? getFieldById(String id) {
    try {
      return _fields.firstWhere((field) => field['id'] == id);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> searchFields(String query) {
    if (query.trim().isEmpty) return List.unmodifiable(_fields);

    final searchTerm = query.toLowerCase().trim();
    return _fields.where((field) {
      final name = (field['name'] ?? '').toString().toLowerCase();
      final location = (field['location'] ?? '').toString().toLowerCase();

      return name.contains(searchTerm) || location.contains(searchTerm);
    }).toList();
  }

  // Firestore integration methods
  Future<void> loadFieldsFromFirestore() async {
    try {
      final fieldsData = await _firebaseService.getFields();
      _fields
        ..clear()
        ..addAll(fieldsData);
      notifyListeners();
    } catch (e) {
      print('Error loading fields from Firestore: $e');
    }
  }

  Future<void> saveFieldToFirestore(Map<String, dynamic> field) async {
    try {
      await _firebaseService.saveField(field);
      // Update local list if not already present
      final fieldId = field['id'];
      final existingIndex = _fields.indexWhere((f) => f['id'] == fieldId);
      if (existingIndex == -1) {
        _fields.insert(0, field);
        notifyListeners();
      }
    } catch (e) {
      print('Error saving field to Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateFieldInFirestore(
    String fieldId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firebaseService.updateField(fieldId, updates);
      // Update local list
      final existingIndex = _fields.indexWhere((f) => f['id'] == fieldId);
      if (existingIndex != -1) {
        _fields[existingIndex] = {..._fields[existingIndex], ...updates};
        notifyListeners();
      }
    } catch (e) {
      print('Error updating field in Firestore: $e');
      rethrow;
    }
  }

  Future<void> deleteFieldFromFirestore(String fieldId) async {
    try {
      await _firebaseService.deleteField(fieldId);
      _fields.removeWhere((f) => f['id'] == fieldId);
      notifyListeners();
    } catch (e) {
      print('Error deleting field from Firestore: $e');
      rethrow;
    }
  }
}
