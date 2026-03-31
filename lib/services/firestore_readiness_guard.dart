import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreReadinessGuard {
  FirestoreReadinessGuard._();
  static final instance = FirestoreReadinessGuard._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _ready = false;
  Completer<void>? _completer;

  bool get isReady => _ready;

  /// 🔥 Guaranteed Web handshake
  Future<void> ensureReady({Duration timeout = const Duration(seconds: 20)}) {
    // Skip handshake on mobile (Android/iOS) as native SDKs handle connection robustly
    if (!kIsWeb) {
      _ready = true;
      return Future.value();
    }

    if (_ready) return Future.value();

    // If a handshake is already in progress, return the existing future
    if (_completer != null && !_completer!.isCompleted) {
      return _completer!.future.timeout(timeout);
    }

    _completer = Completer<void>();

    debugPrint('🔄 Waiting for Firestore handshake...');

    // Use snapshots().first on users collection to force a stream connection
    _db
        .collection('users')
        .limit(1)
        .snapshots()
        .first
        .then((_) {
          _ready = true;
          if (!_completer!.isCompleted) _completer!.complete();
          debugPrint('✅ Firestore connection established');
        })
        .catchError((e) {
          debugPrint('⚠️ Firestore handshake failed: $e');
          // Complete with error to avoid hanging
          if (!_completer!.isCompleted) _completer!.completeError(e);
          _completer = null; // Reset to allow retry
        });

    return _completer!.future.timeout(timeout);
  }

  /// 🔁 Soft reset (Web-safe)
  Future<void> reHandshake() async {
    debugPrint('🔁 Firestore re-handshake');

    _ready = false;
    _completer = null;

    try {
      await _db.disableNetwork();
      await Future.delayed(const Duration(milliseconds: 500));
      await _db.enableNetwork();
    } catch (e) {
      debugPrint('⚠️ Network cycle error: $e');
    }

    await ensureReady();
  }
}
