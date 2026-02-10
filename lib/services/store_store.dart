import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class StoreStore extends ChangeNotifier {
  StoreStore._internal() {
    // Listen to Firestore for real-time updates
    _listenToStoreItems();
  }
  static final StoreStore instance = StoreStore._internal();

  List<Map<String, dynamic>> _items = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  final FirebaseService _firebaseService = FirebaseService.instance;
  bool _isLoading = true;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  Future<void> addItem(Map<String, dynamic> item) async {
    try {
      // Add ID if not present
      item['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();
      // Save to Firestore only (stream will update local list)
      await _firebaseService.saveStoreItem(item);
    } catch (e) {
      print('Error adding store item: $e');
      rethrow;
    }
  }

  void _listenToStoreItems() {
    _subscription?.cancel();
    _subscription = _firebaseService.storeItemsStream().listen(
      (itemsData) {
        // Sort client-side to avoid Firestore index requirements
        itemsData.sort((a, b) {
          final aVal = a['createdAt'];
          final bVal = b['createdAt'];
          if (aVal is Comparable && bVal is Comparable) {
            return bVal.compareTo(aVal); // Descending
          }
          return 0;
        });
        _items = itemsData;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Store stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firebaseService.updateStoreItem(itemId, updates);
      // Firestore stream will update local list
    } catch (e) {
      print('Error updating store item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await _firebaseService.deleteStoreItem(itemId);
      // Firestore stream will update local list
    } catch (e) {
      print('Error deleting store item: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    // Wait for initial load if still loading
    if (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    return List.unmodifiable(_items);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
