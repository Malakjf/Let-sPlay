import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Joins a match securely using a transaction.
  /// Updates both the subcollection (for records) and the array (for UI/Store compatibility).
  Future<void> joinMatch(String matchId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('You must be logged in to join a match.');

    final matchRef = _firestore.collection('matches').doc(matchId);
    final playerRef = matchRef.collection('players').doc(user.uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final matchSnapshot = await transaction.get(matchRef);

        if (!matchSnapshot.exists) {
          throw Exception('Match does not exist.');
        }

        final data = matchSnapshot.data()!;
        final status = data['status'] as String? ?? 'closed';
        final currentPlayers = data['playersCount'] as int? ?? 0;
        final maxPlayers = data['maxPlayers'] as int? ?? 0;
        final playersList = List<String>.from(data['players'] ?? []);

        // 1. Validation Checks
        if (status != 'open') {
          throw Exception('This match is no longer open.');
        }
        if (currentPlayers >= maxPlayers) {
          throw Exception('This match is full.');
        }
        if (playersList.contains(user.uid)) {
          throw Exception('You have already joined this match.');
        }

        // 2. Execute Writes
        // Add to subcollection (matches your requested structure)
        transaction.set(playerRef, {
          'joinedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });

        // Update parent document (keeps PlayerStatsStore working)
        transaction.update(matchRef, {
          'playersCount': FieldValue.increment(1),
          'players': FieldValue.arrayUnion([user.uid]),
        });
      });
      debugPrint('✅ Successfully joined match $matchId');
    } catch (e) {
      debugPrint('❌ Error joining match: $e');
      rethrow; // Let UI handle the error
    }
  }
}