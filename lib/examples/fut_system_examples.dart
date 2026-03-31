import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_attributes_store.dart';
import '../services/player_stats_store.dart';
import '../widgets/FutCardFull.dart';
import '../widgets/FutCardResponsive.dart';
import '../widgets/match_stats_display.dart';
import '../widgets/animations/goal_micro_animation.dart';
import '../widgets/animations/card_flip_animation.dart';

/// 🏆 COMPLETE FUT SYSTEM EXAMPLE
///
/// Demonstrates the complete FIFA-style FUT card system with:
/// - Coach-driven dynamic attributes (PAC, SHO, PAS, DRI, DEF, PHY)
/// - Match stats display (outside card)
/// - Goal animations
/// - Card flip functionality
/// - Real-time updates via Provider
///
/// ARCHITECTURE:
/// ✅ FUT card reads from PlayerAttributesStore
/// ✅ Match stats read from PlayerStatsStore
/// ✅ No static data - all dynamic
/// ✅ Updates instantly across all screens

/// 🎯 Example 1: Simple FUT Card with Stats
class SimpleFutCardExample extends StatelessWidget {
  final String playerId;

  const SimpleFutCardExample({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Player Card'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FUT Card (reads from PlayerAttributesStore)
            FutCardResponsive(
              child: FutCardFull(
                playerId: playerId,
                playerName: 'Mohamed Salah',
                position: 'RW',
                rating: 89,
                countryIcon: 'https://flagcdn.com/w320/eg.png',
                avatarUrl: 'https://example.com/salah.jpg',
              ),
            ),

            const SizedBox(height: 16),

            // Match Stats (outside card - reads from PlayerStatsStore)
            MatchStatsDisplay(playerId: playerId),
          ],
        ),
      ),
    );
  }
}

/// 🎯 Example 2: Flippable FUT Card
class FlippableFutCardExample extends StatelessWidget {
  final String playerId;

  const FlippableFutCardExample({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Flippable Card'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Consumer<PlayerAttributesStore>(
          builder: (context, attributesStore, child) {
            final attributes = attributesStore.getPlayerAttributes(playerId);

            return FlippableCard(
              frontSide: FutCardResponsive(
                child: FutCardFull(
                  playerId: playerId,
                  playerName: 'Cristiano Ronaldo',
                  position: 'ST',
                  rating: 91,
                  countryIcon: 'https://flagcdn.com/w320/pt.png',
                ),
              ),
              backSide: EnlargedMetricsBack(
                pace: attributes?.pace ?? 85,
                shooting: attributes?.shooting ?? 93,
                passing: attributes?.passing ?? 82,
                dribbling: attributes?.dribbling ?? 87,
                defending: attributes?.defending ?? 35,
                physical: attributes?.physical ?? 77,
                playerName: 'CRISTIANO RONALDO',
                backgroundColor: const Color(0xFF1A1F2E),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 🎯 Example 3: Goal Animation Trigger
class GoalAnimationExample extends StatefulWidget {
  final String playerId;
  final String matchId;

  const GoalAnimationExample({
    super.key,
    required this.playerId,
    required this.matchId,
  });

  @override
  State<GoalAnimationExample> createState() => _GoalAnimationExampleState();
}

class _GoalAnimationExampleState extends State<GoalAnimationExample> {
  void _onGoalScored() {
    final statsStore = context.read<PlayerStatsStore>();
    final currentGoals = statsStore.getStat(
      widget.playerId,
      PlayerStatsStore.statGoals,
    );

    // Show animation on FIRST goal only
    if (currentGoals == 0) {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        builder: (context) => const GoalAnimationOverlay(),
      );

      // Auto-dismiss after animation completes
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) Navigator.of(context).pop();
      });
    }

    // Increment goal stat
    statsStore.incrementStat(
      widget.matchId,
      widget.playerId,
      PlayerStatsStore.statGoals,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Goal Animation Demo'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutCardResponsive(
              child: FutCardFull(
                playerId: widget.playerId,
                playerName: 'Kylian Mbappé',
                position: 'ST',
                rating: 91,
                countryIcon: 'https://flagcdn.com/w320/fr.png',
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _onGoalScored,
              icon: const Icon(Icons.sports_soccer),
              label: const Text('SCORE GOAL'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),

            MatchStatsDisplay(playerId: widget.playerId),
          ],
        ),
      ),
    );
  }
}

/// 🎯 Example 4: Complete Player Profile with All Features
class CompletePlayerProfile extends StatelessWidget {
  final String playerId;
  final String matchId;

  const CompletePlayerProfile({
    super.key,
    required this.playerId,
    required this.matchId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A1F2E),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Player Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF64B5F6).withOpacity(0.3),
                      const Color(0xFF1A1F2E),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Flippable FUT Card
                  Consumer<PlayerAttributesStore>(
                    builder: (context, attributesStore, child) {
                      final attributes = attributesStore.getPlayerAttributes(
                        playerId,
                      );

                      return FlippableCard(
                        frontSide: FutCardResponsive(
                          child: FutCardFull(
                            playerId: playerId,
                            playerName: 'Lionel Messi',
                            position: 'RW',
                            rating: 91,
                            countryIcon: 'https://flagcdn.com/w320/ar.png',
                          ),
                        ),
                        backSide: EnlargedMetricsBack(
                          pace: attributes?.pace ?? 85,
                          shooting: attributes?.shooting ?? 92,
                          passing: attributes?.passing ?? 91,
                          dribbling: attributes?.dribbling ?? 95,
                          defending: attributes?.defending ?? 38,
                          physical: attributes?.physical ?? 65,
                          playerName: 'LIONEL MESSI',
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Match Stats
                  MatchStatsDisplay(playerId: playerId),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(context),

                  const SizedBox(height: 32),

                  // Coach Evaluation Section
                  _buildCoachEvaluationSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          context,
          icon: Icons.sports_soccer,
          label: 'Goal',
          color: const Color(0xFF4CAF50),
          onPressed: () => _recordGoal(context),
        ),
        _actionButton(
          context,
          icon: Icons.assistant_photo,
          label: 'Assist',
          color: const Color(0xFF2196F3),
          onPressed: () => _recordAssist(context),
        ),
        _actionButton(
          context,
          icon: Icons.emoji_events,
          label: 'MOTM',
          color: const Color(0xFFFFD700),
          onPressed: () => _recordMotm(context),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCoachEvaluationSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B6F47)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Coach Evaluation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Attributes update automatically when coach provides new ratings.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _simulateCoachEvaluation(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
            ),
            child: const Text('Simulate Coach Rating Update'),
          ),
        ],
      ),
    );
  }

  void _recordGoal(BuildContext context) {
    final statsStore = context.read<PlayerStatsStore>();
    final currentGoals = statsStore.getStat(
      playerId,
      PlayerStatsStore.statGoals,
    );

    if (currentGoals == 0) {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        builder: (context) => const GoalAnimationOverlay(),
      );

      Future.delayed(const Duration(milliseconds: 650), () {
        if (context.mounted) Navigator.of(context).pop();
      });
    }

    statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statGoals);
  }

  void _recordAssist(BuildContext context) {
    final statsStore = context.read<PlayerStatsStore>();
    statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statAssists);
  }

  void _recordMotm(BuildContext context) {
    final statsStore = context.read<PlayerStatsStore>();
    statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statMotm);
  }

  void _simulateCoachEvaluation(BuildContext context) {
    final attributesStore = context.read<PlayerAttributesStore>();

    // Simulate coach rating update (this will trigger attribute animations)
    attributesStore.updateFromCoachEvaluation(
      playerId: playerId,
      position: 'RW',
      evaluation: const CoachEvaluation(
        paceRating: 88,
        shootingRating: 93,
        passingRating: 92,
        dribblingRating: 96,
        defendingRating: 40,
        physicalRating: 68,
        physicalCondition: 0.95,
        recentPerformance: 0.88,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Coach evaluation updated! Watch the attributes animate.',
        ),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }
}
