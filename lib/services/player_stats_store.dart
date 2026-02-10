import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';

/// Single Source of Truth for all player statistics
/// Manages: Goals, Assists, Yellow Cards, Red Cards, MOTM
///
/// Architecture:
/// - Store: Map<PlayerId, Map<StatType, Value>>
/// - UI reads from this store only
/// - All updates go through this store
/// - Firestore is persistence layer, not UI state
class PlayerStatsStore extends ChangeNotifier {
  // Map<playerId, Map<statType, value>>
  final Map<String, Map<String, num>> _stats = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debounce Firestore writes (500ms)
  final Map<String, Timer> _debounceTimers = {};

  // 🔄 User Profile Sync (Debounced)
  final Map<String, Map<String, num>> _pendingDeltas = {};
  final Map<String, Timer> _userSyncTimers = {};

  // 🔌 Real-time subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  // Stat types
  static const String statGoals = 'goals';
  static const String statAssists = 'assists';
  static const String statRed = 'redCards';
  static const String statYellow = 'yellowCards';
  static const String statMotm = 'motm';
  static const String statMatches = 'matches';
  static const String statXP = 'xp';
  static const String statLevel = 'level';

  // 🧤 GK Stats
  static const String statSaves = 'saves';
  static const String statCleanSheet = 'cleanSheet';
  static const String statGoalsReceived = 'goalsReceived';
  static const String statPassing = 'passing'; // GK Passing count

  static const List<String> allStatTypes = [
    statGoals,
    statAssists,
    statRed,
    statYellow,
    statMotm,
    statMatches,
    statSaves,
    statCleanSheet,
    statGoalsReceived,
    statPassing,
    statXP,
    statLevel,
  ];

  /// Initialize store with players from Firestore
  Future<void> initializeForMatch(String matchId) async {
    try {
      debugPrint('📊 PlayerStatsStore: Initializing for match $matchId');

      // Fetch match data
      final matchDoc = await _firestore
          .collection('matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists) return;

      final playerIds = List<String>.from(matchDoc['players'] ?? []);
      debugPrint('👥 Found ${playerIds.length} players');

      // Initialize each player with zero stats
      for (final playerId in playerIds) {
        _stats[playerId] = {
          statGoals: 0,
          statAssists: 0,
          statRed: 0,
          statYellow: 0,
          statMotm: 0,
          statMatches: 0,
          statSaves: 0,
          statCleanSheet: 0,
          statGoalsReceived: 0,
          statPassing: 0,
          statXP: 0,
          statLevel: 1,
        };
      }

      // Subscribe to live stats from Firestore
      _subscribeToMatchStats(matchId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ Error initializing PlayerStatsStore: $e');
    }
  }

  /// Subscribe to match stats
  void _subscribeToMatchStats(String matchId) {
    final subKey = 'match_$matchId';
    if (_subscriptions.containsKey(subKey)) return;

    debugPrint('🔌 Subscribing to stats for match $matchId');
    _subscriptions[subKey] = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('player_stats')
        .doc('aggregate')
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() ?? {};
              bool changed = false;

              for (final playerId in _stats.keys) {
                final playerStats = data[playerId] as Map<String, dynamic>?;
                if (playerStats != null) {
                  final currentStats = _stats[playerId]!;

                  // Helper to update if changed
                  void updateIfChanged(String key, int newVal) {
                    if (currentStats[key] != newVal) {
                      currentStats[key] = newVal;
                      changed = true;
                    }
                  }

                  for (final type in allStatTypes) {
                    if (type != statXP && type != statLevel) {
                      updateIfChanged(type, playerStats[type] as int? ?? 0);
                    }
                  }
                }
              }

              if (changed) {
                notifyListeners();
                debugPrint('🔄 Synced match stats from Firestore');
              }
            }
          },
          onError: (e) {
            debugPrint('❌ Error listening to match stats: $e');
          },
        );
  }

  /// Calculate XP weight for a stat
  num _getXPWeight(String statType) {
    switch (statType) {
      case statGoals:
        return 10;
      case statAssists:
        return 7;
      case statMatches:
        return 5;
      case statMotm:
        return 20;
      case statYellow:
        return -3;
      case statRed:
        return -8;
      case statSaves:
        return 2;
      case statCleanSheet:
        return 15;
      case statGoalsReceived:
        return -5;
      default:
        return 0;
    }
  }

  /// Update a single stat (optimistic + debounced Firestore sync)
  void updateStat(
    String matchId,
    String playerId,
    String statType,
    int newValue,
  ) {
    // 🧮 Calculate delta for user profile sync
    final oldValue = getStat(playerId, statType).toInt();
    final delta = newValue - oldValue;

    // Ensure player exists in store
    _stats.putIfAbsent(
      playerId,
      () => {
        statGoals: 0,
        statAssists: 0,
        statRed: 0,
        statYellow: 0,
        statMotm: 0,
        statMatches: 0,
        statSaves: 0,
        statCleanSheet: 0,
        statGoalsReceived: 0,
        statPassing: 0,
        statXP: 0,
        statLevel: 1,
      },
    );

    // Optimistic update - instant UI feedback
    _stats[playerId]![statType] = newValue.clamp(0, 999);

    // 🌟 Update XP and Level locally
    final xpDelta = delta * _getXPWeight(statType);
    if (xpDelta != 0) {
      final currentXP = getStat(playerId, statXP);
      final newXP = currentXP + xpDelta;
      _stats[playerId]![statXP] = newXP;

      final newLevel = max(1, (newXP / 100).floor());
      _stats[playerId]![statLevel] = newLevel;

      // Queue XP sync
      _queueUserStatSync(playerId, statXP, xpDelta);
    }

    notifyListeners();

    debugPrint(
      '📝 Updated $playerId.$statType = ${_stats[playerId]![statType]}',
    );

    // Debounce Firestore write
    _debouncedSaveToFirestore(matchId, playerId);

    // 🔄 Sync to user profile (Career Stats)
    if (delta != 0) {
      _queueUserStatSync(playerId, statType, delta);
    }
  }

  /// Increment stat by 1
  void incrementStat(String matchId, String playerId, String statType) {
    final current = getStat(playerId, statType).toInt();
    updateStat(matchId, playerId, statType, current + 1);
  }

  /// Decrement stat by 1
  void decrementStat(String matchId, String playerId, String statType) {
    final current = getStat(playerId, statType).toInt();
    updateStat(matchId, playerId, statType, (current - 1).clamp(0, 999));
  }

  /// Get single stat value
  num getStat(String playerId, String statType) {
    return _stats[playerId]?[statType] ?? 0;
  }

  /// Get all stats for a player
  Map<String, num> getPlayerStats(String playerId) {
    return Map.from(_stats[playerId] ?? {}).cast<String, num>();
  }

  /// Get all players' stats
  Map<String, Map<String, num>> getAllStats() {
    return Map.from(_stats);
  }

  /// Check if player exists in store
  bool hasPlayer(String playerId) {
    return _stats.containsKey(playerId);
  }

  /// Get all player IDs
  List<String> getPlayerIds() {
    return _stats.keys.toList();
  }

  /// Debounced Firestore save (prevents too many writes)
  void _debouncedSaveToFirestore(String matchId, String playerId) {
    // Cancel previous timer for this player
    _debounceTimers[playerId]?.cancel();

    // Set new timer
    _debounceTimers[playerId] = Timer(const Duration(milliseconds: 500), () {
      _saveToFirestore(matchId, playerId);
    });
  }

  /// Save stats to Firestore
  Future<void> _saveToFirestore(String matchId, String playerId) async {
    try {
      final stats = _stats[playerId] ?? {};

      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('player_stats')
          .doc('aggregate')
          .set({playerId: stats}, SetOptions(merge: true));

      debugPrint('💾 Saved $playerId stats to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
    }
  }

  /// 🔄 Queue stat update for User Profile (Career Stats)
  /// Uses FieldValue.increment to safely update aggregated stats
  void _queueUserStatSync(String playerId, String statType, num delta) {
    if (delta == 0) return;

    _pendingDeltas.putIfAbsent(playerId, () => {});
    final currentDelta = _pendingDeltas[playerId]![statType] ?? 0;
    _pendingDeltas[playerId]![statType] = currentDelta + delta;

    // Debounce user sync to avoid spamming user doc
    _userSyncTimers[playerId]?.cancel();
    _userSyncTimers[playerId] = Timer(const Duration(milliseconds: 1000), () {
      _flushUserStats(playerId);
    });
  }

  /// 💾 Flush pending user stats to Firestore
  Future<void> _flushUserStats(String playerId) async {
    final deltas = _pendingDeltas[playerId];
    if (deltas == null || deltas.isEmpty) return;

    // Create local copy and clear pending
    final updatesToApply = Map<String, int>.from(deltas);
    _pendingDeltas.remove(playerId);

    try {
      final Map<String, dynamic> updates = {};
      updatesToApply.forEach((stat, value) {
        if (value != 0) {
          // Update root fields 'goals', 'assists', etc. as per Profile requirement
          updates[stat] = FieldValue.increment(value);
        }
      });

      // 🌟 Ensure Level is updated correctly based on current local XP
      // We set level directly because it's derived, not incremented
      final currentLevel = getStat(playerId, statLevel);
      updates[statLevel] = currentLevel;

      if (updates.isNotEmpty) {
        // Use set with merge to ensure 'stats' map exists
        await _firestore
            .collection('users')
            .doc(playerId)
            .set(updates, SetOptions(merge: true));
        debugPrint('👤 Synced career stats for $playerId');
      }
    } catch (e) {
      debugPrint('❌ Failed to sync user stats: $e');
      // Restore pending deltas on failure?
      // For now, we log. In prod, might want retry logic.
    }
  }

  /// Load career stats for a player (from user profile)
  /// Now uses a stream for real-time updates
  Future<void> loadCareerStats(String playerId) async {
    final subKey = 'user_$playerId';
    if (_subscriptions.containsKey(subKey)) return;

    debugPrint('🔌 Subscribing to career stats for $playerId');
    _subscriptions[subKey] = _firestore
        .collection('users')
        .doc(playerId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final data = doc.data() ?? {};

              // Map root fields to stats map
              final Map<String, num> careerStats =
                  _stats[playerId] ?? {}; // Preserve existing stats
              bool changed = false;

              // Try reading from root fields first (Profile requirement)
              for (final key in allStatTypes) {
                final newValue = data[key] as num? ?? 0;
                if (careerStats[key] != newValue) {
                  careerStats[key] = newValue;
                  changed = true;
                }
              }

              _stats[playerId] = careerStats;
              if (changed) {
                notifyListeners();
                debugPrint('🔄 Synced career stats for $playerId');
              }
            }
          },
          onError: (e) {
            debugPrint('❌ Failed to listen to career stats: $e');
          },
        );
  }

  /// Clear all stats (for testing or match reset)
  void clearAll() {
    _stats.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    for (final timer in _userSyncTimers.values) {
      timer.cancel();
    }
    _userSyncTimers.clear();
    _pendingDeltas.clear();

    // Cancel all subscriptions
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    for (final timer in _userSyncTimers.values) {
      timer.cancel();
    }
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
