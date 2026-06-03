import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// 🎯 Single Source of Truth for Player Attributes (Coach-Driven)
///
/// FIFA / PlayFootball.me Pattern:
/// - Attributes are NOT static data
/// - Coach evaluation is the source of truth
/// - Modernized: Admin Approval Workflow (Admin/Coach/Player roles)
///
/// Architecture:
/// - Store: Map<PlayerId, PlayerAttributes>
/// - Evaluation Staging: 'evaluations' collection
/// - Active Ratings: 'users/{id}/metrics' (Only updated on approval)
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
  Future<void> submitEvaluation({
    required String playerId,
    required String playerName,
    required String position,
    required CoachEvaluation evaluation,
    required String ratedById,
    required String ratedByName,
    required String ratedByRole,
    String notes = "",
  }) async {
    // Calculate base values based on position
    final baseValues = _getPositionBaseValues(position);

    // 1. Calculate the FIFA-style attributes locally
    final calculatedMetrics = PlayerAttributes(
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

    // 2. Prepare Evaluation Document
    final bool isAdmin = ratedByRole.toLowerCase() == 'admin';
    final String status = isAdmin ? 'approved' : 'pending';

    final evalDoc = {
      'playerId': playerId,
      'playerName': playerName,
      'position': position,
      'ratedById': ratedById,
      'ratedByName': ratedByName,
      'ratedByRole': ratedByRole,
      'status': status,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'metrics': calculatedMetrics.toMap(),
      'coachEvaluation': {
        'paceRating': evaluation.paceRating,
        'shootingRating': evaluation.shootingRating,
        'passingRating': evaluation.passingRating,
        'dribblingRating': evaluation.dribblingRating,
        'defendingRating': evaluation.defendingRating,
        'physicalRating': evaluation.physicalRating,
        'physicalCondition': evaluation.physicalCondition,
        'recentPerformance': evaluation.recentPerformance,
      },
    };

    try {
      final docRef = await _firestore.collection('evaluations').add(evalDoc);

      // 3. If Admin, apply changes immediately to Player Profile
      if (isAdmin) {
        await _applyEvaluationToPlayer(
          playerId,
          calculatedMetrics,
          docRef.id,
          ratedById,
        );
      }
      debugPrint(
        '📝 Evaluation $status for $playerId submitted by $ratedByRole',
      );
      return; // Explicit return for Future<void>
    } catch (e) {
      debugPrint('❌ Failed to submit evaluation: $e');
    }
  }

  /// 🛡️ ADMIN ONLY: Approve or Reject a coach evaluation
  Future<void> reviewEvaluation({
    required String evaluationId,
    required String playerId,
    required bool approve,
    required String adminId,
    String? adminNotes,
    Map<String, dynamic>? adminEdits, // Ability to edit before approval
  }) async {
    try {
      final evalRef = _firestore.collection('evaluations').doc(evaluationId);

      if (!approve) {
        await evalRef.update({
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      // Get the evaluation data
      final snapshot = await evalRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final metrics = PlayerAttributes.fromMap(data['metrics']);

      // Update Evaluation Status
      await evalRef.update({
        'status': 'approved',
        'approvedBy': adminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'editedByAdmin': adminEdits != null,
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (adminEdits != null) 'metrics': adminEdits,
      });

      // Update Player Profile (This makes it live for the Player/Card)
      final finalMetrics = adminEdits != null
          ? PlayerAttributes.fromMap(adminEdits)
          : metrics;
      await _applyEvaluationToPlayer(
        playerId,
        finalMetrics,
        evaluationId,
        adminId,
      );

      debugPrint('✅ Admin $adminId approved evaluation $evaluationId');
    } catch (e) {
      debugPrint('❌ Error reviewing evaluation: $e');
    }
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
    required String playerId, // Assuming this is the player being updated
    required int saves,
    required int goalsReceived,
    required int cleanSheet,
    required int passing,
  }) {
    // 🛡️ Mark as local update
    _markLocalUpdate(playerId);
    // This method should be async to handle potential Firestore operations

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
    notifyListeners(); // Notify listeners for immediate UI update

    // Directly apply to player's metrics. For GK stats, we assume they are
    // direct updates and don't go through the 'evaluations' collection for approval.
    // We'll use a placeholder for sourceEvalId and actorId.
    _applyEvaluationToPlayer(
      playerId,
      newAttributes,
      'gk_stats_update_${DateTime.now().millisecondsSinceEpoch}',
      'system_gk_updater',
    );

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
          pace: 35,
          shooting: 40,
          passing: 20,
          dribbling: 30,
          defending: 10,
          physical: 25,
        );

      case 'LW':
      case 'RW':
        return const PlayerAttributes(
          pace: 45,
          shooting: 30,
          passing: 30,
          dribbling: 40,
          defending: 10,
          physical: 15,
        );

      // Midfielders
      case 'CAM':
        return const PlayerAttributes(
          pace: 30,
          shooting: 30,
          passing: 45,
          dribbling: 45,
          defending: 15,
          physical: 20,
        );

      case 'CM':
      case 'CDM':
        return const PlayerAttributes(
          pace: 25,
          shooting: 20,
          passing: 35,
          dribbling: 30,
          defending: 35,
          physical: 35,
        );

      // Defenders
      case 'LB':
      case 'RB':
        return const PlayerAttributes(
          pace: 40,
          shooting: 15,
          passing: 25,
          dribbling: 30,
          defending: 40,
          physical: 35,
        );

      case 'CB':
        return const PlayerAttributes(
          pace: 20,
          shooting: 10,
          passing: 20,
          dribbling: 15,
          defending: 45,
          physical: 45,
        );

      // Goalkeeper
      case 'GK':
        return const PlayerAttributes(
          pace: 15,
          shooting: 5,
          passing: 15,
          dribbling: 10,
          defending: 30,
          physical: 40,
        );

      // Default
      default:
        return const PlayerAttributes(
          pace: 20,
          shooting: 20,
          passing: 20,
          dribbling: 20,
          defending: 20,
          physical: 20,
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

  /// Internal helper to sync approved metrics to the player document
  Future<void> _applyEvaluationToPlayer(
    String playerId,
    PlayerAttributes attributes,
    String sourceEvalId,
    String actorId,
  ) async {
    _markLocalUpdate(playerId);
    _attributes[playerId] = attributes;
    notifyListeners();

    try {
      final data = attributes.toMap();

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
        'lastApprovedEvaluationId': sourceEvalId,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Sync to player profile failed: $e');
    }
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
