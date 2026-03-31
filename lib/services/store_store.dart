import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class StoreStore extends ChangeNotifier {
  StoreStore._internal() {
    // 🔒 Only listen to Firestore if user is authenticated
    _initializeStore();
  }
  
  /// 🔒 Initialize store - only if user is authenticated
  Future<void> _initializeStore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Guest mode - not listening to store Firestore');
      _isLoading = false;
      notifyListeners();
      return;
    }
    // User is authenticated, start listening
    _listenToStoreItems();
  }
  
  static final StoreStore instance = StoreStore._internal();

  List<Map<String, dynamic>> _items = [];
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  final FirebaseService _firebaseService = FirebaseService.instance;
  bool _isLoading = true;

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  /// 🔒 Check if user is authenticated before operations
  bool get _isAuthenticated => FirebaseAuth.instance.currentUser != null;

  Future<void> addItem(Map<String, dynamic> item) async {
    // 🔒 Guard: Check authentication
    if (!_isAuthenticated) {
      debugPrint('⚠️ Guest mode - cannot add store item');
      return;
    }
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
    // 🔒 Double-check authentication before listening
    if (!_isAuthenticated) {
      debugPrint('⚠️ Guest mode - not listening to store Firestore');
      _isLoading = false;
      notifyListeners();
      return;
    }
    
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

  /// 🔒 Re-start listening after login
  void startListening() {
    if (_isAuthenticated && _subscription == null) {
      _listenToStoreItems();
    }
  }

  /// 🛑 Stop listening and clear data (e.g. on logout)
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _items = [];
    _isLoading = true;
    notifyListeners();
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    // 🔒 Guard: Check authentication
    if (!_isAuthenticated) {
      debugPrint('⚠️ Guest mode - cannot update store item');
      return;
    }
    try {
      await _firebaseService.updateStoreItem(itemId, updates);
      // Firestore stream will update local list
    } catch (e) {
      print('Error updating store item: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    // 🔒 Guard: Check authentication
    if (!_isAuthenticated) {
      debugPrint('⚠️ Guest mode - cannot delete store item');
      return;
    }
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
