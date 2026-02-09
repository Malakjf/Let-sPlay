import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// 🎯 Single Source of Truth for Player Attributes (Coach-Driven)
///
/// FIFA / PlayFootball.me Pattern:
/// - Attributes are NOT static data
/// - Coach evaluation is the source of truth
/// - PAC, SHO, PAS, DRI, DEF, PHY calculated dynamically
/// - FUT card reads from this store only
///
/// Architecture:
/// - Store: Map<PlayerId, PlayerAttributes>
/// - Coach updates ratings → Attributes recalculate → UI updates
/// - Firestore persistence layer (optional)
class PlayerAttributesStore extends ChangeNotifier {
  // Map<playerId, attributes>
  final Map<String, PlayerAttributes> _attributes = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debounce Firestore writes (500ms)
  final Map<String, Timer> _debounceTimers = {};

  // 🛡️ Listener Guard: Track local updates to prevent feedback loops
  final Map<String, bool> _isLocalUpdateInProgress = {};
  final Map<String, Timer> _localUpdateResetTimers = {};

  // 🔌 Real-time subscriptions
  final Map<String, StreamSubscription<DocumentSnapshot>> _subscriptions = {};

  /// Attribute types (FIFA standard)
  static const String attrPace = 'PAC';
  static const String attrShooting = 'SHO';
  static const String attrPassing = 'PAS';
  static const String attrDribbling = 'DRI';
  static const String attrDefending = 'DEF';
  static const String attrPhysical = 'PHY';

  static const List<String> allAttributes = [
    attrPace,
    attrShooting,
    attrPassing,
    attrDribbling,
    attrDefending,
    attrPhysical,
  ];

  /// Get attribute value for a player
  int getAttribute(String playerId, String attributeType) {
    final attrs = _attributes[playerId];
    if (attrs == null) return 0; // Default base value

    switch (attributeType) {
      case attrPace:
        return attrs.pace;
      case attrShooting:
        return attrs.shooting;
      case attrPassing:
        return attrs.passing;
      case attrDribbling:
        return attrs.dribbling;
      case attrDefending:
        return attrs.defending;
      case attrPhysical:
        return attrs.physical;
      default:
        return 0;
    }
  }

  /// Get all attributes for a player
  PlayerAttributes? getPlayerAttributes(String playerId) {
    return _attributes[playerId];
  }

  /// 🏆 Coach Evaluation System
  ///
  /// Coach provides ratings (0-100) which influence attributes
  /// Calculation considers:
  /// - Base value (position-dependent)
  /// - Coach rating
  /// - Physical condition
  /// - Recent performance
  /// - Tactical role
  void updateFromCoachEvaluation({
    required String playerId,
    required String position,
    required CoachEvaluation evaluation,
  }) {
    // 🛡️ Mark as local update
    _markLocalUpdate(playerId);

    // Calculate base values based on position
    final baseValues = _getPositionBaseValues(position);

    // Apply coach ratings to calculate final attributes
    final attributes = PlayerAttributes(
      pace: _calculateAttribute(
        base: baseValues.pace,
        coachRating: evaluation.paceRating,
        physicalCondition: evaluation.physicalCondition,
        recentPerformance: evaluation.recentPerformance,
      ),
      shooting: _calculateAttribute(
        base: baseValues.shooting,
        coachRating: evaluation.shootingRating,
        physicalCondition: evaluation.physicalCondition,
        recentPerformance: evaluation.recentPerformance,
      ),
      passing: _calculateAttribute(
        base: baseValues.passing,
        coachRating: evaluation.passingRating,
        physicalCondition: evaluation.physicalCondition,
        recentPerformance: evaluation.recentPerformance,
      ),
      dribbling: _calculateAttribute(
        base: baseValues.dribbling,
        coachRating: evaluation.dribblingRating,
        physicalCondition: evaluation.physicalCondition,
        recentPerformance: evaluation.recentPerformance,
      ),
      defending: _calculateAttribute(
        base: baseValues.defending,
        coachRating: evaluation.defendingRating,
        physicalCondition: evaluation.physicalCondition,
        recentPerformance: evaluation.recentPerformance,
      ),
      physical: _calculateAttribute(
        base: baseValues.physical,
        coachRating: evaluation.physicalRating,
        physicalCondition: evaluation.physicalCondition,
        recentPerformance: evaluation.recentPerformance,
      ),
      position: position,
    );

    _attributes[playerId] = attributes;
    notifyListeners(); // ✅ Live update to FUT card

    // Debounced Firestore write
    _saveToFirestore(playerId, attributes);

    debugPrint('🏆 Coach evaluated $playerId: ${attributes.toMap()}');
  }

  /// 🧤 Update GK Attributes from Match Stats
  ///
  /// Maps match stats (Saves, GR, CS) to FUT attributes (DIV, REF, HAN...)
  /// Uses FutCardFull mapping:
  /// - pace -> GR (Goals Received Rating)
  /// - defending -> SAV (Saves Rating)
  /// - physical -> CS (Clean Sheet Rating)
  /// - passing -> PAS (Passing Rating)
  void updateGkAttributesFromStats({
    required String playerId,
    required int saves,
    required int goalsReceived,
    required int cleanSheet,
    required int passing,
  }) {
    // 🛡️ Mark as local update
    _markLocalUpdate(playerId);

    // Get current attributes or defaults
    final current = _attributes[playerId] ?? _getPositionBaseValues('GK');

    // Calculate ratings based on stats
    // SAV (defending): Saves * 5 -> Cap 100
    final savRating = (saves * 5).clamp(0, 100);

    // GR (pace): 100 - (Goals * 10) -> Min 0
    final grRating = (100 - (goalsReceived * 10)).clamp(0, 100);

    // CS (physical): 100 if clean sheet, else 0
    final csRating = cleanSheet > 0 ? 100 : 0;

    // PAS (passing): Passing * 2 -> Cap 100
    final pasRating = (passing * 2).clamp(0, 100);

    final newAttributes = PlayerAttributes(
      pace: grRating, // Mapped to GR
      shooting: current.shooting, // Unused for GK stats
      passing: pasRating, // Mapped to PAS
      dribbling: current.dribbling, // Unused
      defending: savRating, // Mapped to SAV
      physical: csRating, // Mapped to CS
      position: 'GK',
    );

    _attributes[playerId] = newAttributes;
    notifyListeners();
    _saveToFirestore(playerId, newAttributes);

    debugPrint(
      '🧤 GK Stats updated for $playerId: SAV=$savRating, GR=$grRating, CS=$csRating',
    );
  }

  /// Calculate individual attribute value
  /// Formula: base + coach rating + modifiers
  int _calculateAttribute({
    required int base,
    required int coachRating, // 0-100
    required double physicalCondition, // 0.0-1.0
    required double recentPerformance, // 0.0-1.0
  }) {
    // Coach rating is primary factor (0-100 points)
    final coachImpact = coachRating;

    // Physical condition affects output (0-10 points)
    final conditionImpact = (physicalCondition * 10).round();

    // Recent performance trending (0-10 points)
    final performanceImpact = (recentPerformance * 10).round();

    final calculated = base + coachImpact + conditionImpact + performanceImpact;

    // Clamp to full range: 0-100
    return calculated.clamp(0, 100);
  }

  /// Get base attribute values based on position
  /// These are starting points before coach evaluation
  PlayerAttributes _getPositionBaseValues(String position) {
    // FIFA-style position templates
    switch (position.toUpperCase()) {
      // Attackers
      case 'ST':
      case 'CF':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      case 'LW':
      case 'RW':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      // Midfielders
      case 'CAM':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      case 'CM':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      case 'CDM':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      // Defenders
      case 'LB':
      case 'RB':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      case 'CB':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      // Goalkeeper
      case 'GK':
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );

      // Default
      default:
        return const PlayerAttributes(
          pace: 0,
          shooting: 0,
          passing: 0,
          dribbling: 0,
          defending: 0,
          physical: 0,
        );
    }
  }

  /// 🛡️ Mark a player as being updated locally
  void _markLocalUpdate(String playerId) {
    _isLocalUpdateInProgress[playerId] = true;
    _localUpdateResetTimers[playerId]?.cancel();
    _localUpdateResetTimers[playerId] = Timer(const Duration(seconds: 2), () {
      _isLocalUpdateInProgress[playerId] = false;
    });
  }

  /// Save to Firestore (debounced)
  void _saveToFirestore(String playerId, PlayerAttributes attributes) {
    // Cancel existing timer
    _debounceTimers[playerId]?.cancel();

    // Start new timer
    _debounceTimers[playerId] = Timer(
      const Duration(milliseconds: 500),
      () async {
        try {
          final data = attributes.toMap();

          // 🧤 Add GK specific metrics if applicable
          if (attributes.position == 'GK') {
            data['gk'] = {
              'gr': attributes.pace,
              'sav': attributes.defending,
              'cs': attributes.physical,
              'pas': attributes.passing,
            };
          }

          await _firestore.collection('users').doc(playerId).set({
            'metrics': data,
            'lastAttributeUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('💾 Saved attributes for $playerId');
        } catch (e) {
          debugPrint('❌ Failed to save attributes: $e');
        }
      },
    );
  }

  /// Initialize attributes from Firestore
  Future<void> loadPlayerAttributes(String playerId) async {
    try {
      subscribeToPlayer(playerId); // ✅ Start listening for updates

      final doc = await _firestore.collection('users').doc(playerId).get();

      if (doc.exists && doc.data()?['metrics'] != null) {
        final data = doc.data()!['metrics'] as Map<String, dynamic>;
        _attributes[playerId] = PlayerAttributes.fromMap(data);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
        debugPrint('📥 Loaded attributes for $playerId');
      } else {
        debugPrint('⚠️ No stored attributes for $playerId, using defaults');
      }
    } catch (e) {
      debugPrint('❌ Failed to load attributes: $e');
    }
  }

  /// 🔌 Subscribe to real-time attribute updates
  void subscribeToPlayer(String playerId) {
    if (_subscriptions.containsKey(playerId)) return;

    debugPrint('🔌 Subscribing to attributes for $playerId');
    _subscriptions[playerId] = _firestore
        .collection('users')
        .doc(playerId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && snapshot.data()?['metrics'] != null) {
              // 🛡️ Listener Guard: Ignore if local update is in progress
              if (_isLocalUpdateInProgress[playerId] == true) {
                return;
              }

              final data = snapshot.data()!['metrics'] as Map<String, dynamic>;
              final newAttributes = PlayerAttributes.fromMap(data);

              // 🛡️ Equality Check: Don't notify if data hasn't changed
              if (_attributes[playerId] == newAttributes) {
                return;
              }

              _attributes[playerId] = newAttributes;
              notifyListeners();
              debugPrint('🔄 Synced attributes for $playerId from Firestore');
            }
          },
          onError: (e) {
            debugPrint('❌ Error listening to attributes for $playerId: $e');
          },
        );
  }

  void unsubscribeFromPlayer(String playerId) {
    _subscriptions[playerId]?.cancel();
    _subscriptions.remove(playerId);
  }

  /// Bulk load attributes for multiple players
  Future<void> loadMultiplePlayerAttributes(List<String> playerIds) async {
    for (final playerId in playerIds) {
      await loadPlayerAttributes(playerId);
    }
  }

  /// Clear store
  void clear() {
    _attributes.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
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
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    for (final timer in _localUpdateResetTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}

/// 📊 Player Attributes Model
class PlayerAttributes {
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final String? position;

  const PlayerAttributes({
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    this.position,
  });

  Map<String, dynamic> toMap() {
    return {
      'pac': pace,
      'sho': shooting,
      'pas': passing,
      'dri': dribbling,
      'def': defending,
      'phy': physical,
      'position': position,
    };
  }

  factory PlayerAttributes.fromMap(Map<String, dynamic> map) {
    return PlayerAttributes(
      pace:
          map['pac'] as int? ??
          map['pace'] as int? ??
          map['PAC'] as int? ??
          map['GR'] as int? ??
          map['gr'] as int? ??
          0,
      shooting:
          map['sho'] as int? ??
          map['shooting'] as int? ??
          map['SHO'] as int? ??
          0,
      passing:
          map['pas'] as int? ??
          map['passing'] as int? ??
          map['PAS'] as int? ??
          0,
      dribbling:
          map['dri'] as int? ??
          map['dribbling'] as int? ??
          map['DRI'] as int? ??
          0,
      defending:
          map['def'] as int? ??
          map['defending'] as int? ??
          map['DEF'] as int? ??
          map['SAV'] as int? ??
          map['sav'] as int? ??
          0,
      physical:
          map['phy'] as int? ??
          map['physical'] as int? ??
          map['PHY'] as int? ??
          map['CS'] as int? ??
          map['cs'] as int? ??
          0,
      position: map['position'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayerAttributes &&
        other.pace == pace &&
        other.shooting == shooting &&
        other.passing == passing &&
        other.dribbling == dribbling &&
        other.defending == defending &&
        other.physical == physical &&
        other.position == position;
  }

  @override
  int get hashCode {
    return Object.hash(
      pace,
      shooting,
      passing,
      dribbling,
      defending,
      physical,
      position,
    );
  }
}

/// 🏆 Coach Evaluation Input
///
/// Coach provides ratings for each attribute category
/// Plus contextual factors that affect calculations
class CoachEvaluation {
  // Primary ratings (0-100 each)
  final int paceRating;
  final int shootingRating;
  final int passingRating;
  final int dribblingRating;
  final int defendingRating;
  final int physicalRating;

  // Contextual modifiers (0.0-1.0)
  final double physicalCondition; // Fitness, health
  final double recentPerformance; // Last 5 matches trend

  const CoachEvaluation({
    required this.paceRating,
    required this.shootingRating,
    required this.passingRating,
    required this.dribblingRating,
    required this.defendingRating,
    required this.physicalRating,
    this.physicalCondition = 1.0,
    this.recentPerformance = 0.5,
  });

  /// Quick evaluation (same rating for all)
  factory CoachEvaluation.uniform(int rating) {
    return CoachEvaluation(
      paceRating: rating,
      shootingRating: rating,
      passingRating: rating,
      dribblingRating: rating,
      defendingRating: rating,
      physicalRating: rating,
    );
  }
}
