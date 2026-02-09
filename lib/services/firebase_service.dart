import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/role_request.dart';
import 'firestore_readiness_guard.dart';

class FirebaseService {
  /// Real-time stream of store items (active only)
  Stream<List<Map<String, dynamic>>> storeItemsStream({
    bool onlyActive = true,
  }) {
    Query q = _db.collection('store');
    if (onlyActive) q = q.where('active', isEqualTo: true);
    return q.snapshots().map(
      (snap) => snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        data['id'] = d.id;
        return data;
      }).toList(),
    );
  }

  /// Adds a participant to a match with correct status and joinType
  Future<void> addParticipantToMatch({
    required String matchId,
    required String userId,
    required bool isFull,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    // Backwards-compatible helper kept for legacy callers.
    // Prefer using `joinMatchTransaction` which uses `players` and `waitingList`.
    final matchRef = _db.collection('matches').doc(matchId);
    final matchDoc = await matchRef.get();
    if (!matchDoc.exists) throw Exception('Match not found');
    final matchData = matchDoc.data()!;
    final participants = List<Map<String, dynamic>>.from(
      matchData['participants'] ?? [],
    );

    if (participants.any((p) => p['userId'] == userId)) {
      throw Exception('User already requested to join');
    }

    final now = DateTime.now().toUtc();
    final participant = {
      'userId': userId,
      'status': isFull ? 'waiting' : 'pending',
      'joinType': isFull ? 'waiting' : 'join',
      'joinTimestamp': now.toIso8601String(),
      'hasPaid': false,
    };
    participants.add(participant);
    await matchRef.update({'participants': participants});
  }

  /// Transactional join using new structure: `players` and `waitingList`.
  /// If there's room, userId is added to `players` (String array).
  /// Otherwise an entry is appended to `waitingList` with server timestamp.
  Future<void> joinMatchTransaction({
    required String matchId,
    required String userId,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) throw Exception('Match not found');
      final data = snapshot.data()!;

      final players = List<String>.from(data['players'] ?? []);
      final waiting = List<Map<String, dynamic>>.from(
        data['waitingList'] ?? [],
      );

      // Prevent duplicates
      if (players.contains(userId) ||
          waiting.any((w) => w['userId'] == userId)) {
        throw Exception('User already requested to join');
      }

      final maxPlayers = safeInt(
        data['maxPlayers'] ?? data['maxParticipants'] ?? 0,
      );

      if (maxPlayers > 0 && players.length >= maxPlayers) {
        // Add to waiting list with server timestamp
        waiting.add({
          'userId': userId,
          'joinedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(matchRef, {'waitingList': waiting});
      } else {
        players.add(userId);
        transaction.update(matchRef, {
          'players': players,
          'playersCount': players.length,
        });
      }
    });
  }

  /// Approve a user from waiting list and move them to players atomically.
  Future<void> approveWaitingParticipant({
    required String matchId,
    required String userId,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) throw Exception('Match not found');
      final data = snapshot.data()!;

      final players = List<String>.from(data['players'] ?? []);
      final waiting = List<Map<String, dynamic>>.from(
        data['waitingList'] ?? [],
      );

      // Ensure user is in waiting list
      final wIdx = waiting.indexWhere((w) => w['userId'] == userId);
      if (wIdx == -1) throw Exception('User not in waiting list');

      final maxPlayers = safeInt(
        data['maxPlayers'] ?? data['maxParticipants'] ?? 0,
      );
      if (maxPlayers > 0 && players.length >= maxPlayers) {
        throw Exception('Match is full');
      }

      // Remove from waiting and add to players (prevent duplicates)
      waiting.removeAt(wIdx);
      if (!players.contains(userId)) players.add(userId);

      transaction.update(matchRef, {
        'waitingList': waiting,
        'players': players,
        'playersCount': players.length,
      });
    });
  }

  /// Reject (remove) a user from waiting list.
  Future<void> rejectWaitingParticipant({
    required String matchId,
    required String userId,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) throw Exception('Match not found');
      final data = snapshot.data()!;

      final waiting = List<Map<String, dynamic>>.from(
        data['waitingList'] ?? [],
      );
      final players = List<String>.from(data['players'] ?? []);

      final wIdx = waiting.indexWhere((w) => w['userId'] == userId);
      if (wIdx == -1) throw Exception('User not in waiting list');

      waiting.removeAt(wIdx);
      // Ensure also not in players
      if (players.contains(userId)) players.remove(userId);

      transaction.update(matchRef, {
        'waitingList': waiting,
        'players': players,
        'playersCount': players.length,
      });
    });
  }

  /// Remove a confirmed player from `players` list.
  Future<void> removePlayer({
    required String matchId,
    required String userId,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(matchRef);
      if (!snapshot.exists) throw Exception('Match not found');
      final data = snapshot.data()!;

      final players = List<String>.from(data['players'] ?? []);
      if (!players.contains(userId)) throw Exception('Player not found');

      players.remove(userId);
      transaction.update(matchRef, {
        'players': players,
        'playersCount': players.length,
      });
    });
  }

  /// Organizer confirms a participant (moves to confirmed and adds to players array)
  Future<void> confirmParticipant({
    required String matchId,
    required String userId,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);
    final matchDoc = await matchRef.get();
    if (!matchDoc.exists) throw Exception('Match not found');
    final matchData = matchDoc.data()!;
    final participants = List<Map<String, dynamic>>.from(
      matchData['participants'] ?? [],
    );
    final players = List<String>.from(matchData['players'] ?? []);

    // Find participant
    final idx = participants.indexWhere((p) => p['userId'] == userId);
    if (idx == -1) throw Exception('Participant not found');
    participants[idx]['status'] = 'confirmed';
    if (!players.contains(userId)) players.add(userId);
    await matchRef.update({
      'participants': participants,
      'players': players,
      'playersCount': players.length,
    });
  }

  /// Organizer can reject/remove a participant
  Future<void> rejectParticipant({
    required String matchId,
    required String userId,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);
    final matchDoc = await matchRef.get();
    if (!matchDoc.exists) throw Exception('Match not found');
    final matchData = matchDoc.data()!;
    final participants = List<Map<String, dynamic>>.from(
      matchData['participants'] ?? [],
    );
    final players = List<String>.from(matchData['players'] ?? []);

    final idx = participants.indexWhere((p) => p['userId'] == userId);
    if (idx == -1) throw Exception('Participant not found');
    participants[idx]['status'] = 'rejected';

    if (players.contains(userId)) players.remove(userId);

    await matchRef.update({
      'participants': participants,
      'players': players,
      'playersCount': players.length,
    });
  }

  /// Updates the payment status of a participant (Organizer/Admin only)
  /// This is the Single Source of Truth for payment state.
  Future<void> updateParticipantPaymentStatus({
    required String matchId,
    required String userId,
    required bool hasPaid,
  }) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchRef = _db.collection('matches').doc(matchId);
    final matchDoc = await matchRef.get();
    if (!matchDoc.exists) throw Exception('Match not found');

    final matchData = matchDoc.data()!;
    final participants = List<Map<String, dynamic>>.from(
      matchData['participants'] ?? [],
    );

    final idx = participants.indexWhere((p) => p['userId'] == userId);
    if (idx == -1) throw Exception('Participant not found');

    participants[idx]['hasPaid'] = hasPaid;

    await matchRef.update({'participants': participants});
  }

  /// Get confirmed players for Players page
  Future<List<String>> getConfirmedPlayers(String matchId) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchDoc = await _db.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return [];
    final matchData = matchDoc.data()!;
    final participants = List<Map<String, dynamic>>.from(
      matchData['participants'] ?? [],
    );
    return participants
        .where((p) => p['status'] == 'confirmed')
        .map((p) => p['userId'] as String)
        .toList();
  }

  /// Get all participants for management page
  Future<List<Map<String, dynamic>>> getAllParticipants(String matchId) async {
    _requireNonEmptyId(matchId, 'matchId');
    final matchDoc = await _db.collection('matches').doc(matchId).get();
    if (!matchDoc.exists) return [];
    final matchData = matchDoc.data()!;
    return List<Map<String, dynamic>>.from(matchData['participants'] ?? []);
  }

  FirebaseService._internal();
  static final FirebaseService instance = FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _readinessGuard = FirestoreReadinessGuard.instance;

  /// Safe read with automatic retry and connection check
  Future<T> _safeFirestoreRead<T>({
    required Future<T> Function() operation,
    required T Function() fallback,
  }) async {
    try {
      await _readinessGuard.ensureReady();
      return await operation().timeout(const Duration(seconds: 10));
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('⚠️ Firestore unavailable, re-handshaking...');
        await _readinessGuard.reHandshake();
        try {
          return await operation().timeout(const Duration(seconds: 10));
        } catch (e2) {
          debugPrint('❌ Retry failed: $e2');
          // Force re-handshake before fallback to clear sticky offline state
          await _readinessGuard.reHandshake();
        }
      } else if (e.code == 'permission-denied') {
        debugPrint('❌ Permission denied: ${e.message}');
        rethrow;
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Firestore operation timed out: $e');
      // Fallback will be used
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
    }
    return fallback();
  }

  /* ================= SAFE PARSING HELPERS ================= */

  static int safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static double safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Ensure IDs used for document paths are non-empty. If a candidate is
  // falsy or an empty string, generate a timestamp-based id instead.
  static String _normalizeOrCreateId(dynamic candidate) {
    final s = candidate?.toString().trim() ?? '';
    return s.isNotEmpty ? s : DateTime.now().millisecondsSinceEpoch.toString();
  }

  static void _requireNonEmptyId(String id, String name) {
    if (id.trim().isEmpty) {
      throw ArgumentError('$name must be a non-empty string');
    }
  }

  /* ================= AUTH ================= */

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await ensureUserDoc();
    return cred;
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await saveUserData(cred.user!.uid, {
      'uid': cred.user!.uid,
      'email': email.toLowerCase(),
      'username': email.split('@')[0],
      'name': email.split('@')[0],
      'role': 'Player',
      'walletCredit': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  Future<void> signOut() async => _auth.signOut();

  /* ================= USER CORE ================= */

  Future<Map<String, dynamic>> getUserData(String uid) async {
    _requireNonEmptyId(uid, 'uid');
    debugPrint('📥 Fetching user data for: $uid');

    return _safeFirestoreRead(
      operation: () async {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .get(
              // Use serverAndCache - lets SDK choose best source
              const GetOptions(source: Source.serverAndCache),
            );

        if (doc.exists && doc.data() != null) {
          debugPrint(
            '✅ User data loaded from ${doc.metadata.isFromCache ? "cache" : "server"}',
          );
          debugPrint('📊 Role: ${doc.data()!['role']}');
          return doc.data()!;
        }

        debugPrint('⚠️ Document does not exist');
        return {};
      },
      fallback: () {
        debugPrint('📦 Using default user data');
        return _getDefaultUserData(uid);
      },
    );
  }

  Map<String, dynamic> _getDefaultUserData(String uid) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';

    debugPrint('🔧 Creating default data for: $email');

    return {
      'uid': uid,
      'email': email,
      'username': email.split('@')[0],
      'name': email.split('@')[0],
      'role': email.toLowerCase() == 'letsplaysup2025@gmail.com'
          ? 'Admin'
          : 'Player',
      'walletCredit': 0.0,
      'goals': 0,
      'assists': 0,
      'motm': 0,
      'matches': 0,
      'level': 1,
      'rating': 0,
      'yellowCards': 0,
      'redCards': 0,
      'metrics': {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0},
      'badges': [],
      'avatarUrl': '',
      'countryFlagUrl': '',
      'position': 'ST',
      'club': '',
      'nationality': '',
    };
  }

  Future<void> ensureUserDoc() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No current user');
      return;
    }

    Future<void> performCheck() async {
      final ref = _db.collection('users').doc(user.uid);
      final snap = await ref.get().timeout(const Duration(seconds: 5));

      if (!snap.exists) {
        debugPrint('📝 Creating user document...');
        await ref.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'username': user.email?.split('@')[0] ?? 'Player',
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'Player',
          'role': user.email?.toLowerCase() == 'letsplaysup2025@gmail.com'
              ? 'Admin'
              : 'Player',
          'walletCredit': 0.0,
          'goals': 0,
          'assists': 0,
          'motm': 0,
          'matches': 0,
          'level': 1,
          'rating': 0,
          'yellowCards': 0,
          'redCards': 0,
          'metrics': {
            'PAC': 0,
            'SHO': 0,
            'PAS': 0,
            'DRI': 0,
            'DEF': 0,
            'PHY': 0,
          },
          'badges': [],
          'avatarUrl': '',
          'countryFlagUrl': '',
          'position': 'ST',
          'club': '',
          'nationality': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to be safe
      } else {
        // Check for missing fields
        final data = snap.data() ?? {};
        Map<String, dynamic> updates = {};
        if (!data.containsKey('metrics')) {
          updates['metrics'] = {
            'PAC': 0,
            'SHO': 0,
            'PAS': 0,
            'DRI': 0,
            'DEF': 0,
            'PHY': 0,
          };
        }
        if (updates.isNotEmpty) {
          await ref.set(updates, SetOptions(merge: true));
        }
      }
    }

    try {
      await _readinessGuard.ensureReady();
      await performCheck();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        debugPrint('⚠️ ensureUserDoc unavailable, re-handshaking...');
        await _readinessGuard.reHandshake();
        try {
          await performCheck();
        } catch (e) {
          debugPrint('⚠️ ensureUserDoc retry failed: $e');
        }
      } else {
        debugPrint('⚠️ ensureUserDoc failed: $e');
      }
    } catch (e) {
      debugPrint('⚠️ ensureUserDoc error: $e');
    }
  }

  Future<String> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('⚠️ No current user for role check');
      return 'Player';
    }

    try {
      final data = await getUserData(user.uid);
      final role = data['role'] ?? 'Player';
      debugPrint('👤 Current user role: $role');
      return role;
    } catch (e) {
      debugPrint('❌ getCurrentUserRole error: $e');
      return 'Player';
    }
  }

  Future<void> ensureUserHasPlayerFields(String userId) async {
    _requireNonEmptyId(userId, 'userId');
    try {
      final ref = _db.collection('users').doc(userId);
      final snap = await ref.get().timeout(const Duration(seconds: 5));

      if (!snap.exists) {
        debugPrint('⚠️ User doc does not exist');
        return;
      }

      final data = snap.data();
      if (data == null) return;

      if (data['metrics'] == null) {
        await ref
            .update({
              'metrics': {
                'PAC': 0,
                'SHO': 0,
                'PAS': 0,
                'DRI': 0,
                'DEF': 0,
                'PHY': 0,
              },
            })
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('⚠️ ensureUserHasPlayerFields failed: $e (non-critical)');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    return getUserData(user.uid);
  }

  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    _requireNonEmptyId(userId, 'userId');
    await _db.collection('users').doc(userId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    _requireNonEmptyId(uid, 'uid');
    await saveUserData(uid, updates);
  }

  Future<void> updateUserRole(String uid, String role) async {
    _requireNonEmptyId(uid, 'uid');
    await updateUserData(uid, {'role': role});
  }

  Future<void> updateUserWallet(String uid, num value) async {
    _requireNonEmptyId(uid, 'uid');
    await updateUserData(uid, {'walletCredit': value});
  }

  /// Create a set of test users in Firestore.
  ///
  /// Call `FirebaseService.instance.createTestUsers()` from debug code to
  /// populate the `users` collection with sample accounts for local testing.
  Future<List<String>> createTestUsers([
    List<Map<String, String>>? users,
  ]) async {
    final sample =
        users ??
        [
          {
            'uid': 'test_player_1',
            'email': 'player1@example.com',
            'username': 'player1',
            'name': 'Player One',
            'role': 'Player',
          },
          {
            'uid': 'test_player_2',
            'email': 'player2@example.com',
            'username': 'player2',
            'name': 'Player Two',
            'role': 'Player',
          },
          {
            'uid': 'test_organizer',
            'email': 'organizer@example.com',
            'username': 'organizer',
            'name': 'Organizer',
            'role': 'Organizer',
          },
          {
            'uid': 'test_admin',
            'email': 'admin@example.com',
            'username': 'admin',
            'name': 'Admin User',
            'role': 'Admin',
          },
        ];

    final created = <String>[];
    for (final u in sample) {
      final rawUid = u['uid'] ?? u['email']?.split('@').first ?? '';
      final uid = _normalizeOrCreateId(rawUid);

      final data = {
        'uid': uid,
        'email': u['email'] ?? '',
        'username': u['username'] ?? uid,
        'name': u['name'] ?? uid,
        'role': u['role'] ?? 'Player',
        'walletCredit': 0.0,
        'metrics': {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0},
        'badges': [],
        'avatarUrl': '',
        'countryFlagUrl': '',
        'position': 'ST',
        'club': '',
        'nationality': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      created.add(uid);
    }

    return created;
  }

  Future<List<Map<String, dynamic>>> getAllUsers({int limit = 200}) async {
    try {
      final snap = await _db.collection('users').limit(limit).get();
      return snap.docs.map((d) {
        final data = d.data();
        data['uid'] = d.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ getAllUsers error: $e');
      return [];
    }
  }

  /* ================= MATCHES ================= */

  Future<void> saveMatch(Map<String, dynamic> match) async {
    final id = _normalizeOrCreateId(match['id']);
    await _db.collection('matches').doc(id).set({
      ...match,
      'id': id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getMatches() async {
    return _safeFirestoreRead(
      operation: () async {
        final snap = await _db
            .collection('matches')
            .get()
            .timeout(const Duration(seconds: 10));
        return snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return data;
        }).toList();
      },
      fallback: () {
        debugPrint('📦 Returning empty matches list');
        return [];
      },
    );
  }

  Future<Map<String, dynamic>?> getMatch(String matchId) async {
    try {
      _requireNonEmptyId(matchId, 'matchId');
      final doc = await _db.collection('matches').doc(matchId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('❌ getMatch error: $e');
      return null;
    }
  }

  Future<void> updateMatch(String id, Map<String, dynamic> data) async {
    _requireNonEmptyId(id, 'id');
    await _db.collection('matches').doc(id).update(data);
  }

  Future<void> deleteMatch(String id) async {
    _requireNonEmptyId(id, 'id');
    await _db.collection('matches').doc(id).delete();
  }

  /* ================= FIELDS ================= */

  Future<void> saveField(Map<String, dynamic> field) async {
    final id = _normalizeOrCreateId(field['id']);

    debugPrint('💾 Saving field to Firestore...');
    debugPrint('📝 Field ID: $id');
    debugPrint('📝 Field name: ${field['name']}');
    debugPrint('🔐 Current user: ${_auth.currentUser?.uid}');

    Future<void> performSave() async {
      await _db
          .collection('fields')
          .doc(id)
          .set({
            ...field,
            'id': id,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 30));
    }

    try {
      await _readinessGuard.ensureReady();
      await performSave();
      debugPrint('✅ Field saved successfully');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Permission denied. Only Organizers and Admins can create fields.',
        );
      }
      if (e.code == 'unavailable') {
        debugPrint('⚠️ Connection unavailable, re-handshaking...');
        await _readinessGuard.reHandshake();
        try {
          await performSave();
          debugPrint('✅ Field saved successfully (after retry)');
        } catch (e2) {
          throw Exception(
            'Unable to connect to Firebase. Please check your internet connection.',
          );
        }
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error saving field: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFields() async {
    return _safeFirestoreRead(
      operation: () async {
        final snap = await _db
            .collection('fields')
            .get()
            .timeout(const Duration(seconds: 10));
        return snap.docs.map((e) => e.data()).toList();
      },
      fallback: () {
        debugPrint('📦 Returning empty fields list');
        return [];
      },
    );
  }

  Future<void> updateField(String id, Map<String, dynamic> data) async {
    _requireNonEmptyId(id, 'id');
    await _db.collection('fields').doc(id).update(data);
  }

  Future<void> deleteField(String id) async {
    _requireNonEmptyId(id, 'id');
    await _db.collection('fields').doc(id).delete();
  }

  /* ================= STORE ================= */

  Future<void> saveStoreItem(Map<String, dynamic> data) async {
    await _db.collection('store').add({
      'active': true,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getStoreItems({
    bool onlyActive = true,
  }) async {
    return _safeFirestoreRead(
      operation: () async {
        Query q = _db.collection('store');
        if (onlyActive) q = q.where('active', isEqualTo: true);

        final snap = await q
            .orderBy('createdAt', descending: true)
            .get()
            .timeout(const Duration(seconds: 10));
        return snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList();
      },
      fallback: () {
        debugPrint('📦 Returning empty store items list');
        return [];
      },
    );
  }

  Future<void> updateStoreItem(String id, Map<String, dynamic> data) async {
    _requireNonEmptyId(id, 'id');
    await _db.collection('store').doc(id).update(data);
  }

  Future<void> deleteStoreItem(String id) async {
    _requireNonEmptyId(id, 'id');
    await _db.collection('store').doc(id).delete();
  }

  /* ================= ROLE REQUESTS ================= */

  Future<void> saveRoleRequest(Map<String, dynamic> data) async {
    final id = _normalizeOrCreateId(data['id']);
    await _db.collection('roleRequests').doc(id).set({
      ...data,
      'id': id,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<RoleRequest>> getRoleRequests() async {
    final snap = await _db
        .collection('roleRequests')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return RoleRequest(
        id: d.id,
        userId: data['userId'],
        userName: data['userName'],
        userEmail: data['userEmail'],
        requestedRole: data['requestedRole'],
        requestDate: (data['createdAt'] as Timestamp).toDate(),
      );
    }).toList();
  }

  Future<void> approveRoleRequest(
    String requestId,
    String userId,
    String role,
  ) async {
    // Convert role string to permissionLevel string for consistency
    String permissionLevel;
    final normalizedRole = role.toLowerCase();

    switch (normalizedRole) {
      case 'admin':
        permissionLevel = 'ADMIN';
        break;
      case 'organizer':
        permissionLevel = 'ORGANIZER';
        break;
      case 'coach':
        permissionLevel = 'COACH';
        break;
      case 'academy_player':
        permissionLevel = 'ACADEMY';
        break;
      default:
        permissionLevel = 'PLAYER';
    }

    _requireNonEmptyId(requestId, 'requestId');
    _requireNonEmptyId(userId, 'userId');

    await updateUserData(userId, {
      'role': role,
      'permissionLevel': permissionLevel,
    });
    await _db.collection('roleRequests').doc(requestId).delete();
  }

  Future<void> rejectRoleRequest(String requestId) async {
    _requireNonEmptyId(requestId, 'requestId');
    await _db.collection('roleRequests').doc(requestId).delete();
  }

  /* ================= AVATAR ================= */

  Future<String?> uploadAvatar(File file, String uid) async {
    final ref = _storage.ref('avatars/$uid.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    await updateUserData(uid, {'avatarUrl': url});
    return url;
  }
}
