import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_attributes_store.dart';
import '../services/player_stats_store.dart';
import '../widgets/FutCardFull.dart';
import '../widgets/FutCardResponsive.dart';
import '../widgets/match_stats_display.dart';
import '../widgets/animations/goal_micro_animation.dart';
import '../widgets/animations/card_flip_animation.dart';

/// 🎯 FUT Card Demo Page
///
/// Self-contained demo that works without needing real match/player data
/// Perfect for testing and showcasing the FUT card system
class FutCardDemoPage extends StatefulWidget {
  const FutCardDemoPage({super.key});

  @override
  State<FutCardDemoPage> createState() => _FutCardDemoPageState();
}

class _FutCardDemoPageState extends State<FutCardDemoPage> {
  final String _demoPlayerId = 'demo_player_001';
  final String _demoMatchId = 'demo_match_001';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  Future<void> _initializeDemoData() async {
    // Initialize stores with demo data
    final attributesStore = context.read<PlayerAttributesStore>();
    final statsStore = context.read<PlayerStatsStore>();

    // Set up demo player attributes
    attributesStore.updateFromCoachEvaluation(
      playerId: _demoPlayerId,
      position: 'RW',
      evaluation: const CoachEvaluation(
        paceRating: 89,
        shootingRating: 92,
        passingRating: 85,
        dribblingRating: 91,
        defendingRating: 35,
        physicalRating: 75,
        physicalCondition: 0.95,
        recentPerformance: 0.88,
      ),
    );

    // Initialize match stats
    await statsStore.initializeForMatch(_demoMatchId);

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF64B5F6)),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          title: const Text('FUT Card System Demo'),
          backgroundColor: const Color(0xFF1A1F2E),
          bottom: const TabBar(
            indicatorColor: Color(0xFF64B5F6),
            tabs: [
              Tab(icon: Icon(Icons.credit_card), text: 'Card'),
              Tab(icon: Icon(Icons.flip), text: 'Flip'),
              Tab(icon: Icon(Icons.sports_soccer), text: 'Goal'),
              Tab(icon: Icon(Icons.apps), text: 'All'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSimpleCardDemo(),
            _buildFlipCardDemo(),
            _buildGoalAnimationDemo(),
            _buildCompleteDemo(),
          ],
        ),
      ),
    );
  }

  // Tab 1: Simple Card
  Widget _buildSimpleCardDemo() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Basic FUT Card',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutCardResponsive(
              child: FutCardFull(
                playerId: _demoPlayerId,
                playerName: 'Mohamed Salah',
                position: 'RW',
                rating: 89,
                countryIcon: 'https://flagcdn.com/w320/eg.png',
              ),
            ),
            const SizedBox(height: 16),
            MatchStatsDisplay(playerId: _demoPlayerId),
          ],
        ),
      ),
    );
  }

  // Tab 2: Flippable Card
  Widget _buildFlipCardDemo() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap to Flip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See enlarged metrics on back',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Consumer<PlayerAttributesStore>(
              builder: (context, attributesStore, child) {
                final attributes = attributesStore.getPlayerAttributes(
                  _demoPlayerId,
                );

                return FlippableCard(
                  frontSide: FutCardResponsive(
                    child: FutCardFull(
                      playerId: _demoPlayerId,
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
          ],
        ),
      ),
    );
  }

  // Tab 3: Goal Animation
  Widget _buildGoalAnimationDemo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutCardResponsive(
            child: FutCardFull(
              playerId: _demoPlayerId,
              playerName: 'Kylian Mbappé',
              position: 'ST',
              rating: 91,
              countryIcon: 'https://flagcdn.com/w320/fr.png',
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _triggerGoalAnimation,
            icon: const Icon(Icons.sports_soccer, size: 32),
            label: const Text(
              'SCORE GOAL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),
          MatchStatsDisplay(playerId: _demoPlayerId),
        ],
      ),
    );
  }

  // Tab 4: Complete Demo
  Widget _buildCompleteDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Complete System',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<PlayerAttributesStore>(
            builder: (context, attributesStore, child) {
              final attributes = attributesStore.getPlayerAttributes(
                _demoPlayerId,
              );

              return FlippableCard(
                frontSide: FutCardResponsive(
                  child: FutCardFull(
                    playerId: _demoPlayerId,
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
          MatchStatsDisplay(playerId: _demoPlayerId),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 32),
          _buildCoachEvaluationCard(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          icon: Icons.sports_soccer,
          label: 'Goal',
          color: const Color(0xFF4CAF50),
          onPressed: _triggerGoalAnimation,
        ),
        _actionButton(
          icon: Icons.assistant_photo,
          label: 'Assist',
          color: const Color(0xFF2196F3),
          onPressed: _recordAssist,
        ),
        _actionButton(
          icon: Icons.emoji_events,
          label: 'MOTM',
          color: const Color(0xFFFFD700),
          onPressed: _recordMotm,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildCoachEvaluationCard() {
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
          const SizedBox(height: 12),
          const Text(
            'Attributes update in real-time when coach provides new ratings.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _simulateCoachUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
            ),
            child: const Text('Simulate Rating Update'),
          ),
        ],
      ),
    );
  }

  void _triggerGoalAnimation() {
    final statsStore = context.read<PlayerStatsStore>();
    final currentGoals = statsStore.getStat(
      _demoPlayerId,
      PlayerStatsStore.statGoals,
    );

    // Show animation on first goal only
    if (currentGoals == 0) {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        builder: (context) => const GoalAnimationOverlay(),
      );

      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) Navigator.of(context).pop();
      });
    }

    statsStore.incrementStat(
      _demoMatchId,
      _demoPlayerId,
      PlayerStatsStore.statGoals,
    );
  }

  void _recordAssist() {
    final statsStore = context.read<PlayerStatsStore>();
    statsStore.incrementStat(
      _demoMatchId,
      _demoPlayerId,
      PlayerStatsStore.statAssists,
    );
  }

  void _recordMotm() {
    final statsStore = context.read<PlayerStatsStore>();
    statsStore.incrementStat(
      _demoMatchId,
      _demoPlayerId,
      PlayerStatsStore.statMotm,
    );
  }

  void _simulateCoachUpdate() {
    final attributesStore = context.read<PlayerAttributesStore>();

    // Update with slightly different ratings to trigger animations
    attributesStore.updateFromCoachEvaluation(
      playerId: _demoPlayerId,
      position: 'RW',
      evaluation: CoachEvaluation(
        paceRating: 90 + (DateTime.now().second % 5),
        shootingRating: 93 + (DateTime.now().second % 4),
        passingRating: 86 + (DateTime.now().second % 6),
        dribblingRating: 92 + (DateTime.now().second % 5),
        defendingRating: 36 + (DateTime.now().second % 4),
        physicalRating: 76 + (DateTime.now().second % 5),
        physicalCondition: 0.95,
        recentPerformance: 0.90,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Attributes updated! Watch them animate!'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
