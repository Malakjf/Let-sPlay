import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FieldStore extends ChangeNotifier {
  FieldStore._internal() {
    // Auto-load fields on initialization
    loadFieldsFromFirestore();
  }
  static final FieldStore instance = FieldStore._internal();

  final List<Map<String, dynamic>> _fields = [];
  final FirebaseService _firebaseService = FirebaseService.instance;
  bool _isLoading = false;

  List<Map<String, dynamic>> get fields => List.unmodifiable(_fields);
  bool get isLoading => _isLoading;

  Future<void> addField(Map<String, dynamic> field) async {
    try {
      // Add ID if not present
      field['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();

      // Save to Firestore
      await _firebaseService.saveField(field);

      // Update local list
      _fields.insert(0, field);
      notifyListeners();
    } catch (e) {
      print('Error adding field: $e');
      rethrow;
    }
  }

  Future<void> loadFieldsFromFirestore() async {
    if (_isLoading) return; // Prevent concurrent loads

    _isLoading = true;
    notifyListeners();

    try {
      final fieldsData = await _firebaseService.getFields();
      _fields.clear();
      _fields.addAll(fieldsData);
      debugPrint(
        '✅ FieldStore: Loaded ${_fields.length} fields from Firestore',
      );
    } catch (e) {
      debugPrint('❌ Error loading fields from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateField(String fieldId, Map<String, dynamic> updates) async {
    try {
      await _firebaseService.updateField(fieldId, updates);

      // Update local list
      final index = _fields.indexWhere((f) => f['id'] == fieldId);
      if (index != -1) {
        _fields[index] = {..._fields[index], ...updates};
        notifyListeners();
      }
    } catch (e) {
      print('Error updating field: $e');
      rethrow;
    }
  }

  Future<void> deleteField(String fieldId) async {
    try {
      await _firebaseService.deleteField(fieldId);
      _fields.removeWhere((f) => f['id'] == fieldId);
      notifyListeners();
    } catch (e) {
      print('Error deleting field: $e');
      rethrow;
    }
  }
}
