/// 🏆 Coach Evaluation System - Usage Examples
///
/// This file demonstrates how to use the PlayerAttributesStore
/// to implement coach-driven attribute evaluation.
library;

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_attributes_store.dart';

/// Example 1: Basic Coach Evaluation
///
/// Coach provides ratings for each attribute category
/// The store calculates final values and updates the FUT card live
void exampleBasicEvaluation(BuildContext context) {
  final attributesStore = context.read<PlayerAttributesStore>();

  // Coach evaluates player
  const evaluation = CoachEvaluation(
    paceRating: 75, // 0-100 scale
    shootingRating: 85, // Strong shooter
    passingRating: 70, // Good passer
    dribblingRating: 80, // Excellent dribbler
    defendingRating: 50, // Attacking player
    physicalRating: 72, // Average physical
    physicalCondition: 1.0, // 100% fit
    recentPerformance: 0.8, // 80% recent form
  );

  // Update attributes for player
  attributesStore.submitEvaluation(
    playerId: 'player_123',
    playerName: 'Player 123', // Placeholder
    position: 'ST', // Striker
    evaluation: evaluation,
    ratedById:
        FirebaseAuth.instance.currentUser?.uid ?? 'coach_id_1', // Placeholder
    ratedByName:
        FirebaseAuth.instance.currentUser?.displayName ??
        'Coach Alpha', // Placeholder
    ratedByRole: 'coach',
  );

  // ✅ FUT card automatically updates!
}

/// Example 2: Position-Based Evaluation
///
/// Different positions get different base values
/// Coach evaluation adjusts from those bases
void examplePositionBasedEvaluation(BuildContext context) {
  final attributesStore = context.read<PlayerAttributesStore>();

  // Evaluating a Center Back (CB)
  const defenderEvaluation = CoachEvaluation(
    paceRating: 60, // CBs don't need extreme pace
    shootingRating: 40, // Not a priority
    passingRating: 65, // Good passing from back
    dribblingRating: 50, // Basic ball control
    defendingRating: 90, // ⭐ Key attribute!
    physicalRating: 85, // Strong and physical
    physicalCondition: 0.9,
    recentPerformance: 0.7,
  );

  attributesStore.submitEvaluation(
    playerId: 'defender_456',
    playerName: 'Defender 456', // Placeholder
    position: 'CB', // Position determines base values
    evaluation: defenderEvaluation,
    ratedById:
        FirebaseAuth.instance.currentUser?.uid ?? 'coach_id_2', // Placeholder
    ratedByName:
        FirebaseAuth.instance.currentUser?.displayName ??
        'Coach Beta', // Placeholder
    ratedByRole: 'coach',
  );

  // Result: DEF will be high, PAC/SHO will be lower
  // This matches FIFA logic where CBs have high defending
}

/// Example 3: Quick Uniform Evaluation
///
/// When coach wants to give same rating across all attributes
void exampleUniformEvaluation(BuildContext context) {
  final attributesStore = context.read<PlayerAttributesStore>();

  // Give player 80 rating across all categories
  final uniformEvaluation = CoachEvaluation.uniform(80);

  attributesStore.submitEvaluation(
    playerId: 'player_789',
    playerName: 'Player 789', // Placeholder
    position: 'CM', // Central Midfielder
    evaluation: uniformEvaluation,
    ratedById:
        FirebaseAuth.instance.currentUser?.uid ?? 'coach_id_3', // Placeholder
    ratedByName:
        FirebaseAuth.instance.currentUser?.displayName ??
        'Coach Gamma', // Placeholder
    ratedByRole: 'coach',
  );

  // All attributes will be adjusted to around 80
  // (exact value depends on position base + modifiers)
}

/// Example 4: Contextual Modifiers
///
/// Physical condition and recent performance affect calculations
void exampleContextualModifiers(BuildContext context) {
  final attributesStore = context.read<PlayerAttributesStore>();

  // Player returning from injury
  const injuredPlayerEvaluation = CoachEvaluation(
    paceRating: 80,
    shootingRating: 85,
    passingRating: 75,
    dribblingRating: 80,
    defendingRating: 60,
    physicalRating: 75,
    physicalCondition: 0.6, // ⚠️ Only 60% fit (returning from injury)
    recentPerformance: 0.4, // ⚠️ 40% form (hasn't played in weeks)
  );

  attributesStore.submitEvaluation(
    playerId: 'injured_player',
    playerName: 'Injured Player', // Placeholder
    position: 'RW',
    evaluation: injuredPlayerEvaluation,
    ratedById:
        FirebaseAuth.instance.currentUser?.uid ?? 'coach_id_4', // Placeholder
    ratedByName:
        FirebaseAuth.instance.currentUser?.displayName ??
        'Coach Delta', // Placeholder
    ratedByRole: 'coach',
  );

  // Despite high coach ratings, final attributes will be lower
  // due to poor physical condition and form
}

/// Example 5: Player on Fire (Hot Streak)
///
/// Player in excellent form gets boosted attributes
void exampleHotStreak(BuildContext context) {
  final attributesStore = context.read<PlayerAttributesStore>();

  // Player with amazing recent performances
  const hotStreakEvaluation = CoachEvaluation(
    paceRating: 75,
    shootingRating: 80,
    passingRating: 70,
    dribblingRating: 75,
    defendingRating: 50,
    physicalRating: 70,
    physicalCondition: 1.0, // ✅ 100% fit
    recentPerformance: 1.0, // ✅ 100% form (5 great games in a row!)
  );

  attributesStore.submitEvaluation(
    playerId: 'hot_player',
    playerName: 'Hot Player', // Placeholder
    position: 'ST',
    evaluation: hotStreakEvaluation,
    ratedById:
        FirebaseAuth.instance.currentUser?.uid ?? 'coach_id_5', // Placeholder
    ratedByName:
        FirebaseAuth.instance.currentUser?.displayName ??
        'Coach Epsilon', // Placeholder
    ratedByRole: 'coach',
  );

  // Attributes boosted by excellent form and fitness
  // Card will show higher values than base coach ratings
}

/// Example 6: Loading Saved Attributes
///
/// Load previously saved attributes from Firestore
Future<void> exampleLoadAttributes(BuildContext context) async {
  final attributesStore = context.read<PlayerAttributesStore>();

  // Load single player
  await attributesStore.loadPlayerAttributes('player_123');

  // Or load multiple players at once
  await attributesStore.loadMultiplePlayerAttributes([
    'player_123',
    'player_456',
    'player_789',
  ]);

  // FUT cards will show loaded attributes
}

/// Example 7: Real-Time Updates
///
/// Widget automatically rebuilds when coach updates evaluation
class CoachEvaluationPanel extends StatelessWidget {
  final String playerId;

  const CoachEvaluationPanel({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Coach input sliders
        ElevatedButton(
          onPressed: () {
            // When coach changes evaluation...
            final attributesStore = context.read<PlayerAttributesStore>();
            final currentUser = FirebaseAuth.instance.currentUser;
            final currentUserId = currentUser?.uid ?? 'anonymous_coach_id';
            final currentUserName =
                currentUser?.displayName ?? 'Anonymous Coach';

            attributesStore.submitEvaluation(
              playerId: playerId,
              playerName: 'Player Name for $playerId', // Placeholder
              position: 'CM',
              evaluation: const CoachEvaluation(
                paceRating: 75,
                shootingRating: 80,
                passingRating: 85,
                physicalCondition: 1.0,
                recentPerformance: 0.9,
                dribblingRating: 78,
                defendingRating: 65,
                physicalRating: 72,
              ),
              ratedById: currentUserId,
              ratedByName: currentUserName,
              ratedByRole: 'coach',
            );

            // ✅ FUT card updates instantly!
          },
          child: const Text('Submit Evaluation'),
        ),

        // FUT Card (Consumer automatically rebuilds)
        Consumer<PlayerAttributesStore>(
          builder: (context, store, child) {
            final attributes = store.getPlayerAttributes(playerId);

            return Column(
              children: [
                Text('PAC: ${attributes?.pace ?? 50}'),
                Text('SHO: ${attributes?.shooting ?? 50}'),
                Text('PAS: ${attributes?.passing ?? 50}'),
                Text('DRI: ${attributes?.dribbling ?? 50}'),
                Text('DEF: ${attributes?.defending ?? 50}'),
                Text('PHY: ${attributes?.physical ?? 50}'),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Example 8: Complete Coach Workflow
///
/// Full flow from evaluation to card display
class CoachEvaluationWorkflow {
  static Future<void> evaluateAndDisplay(
    BuildContext context, {
    required String playerId,
    required String position,
    required int paceRating,
    required int shootingRating,
    required int passingRating,
    required int dribblingRating,
    required int defendingRating,
    required int physicalRating,
    required double fitnessLevel,
    required double recentForm,
  }) async {
    final attributesStore = context.read<PlayerAttributesStore>();

    // Step 1: Create evaluation from coach inputs
    final evaluation = CoachEvaluation(
      paceRating: paceRating,
      shootingRating: shootingRating,
      passingRating: passingRating,
      dribblingRating: dribblingRating,
      defendingRating: defendingRating,
      physicalRating: physicalRating,
      physicalCondition: fitnessLevel,
      recentPerformance: recentForm,
    );

    // Step 2: Calculate and store attributes
    attributesStore.submitEvaluation(
      playerId: playerId,
      playerName: 'Player Name for $playerId', // Placeholder
      position: position,
      evaluation: evaluation,
      ratedById:
          FirebaseAuth.instance.currentUser?.uid ??
          'workflow_coach_id', // Placeholder
      ratedByName:
          FirebaseAuth.instance.currentUser?.displayName ??
          'Workflow Coach', // Placeholder
      ratedByRole: 'coach',
    );

    // Step 3: Attributes automatically saved to Firestore (debounced)
    // Step 4: FUT card automatically updates (Consumer pattern)

    debugPrint('✅ Player $playerId evaluated by coach');
    debugPrint('📊 Attributes calculated and stored');
    debugPrint('🎴 FUT card updated live');
  }
}

/// Example 9: Attribute Value Ranges
///
/// Understanding the calculation formula
///
/// Formula: base + (coachRating * 0.4) + (physicalCondition * 10) + (recentPerformance * 10)
/// Clamped to: 40-99
///
/// Examples:
/// - CB with DEF base 70, coach rating 90, 100% fit, 80% form:
///   70 + (90 * 0.4) + (1.0 * 10) + (0.8 * 10) = 70 + 36 + 10 + 8 = 124 → 99 (clamped)
///
/// - ST with PAC base 60, coach rating 80, 60% fit, 40% form:
///   60 + (80 * 0.4) + (0.6 * 10) + (0.4 * 10) = 60 + 32 + 6 + 4 = 102 → 99 (clamped)
///
/// - GK with SHO base 30, coach rating 50, 100% fit, 50% form:
///   30 + (50 * 0.4) + (1.0 * 10) + (0.5 * 10) = 30 + 20 + 10 + 5 = 65

/// Example 10: Integration with Match System
///
/// Update attributes based on match performance
void exampleMatchPerformanceUpdate(BuildContext context) {
  final attributesStore = context.read<PlayerAttributesStore>();

  // After match, coach reviews performance
  // Player had excellent match:
  // - 2 goals (SHO boost)
  // - 3 assists (PAS boost)
  // - High work rate (PHY boost)

  const postMatchEvaluation = CoachEvaluation(
    paceRating: 75,
    shootingRating: 90, // ⬆️ Boosted due to goals
    passingRating: 88, // ⬆️ Boosted due to assists
    dribblingRating: 78,
    defendingRating: 50,
    physicalRating: 85, // ⬆️ Boosted due to work rate
    physicalCondition: 0.8, // Tired after match
    recentPerformance: 0.95, // Excellent recent form
  );

  attributesStore.submitEvaluation(
    playerId: 'match_player',
    playerName: 'Match Player', // Placeholder
    position: 'ST',
    evaluation: postMatchEvaluation,
    ratedById:
        FirebaseAuth.instance.currentUser?.uid ??
        'match_coach_id', // Placeholder
    ratedByName:
        FirebaseAuth.instance.currentUser?.displayName ??
        'Match Coach', // Placeholder
    ratedByRole: 'coach',
  );

  // Player's card reflects improved performance
  // This is how FIFA Career Mode works - performance affects ratings
}
