import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  String? _userId;
  String? get userId => _userId;

  AuthProvider(this._firebaseService);

  Future<void> checkAuthStatus() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final user = _firebaseService.currentUser;
      _isAuthenticated = user != null;

      if (_isAuthenticated) {
        _userId = user!.uid;
        print('✅ User IS authenticated - showing main MaterialApp');
        print('   User ID: $_userId');
        print('   Email: ${user.email}');

        // Get user data
        _userData = await _firebaseService.getCurrentUserData();
      } else {
        print('❌ User NOT authenticated - showing login screen');
      }

      _error = null;
    } catch (e) {
      print('❌ Error checking auth status: $e');
      _error = e.toString();
      _isAuthenticated = false;
      _userData = null;
      _userId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firebaseService.signInWithEmailAndPassword(email, password);

      final user = _firebaseService.currentUser;
      if (user != null) {
        _isAuthenticated = true;
        _userId = user.uid;
        _userData = await _firebaseService.getCurrentUserData();
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      _userData = null;
      _userId = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.signOut();
      _isAuthenticated = false;
      _userData = null;
      _userId = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
