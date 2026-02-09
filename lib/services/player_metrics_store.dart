import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';

/// Single Source of Truth for player performance metrics
/// Manages: PAC, SHO, PAS, DRI, DEF, PHY, CS, GL, SAV
///
/// Separate from PlayerStatsStore because:
/// - Different update frequency
/// - Different persistence requirements
/// - Different UI needs (can be complex ranges)
class PlayerMetricsStore extends ChangeNotifier {
  // Map<playerId, Map<metricType, value>>
  final Map<String, Map<String, num>> _metrics = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Metric types
  static const String metricPAC = 'PAC'; // Pace
  static const String metricSHO = 'SHO'; // Shooting
  static const String metricPAS = 'PAS'; // Passing
  static const String metricDRI = 'DRI'; // Dribbling
  static const String metricDEF = 'DEF'; // Defense
  static const String metricPHY = 'PHY'; // Physical
  static const String metricCS = 'CS'; // Clean Sheet
  static const String metricGL = 'GL'; // Goals Let In
  static const String metricSAV = 'SAV'; // Saves

  static const List<String> allMetricTypes = [
    metricPAC,
    metricSHO,
    metricPAS,
    metricDRI,
    metricDEF,
    metricPHY,
    metricCS,
    metricGL,
    metricSAV,
  ];

  // Debounce timers
  final Map<String, Timer> _debounceTimers = {};

  // 🛡️ Listener Guard: Track local updates
  final Map<String, bool> _isLocalUpdateInProgress = {};
  final Map<String, Timer> _localUpdateResetTimers = {};

  // 🔌 User Profile Subscriptions
  final Map<String, StreamSubscription> _userSubscriptions = {};

  /// Initialize metrics for match
  Future<void> initializeForMatch(String matchId) async {
    try {
      debugPrint('📊 PlayerMetricsStore: Initializing for match $matchId');

      // Fetch match data
      final matchDoc = await _firestore
          .collection('matches')
          .doc(matchId)
          .get();

      if (!matchDoc.exists) return;

      final playerIds = List<String>.from(matchDoc['players'] ?? []);

      // Initialize each player with zero metrics
      for (final playerId in playerIds) {
        _metrics[playerId] = {
          metricPAC: 0,
          metricSHO: 0,
          metricPAS: 0,
          metricDRI: 0,
          metricDEF: 0,
          metricPHY: 0,
          metricCS: 0,
          metricGL: 0,
          metricSAV: 0,
        };
      }

      // Load saved metrics (Prioritize User Profile for Ratings)
      await _loadMetricsFromFirestore(matchId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error initializing PlayerMetricsStore: $e');
    }
  }

  /// Load metrics from Firestore
  Future<void> _loadMetricsFromFirestore(String matchId) async {
    try {
      final metricsDoc = await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('player_metrics')
          .doc('aggregate')
          .get();

      if (metricsDoc.exists) {
        final data = metricsDoc.data() ?? {};
        for (final playerId in _metrics.keys) {
          final playerMetrics = data[playerId] as Map<String, dynamic>?;
          if (playerMetrics != null) {
            _metrics[playerId]?.addAll({
              metricPAC: playerMetrics[metricPAC] as int? ?? 0,
              metricSHO: playerMetrics[metricSHO] as int? ?? 0,
              metricPAS: playerMetrics[metricPAS] as int? ?? 0,
              metricDRI: playerMetrics[metricDRI] as int? ?? 0,
              metricDEF: playerMetrics[metricDEF] as int? ?? 0,
              metricPHY: playerMetrics[metricPHY] as int? ?? 0,
              metricCS: playerMetrics[metricCS] as int? ?? 0,
              metricGL: playerMetrics[metricGL] as int? ?? 0,
              metricSAV: playerMetrics[metricSAV] as int? ?? 0,
            });
          }
        }

        // Also load from User Profiles to ensure we have the latest ratings
        await _loadMetricsFromUserProfiles(_metrics.keys.toList());
        debugPrint('✅ Loaded metrics from Firestore');
      } else {
        // If no match metrics, load from User Profiles
        await _loadMetricsFromUserProfiles(_metrics.keys.toList());
      }
    } catch (e) {
      debugPrint('⚠️ Could not load metrics from Firestore: $e');
    }
  }

  /// Load metrics from User Profiles (for initial ratings)
  Future<void> _loadMetricsFromUserProfiles(List<String> playerIds) async {
    try {
      // We can't query 'in' with too many IDs, so we might need to batch or do individual gets.
      // For simplicity and reliability, we'll fetch individually or in small batches.
      // Given Firestore limits, individual gets are often fine for roster sizes < 20.

      for (final playerId in playerIds) {
        final doc = await _firestore.collection('users').doc(playerId).get();
        if (doc.exists && doc.data()?['metrics'] != null) {
          final metrics = Map<String, dynamic>.from(doc.data()!['metrics']);

          _metrics.putIfAbsent(playerId, () => {});

          // Only update if not already set (or overwrite? Overwrite is better for "Single Source of Truth")
          // We map the persistent ratings: PAC, SHO, PAS, DRI, DEF, PHY
          final persistentMetrics = [
            metricPAC,
            metricSHO,
            metricPAS,
            metricDRI,
            metricDEF,
            metricPHY,
          ];

          for (final m in persistentMetrics) {
            if (metrics.containsKey(m)) {
              _metrics[playerId]![m] = metrics[m] as int;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading user profile metrics: $e');
    }
  }

  /// Update a metric value
  void updateMetric(
    String matchId,
    String playerId,
    String metricType,
    int newValue,
  ) {
    // 🛡️ Mark as local update
    _markLocalUpdate(playerId);

    final oldValue = getMetric(playerId, metricType);
    final diff = newValue - oldValue;

    // Ensure player exists
    _metrics.putIfAbsent(
      playerId,
      () => {
        metricPAC: 0,
        metricSHO: 0,
        metricPAS: 0,
        metricDRI: 0,
        metricDEF: 0,
        metricPHY: 0,
        metricCS: 0,
        metricGL: 0,
        metricSAV: 0,
      },
    );

    // Clamp value to valid range (0-100)
    _metrics[playerId]![metricType] = newValue.clamp(0, 100);
    notifyListeners();

    // 🌟 Update XP (0.5 per metric point)
    // We need to read current XP from somewhere. Since we subscribe to user doc,
    // we should store XP in _metrics or fetch it.
    // For simplicity, we'll just increment XP in Firestore and let the subscription update local state.
    if (diff != 0) {
      _updateUserXP(playerId, diff * 0.5);
    }

    debugPrint(
      '📝 Updated $playerId.$metricType = ${_metrics[playerId]![metricType]}',
    );

    // Debounce Firestore write
    _debouncedSaveToFirestore(matchId, playerId);

    // ✅ Save to User Profile (Single Source of Truth for Ratings)
    _debouncedSaveToUserProfile(playerId);
  }

  /// Get single metric value
  num getMetric(String playerId, String metricType) {
    return _metrics[playerId]?[metricType] ?? 0;
  }

  /// Get all metrics for a player
  Map<String, num> getPlayerMetrics(String playerId) {
    return Map.from(_metrics[playerId] ?? {}).cast<String, num>();
  }

  /// Get all metrics for all players
  Map<String, Map<String, num>> getAllMetrics() {
    return Map.from(_metrics);
  }

  /// Check if player exists
  bool hasPlayer(String playerId) {
    return _metrics.containsKey(playerId);
  }

  /// Get all player IDs
  List<String> getPlayerIds() {
    return _metrics.keys.toList();
  }

  /// 🛡️ Mark a player as being updated locally
  void _markLocalUpdate(String playerId) {
    _isLocalUpdateInProgress[playerId] = true;
    _localUpdateResetTimers[playerId]?.cancel();
    _localUpdateResetTimers[playerId] = Timer(const Duration(seconds: 2), () {
      _isLocalUpdateInProgress[playerId] = false;
    });
  }

  /// Debounced save
  void _debouncedSaveToFirestore(String matchId, String playerId) {
    _debounceTimers[playerId]?.cancel();
    _debounceTimers[playerId] = Timer(const Duration(milliseconds: 500), () {
      _saveToFirestore(matchId, playerId);
    });
  }

  /// Debounced save to User Profile
  void _debouncedSaveToUserProfile(String userId) {
    final key = 'user_profile_$userId';
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 500), () {
      _saveToUserProfile(userId, _metrics[userId] ?? {});
    });
  }

  /// 🌟 Update User XP and Level
  Future<void> _updateUserXP(String userId, double xpDelta) async {
    try {
      // We use a transaction or simple increment.
      // Since Level depends on Total XP, we need to read-modify-write or use increment and let UI derive level.
      // But requirement says "XP updates Level automatically" and "Level... saved in Firestore".
      // So we must calculate Level on server or read-calc-write.
      // We'll do a transaction to ensure consistency.
      final userRef = _firestore.collection('users').doc(userId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return;

        final currentXP = (snapshot.data()?['xp'] as num?)?.toDouble() ?? 0.0;
        final newXP = currentXP + xpDelta;
        final newLevel = max(1, (newXP / 100).floor());

        transaction.update(userRef, {'xp': newXP, 'level': newLevel});
      });
    } catch (e) {
      debugPrint('❌ Error updating XP: $e');
    }
  }

  /// Save to Firestore
  Future<void> _saveToFirestore(String matchId, String playerId) async {
    try {
      final metrics = _metrics[playerId] ?? {};

      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('player_metrics')
          .doc('aggregate')
          .set({playerId: metrics}, SetOptions(merge: true));

      debugPrint('💾 Saved $playerId metrics to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving metrics to Firestore: $e');
    }
  }

  /// 🧤 Update GK Ratings from Match Stats (Coach/Organization)
  /// Calculates 0-99 ratings from raw stats and saves to User Profile
  void updateGkRatingsFromStats({
    required String userId,
    required int saves,
    required int goalsReceived,
    required int cleanSheet,
    required int passing,
  }) {
    // 🛡️ Mark as local update
    _markLocalUpdate(userId);

    // Calculate ratings based on stats (Logic moved from AttributesStore)
    // SAV: Base 50 + (Saves * 5) -> Cap 100
    final savRating = (50 + (saves * 5)).clamp(40, 100);

    // GR: Base 100 - (Goals * 10) -> Min 40
    final grRating = (100 - (goalsReceived * 10)).clamp(40, 100);

    // CS: 100 if clean sheet, else 50
    final csRating = cleanSheet > 0 ? 100 : 50;

    // PAS: Base 50 + (Passing * 2) -> Cap 100
    final pasRating = (50 + (passing * 2)).clamp(40, 100);

    // Update local state
    _metrics.putIfAbsent(userId, () => {});
    _metrics[userId]![metricSAV] = savRating;
    _metrics[userId]![metricGL] = grRating; // Mapped to GR
    _metrics[userId]![metricCS] = csRating;
    _metrics[userId]![metricPAS] = pasRating;

    notifyListeners();

    // Save to Firestore (User Profile)
    _saveToUserProfile(userId, {
      metricSAV: savRating,
      'GR': grRating, // Store as GR for consistency with prompt
      metricCS: csRating,
      metricPAS: pasRating,
    });
  }

  /// 💾 Save metrics to User Profile (users/{userId}/metrics)
  Future<void> _saveToUserProfile(
    String userId,
    Map<String, num> values,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'metrics': values,
        'lastMetricUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('💾 Saved GK metrics for $userId');
    } catch (e) {
      debugPrint('❌ Error saving user metrics: $e');
    }
  }

  /// 🔌 Subscribe to User Profile Metrics (for Profile/Card)
  void subscribeToUser(String userId) {
    if (_userSubscriptions.containsKey(userId)) return;

    debugPrint('🔌 Subscribing to metrics for user $userId');
    _userSubscriptions[userId] = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            // 🛡️ Listener Guard
            if (_isLocalUpdateInProgress[userId] == true) {
              return;
            }

            final data = snapshot.data();
            if (data != null && data['metrics'] is Map) {
              final metrics = Map<String, dynamic>.from(data['metrics']);

              _metrics.putIfAbsent(userId, () => {});

              // Map Firestore keys to Store keys
              // Handle GR specifically as it might be stored as 'GR' or 'GL'
              final gr =
                  metrics['GR'] ?? metrics['GL'] ?? metrics[metricGL] ?? 0;

              bool changed = false;
              void updateIfChanged(String key, num val) {
                if (_metrics[userId]![key] != val) {
                  _metrics[userId]![key] = val;
                  changed = true;
                }
              }

              updateIfChanged(metricPAC, metrics[metricPAC] as int? ?? 0);
              updateIfChanged(metricSHO, metrics[metricSHO] as int? ?? 0);
              updateIfChanged(metricPAS, metrics[metricPAS] as int? ?? 0);
              updateIfChanged(metricDRI, metrics[metricDRI] as int? ?? 0);
              updateIfChanged(metricDEF, metrics[metricDEF] as int? ?? 0);
              updateIfChanged(metricPHY, metrics[metricPHY] as int? ?? 0);

              updateIfChanged(metricSAV, metrics[metricSAV] as int? ?? 0);
              updateIfChanged(metricCS, metrics[metricCS] as int? ?? 0);
              updateIfChanged(metricGL, gr as int);

              if (changed) {
                notifyListeners();
              }
            }
          }
        });
  }

  /// Check if player is GK based on metrics presence or external flag
  bool isGK(String userId) {
    // This is a heuristic. Ideally position is passed, but if we have high SAV/GR/CS it's likely GK data.
    // For strict checking, rely on the UI passing the position.
    final m = _metrics[userId];
    return m != null && (m.containsKey(metricSAV) || m.containsKey('GR'));
  }

  /// Clear all metrics
  void clearAll() {
    _metrics.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    notifyListeners();

    for (final sub in _userSubscriptions.values) {
      sub.cancel();
    }
    _userSubscriptions.clear();
  }

  @override
  void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    // _userSubscriptions are cleared in clearAll()
    for (final sub in _userSubscriptions.values) {
      sub.cancel();
    }
    for (final timer in _localUpdateResetTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}
