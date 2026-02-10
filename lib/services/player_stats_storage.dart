// ignore_for_file: empty_catches

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_helper.dart';

// Enhanced PlayerStatsStorage with Firebase + Local Storage
class PlayerStatsStorage {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save BOTH locally and to Firebase
  static Future<void> savePlayerStat(
    int matchId,
    String playerName,
    String statType,
    int value,
  ) async {
    // Save locally first (instant UI update)
    await _saveLocal(matchId, playerName, statType, value);

    // Save to Firebase (background sync)
    _saveToFirebase(matchId, playerName, statType, value);
  }

  // Load from local (fastest)
  static Future<int> getPlayerStat(
    int matchId,
    String playerName,
    String statType,
  ) async {
    // Try local storage first
    final prefs = await SharedPreferences.getInstance();
    final localValue = prefs.getString(
      _getStorageKey(matchId, playerName, statType),
    );

    if (localValue != null) {
      return int.tryParse(localValue) ?? 0;
    }

    // If local not found, try Firebase
    final firebaseValue = await _getFirebaseValue(
      matchId,
      playerName,
      statType,
    );
    if (firebaseValue != null) {
      // Cache in local storage for future fast access
      await _saveLocal(matchId, playerName, statType, firebaseValue);
      return firebaseValue;
    }

    return 0;
  }

  // Update player stat in both local and Firebase
  static Future<void> updatePlayerStat(
    int matchId,
    String playerName,
    String statType,
    int newValue,
  ) async {
    await savePlayerStat(matchId, playerName, statType, newValue);
  }

  // Load all stats for a match from Firebase
  static Future<Map<String, PlayerStats>> getAllPlayerMatchStats(
    int matchId,
  ) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('match_statistics')
          .doc('match_$matchId')
          .collection('players')
          .get();

      Map<String, PlayerStats> results = {};
      for (DocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        PlayerStats stats = PlayerStats.fromFirestore(data);
        results[stats.playerName] = stats;

        // Cache locally for faster future access
        await _cacheLocal(matchId, stats);
      }

      return results;
    } catch (e) {
      return await _loadLocalAllStats(matchId);
    }
  }

  // Clear stats for a specific match
  static Future<void> clearMatchStats(int matchId) async {
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) => key.startsWith('match_${matchId}_'),
    );
    for (String key in keys) {
      await prefs.remove(key);
    }

    // Clear Firebase
    try {
      WriteBatch batch = _firestore.batch();
      QuerySnapshot snapshot = await _firestore
          .collection('match_statistics')
          .doc('match_$matchId')
          .collection('players')
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {}
  }

  // Helper methods
  static String _getStorageKey(
    int matchId,
    String playerName,
    String statType,
  ) {
    return 'match_${matchId}_player_${playerName}_$statType';
  }

  static Future<void> _saveLocal(
    int matchId,
    String playerName,
    String statType,
    int value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getStorageKey(matchId, playerName, statType),
      value.toString(),
    );
  }

  static Future<void> _saveToFirebase(
    int matchId,
    String playerName,
    String statType,
    int value,
  ) async {
    try {
      await _firestore
          .collection('match_statistics')
          .doc('match_$matchId')
          .collection('players')
          .doc(playerName)
          .set({
            'matchId': matchId,
            'playerName': playerName,
            _statTypeToField(statType): value,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {}
  }

  static Future<int?> _getFirebaseValue(
    int matchId,
    String playerName,
    String statType,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('match_statistics')
          .doc('match_$matchId')
          .collection('players')
          .doc(playerName)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data[_statTypeToField(statType)] as int?;
      }
    } catch (e) {}
    return null;
  }

  static String _statTypeToField(String statType) {
    switch (statType) {
      case 'Goals':
        return 'goals';
      case 'Assists':
        return 'assists';
      case 'Red':
        return 'redCards';
      case 'Yellow':
        return 'yellowCards';
      case 'MOTM':
        return 'motm';
      case 'PAC':
        return 'pac';
      case 'SHO':
        return 'sho';
      case 'PAS':
        return 'pas';
      case 'DRI':
        return 'dri';
      case 'DEF':
        return 'def';
      case 'PHY':
        return 'phy';
      case 'CS':
        return 'cleanSheets';
      case 'GL':
        return 'goalsLetIn';
      case 'SAV':
        return 'saves';
      default:
        return statType.toLowerCase();
    }
  }

  static Future<void> _cacheLocal(int matchId, PlayerStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'Goals'),
      stats.goals.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'Assists'),
      stats.assists.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'Red'),
      stats.redCards.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'Yellow'),
      stats.yellowCards.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'MOTM'),
      stats.motm.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'CS'),
      stats.cleanSheets.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'GL'),
      stats.goalsLetIn.toString(),
    );
    await prefs.setString(
      _getStorageKey(matchId, stats.playerName, 'SAV'),
      stats.saves.toString(),
    );
  }

  static Future<Map<String, PlayerStats>> _loadLocalAllStats(
    int matchId,
  ) async {
    await SharedPreferences.getInstance();
    Map<String, PlayerStats> results = {};

    // This is a simplified version - in practice you'd need a more robust local storage system
    // For now, return empty map as fallback
    return results;
  }
}

// Updated PlayerStats class with Firebase support
class PlayerStats {
  final String playerName;
  final int goals;
  final int assists;
  final int redCards;
  final int yellowCards;
  final int motm;
  final int cleanSheets;
  final int goalsLetIn;
  final int saves;
  final DateTime lastUpdated;

  PlayerStats({
    required this.playerName,
    required this.goals,
    required this.assists,
    required this.redCards,
    required this.yellowCards,
    required this.motm,
    this.cleanSheets = 0,
    this.goalsLetIn = 0,
    this.saves = 0,
    required this.lastUpdated,
  });

  // Create from Firestore data
  factory PlayerStats.fromFirestore(Map<String, dynamic> data) {
    return PlayerStats(
      playerName: data['playerName'],
      goals: (data['goals'] as int?) ?? 0,
      assists: (data['assists'] as int?) ?? 0,
      redCards: (data['redCards'] as int?) ?? 0,
      yellowCards: (data['yellowCards'] as int?) ?? 0,
      motm: (data['motm'] as int?) ?? 0,
      cleanSheets: (data['cleanSheets'] as int?) ?? 0,
      goalsLetIn: (data['goalsLetIn'] as int?) ?? 0,
      saves: (data['saves'] as int?) ?? 0,
      lastUpdated: parseFirestoreDate(data['lastUpdated']),
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'goals': goals,
      'assists': assists,
      'redCards': redCards,
      'yellowCards': yellowCards,
      'motm': motm,
      'cleanSheets': cleanSheets,
      'goalsLetIn': goalsLetIn,
      'saves': saves,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from JSON
  factory PlayerStats.fromJson(Map<String, dynamic> json) {
    return PlayerStats(
      playerName: json['playerName'],
      goals: json['goals'],
      assists: json['assists'],
      redCards: json['redCards'],
      yellowCards: json['yellowCards'],
      motm: json['motm'],
      cleanSheets: json['cleanSheets'] ?? 0,
      goalsLetIn: json['goalsLetIn'] ?? 0,
      saves: json['saves'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  // Copy with updates
  PlayerStats copyWith({
    String? playerName,
    int? goals,
    int? assists,
    int? redCards,
    int? yellowCards,
    int? motm,
    int? cleanSheets,
    int? goalsLetIn,
    int? saves,
    DateTime? lastUpdated,
  }) {
    return PlayerStats(
      playerName: playerName ?? this.playerName,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      redCards: redCards ?? this.redCards,
      yellowCards: yellowCards ?? this.yellowCards,
      motm: motm ?? this.motm,
      cleanSheets: cleanSheets ?? this.cleanSheets,
      goalsLetIn: goalsLetIn ?? this.goalsLetIn,
      saves: saves ?? this.saves,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
