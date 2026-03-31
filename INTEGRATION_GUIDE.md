// 🚀 QUICK INTEGRATION GUIDE - Copy & Paste Examples
// 
// This file contains ready-to-use code snippets for integrating
// the FUT card system into your existing LetsPlay app pages.

// ═══════════════════════════════════════════════════════════════
// 📄 1. PLAYERS SCREEN INTEGRATION
// ═══════════════════════════════════════════════════════════════

// File: lib/pages/players.dart
// Add these imports at the top:

import 'package:letsplay/widgets/FutCardFull.dart';
import 'package:letsplay/widgets/match_stats_display.dart';
import 'package:letsplay/widgets/animations/goal_micro_animation.dart';

// Replace your player card widget with:

Widget _buildPlayerCard(Player player) {
  return GestureDetector(
    onTap: () => _navigateToPlayerDetails(player),
    child: Column(
      children: [
        // FUT Card (attributes from PlayerAttributesStore)
        FutCardFull(
          playerId: player.id,
          playerName: player.name,
          position: player.position,
          rating: player.overallRating,
          countryIcon: player.countryFlag,
          avatarUrl: player.photoUrl,
        ),
        
        const SizedBox(height: 12),
        
        // Match Stats (outside card)
        MatchStatsDisplay(playerId: player.id),
      ],
    ),
  );
}

// Add goal animation handler:

void _handleGoalScored(String playerId, String matchId) {
  final statsStore = context.read<PlayerStatsStore>();
  final currentGoals = statsStore.getStat(playerId, PlayerStatsStore.statGoals);

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

  // Record the goal
  statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statGoals);
}

// ═══════════════════════════════════════════════════════════════
// 📄 2. HOME PAGE / MAIN DASHBOARD
// ═══════════════════════════════════════════════════════════════

// File: lib/pages/Home.dart (or as part of MainLayout.dart)
// This is a sample dashboard screen for after the user logs in.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import 'package:letsplay/widgets/FutCardFull.dart';
import 'package:letsplay/widgets/animations/card_flip_animation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // This should not happen if AuthGate is working correctly,
      // but it's a good practice to handle it.
      return const Scaffold(body: Center(child: Text('Not logged in. Please restart the app.')));
    }

    // NOTE: Replace placeholder data with actual data from your user provider/service
    final String playerName = user.displayName ?? 'Player';
    final String playerPosition = 'ST'; // Replace with actual data
    final int playerRating = 85;       // Replace with actual data
    final String playerCountry = 'https://flagcdn.com/w320/eg.png'; // Replace

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $playerName!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Display the user's own FUT card using the flippable container
                _buildProfileCard(
                  context,
                  userId: user.uid,
                  name: playerName,
                  position: playerPosition,
                  rating: playerRating,
                  countryIcon: playerCountry,
                  avatarUrl: user.photoURL,
                ),
                
                const SizedBox(height: 8),
                _buildFlipHint(),

                const SizedBox(height: 32),
                
                // Quick Action Buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required String userId,
    required String name,
    required String position,
    required int rating,
    required String countryIcon,
    String? avatarUrl,
  }) {
    // This is the same flippable card from the Profile page integration.
    // It consumes the PlayerAttributesStore to get dynamic metrics for the back.
    return Consumer<PlayerAttributesStore>(
      builder: (context, attributesStore, child) {
        final attributes = attributesStore.getPlayerAttributes(userId);

        return FlippableCard(
          frontSide: FutCardFull(
            playerId: userId,
            playerName: name,
            position: position,
            rating: rating,
            countryIcon: countryIcon,
            avatarUrl: avatarUrl,
          ),
          backSide: EnlargedMetricsBack(
            pace: attributes?.pace ?? 50,
            shooting: attributes?.shooting ?? 50,
            passing: attributes?.passing ?? 50,
            dribbling: attributes?.dribbling ?? 50,
            defending: attributes?.defending ?? 50,
            physical: attributes?.physical ?? 50,
            playerName: name.toUpperCase(),
            backgroundColor: const Color(0xFF1A1F2E),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () { /* TODO: Navigate to Find Match screen */ },
          icon: const Icon(Icons.search),
          label: const Text('Find Match'),
        ),
        ElevatedButton.icon(
          onPressed: () { /* TODO: Navigate to Fields screen */ },
          icon: const Icon(Icons.stadium),
          label: const Text('View Fields'),
        ),
        ElevatedButton.icon(
          onPressed: () { /* TODO: Navigate to Profile screen */ },
          icon: const Icon(Icons.person),
          label: const Text('My Profile'),
        ),
      ],
    );
  }

  Widget _buildFlipHint() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, color: Colors.white54, size: 16),
          SizedBox(width: 8),
          Text(
            'Tap card to see detailed stats',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 📄 3. PROFILE PAGE INTEGRATION
// ═══════════════════════════════════════════════════════════════

// File: lib/pages/Profile.dart
// Add these imports:

import 'package:letsplay/widgets/FutCardFull.dart';
import 'package:letsplay/widgets/animations/card_flip_animation.dart';
import 'package:provider/provider.dart';
import 'package:letsplay/services/player_attributes_store.dart';

// Replace profile card section with:

Widget _buildProfileCard() {
  return Consumer<PlayerAttributesStore>(
    builder: (context, attributesStore, child) {
      final attributes = attributesStore.getPlayerAttributes(currentUserId);

      return FlippableCard(
        // Front: FUT Card
        frontSide: FutCardFull(
          playerId: currentUserId,
          playerName: currentUser.name,
          position: currentUser.position,
          rating: currentUser.overallRating,
          countryIcon: currentUser.countryFlag,
          avatarUrl: currentUser.photoUrl,
        ),
        
        // Back: Enlarged metrics
        backSide: EnlargedMetricsBack(
          pace: attributes?.pace ?? 50,
          shooting: attributes?.shooting ?? 50,
          passing: attributes?.passing ?? 50,
          dribbling: attributes?.dribbling ?? 50,
          defending: attributes?.defending ?? 50,
          physical: attributes?.physical ?? 50,
          playerName: currentUser.name.toUpperCase(),
          backgroundColor: const Color(0xFF1A1F2E),
        ),
      );
    },
  );
}

// Add hint for users:
Widget _buildFlipHint() {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_outline, color: Colors.white54, size: 16),
        SizedBox(width: 8),
        Text(
          'Tap card to see detailed stats',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// 📄 4. MATCH DETAILS PAGE INTEGRATION
// ═══════════════════════════════════════════════════════════════

// File: lib/pages/MatchDetails.dart
// Add these imports:

import 'package:letsplay/widgets/match_stats_display.dart';
import 'package:letsplay/widgets/animations/goal_micro_animation.dart';
import 'package:provider/provider.dart';
import 'package:letsplay/services/player_stats_store.dart';

// Initialize stats store for match:

@override
void initState() {
  super.initState();
  _initializeMatchStats();
}

Future<void> _initializeMatchStats() async {
  final statsStore = context.read<PlayerStatsStore>();
  await statsStore.initializeForMatch(widget.matchId);
}

// Add player stats row in match summary:

Widget _buildPlayerStatsRow(String playerId) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: MinimalStatsRow(
      playerId: playerId,
      textColor: Colors.white,
    ),
  );
}

// Record match events:

void _recordGoal(String playerId) {
  _handleGoalScored(playerId, widget.matchId);
}

void _recordAssist(String playerId) {
  final statsStore = context.read<PlayerStatsStore>();
  statsStore.incrementStat(widget.matchId, playerId, PlayerStatsStore.statAssists);
}

void _recordYellowCard(String playerId) {
  final statsStore = context.read<PlayerStatsStore>();
  statsStore.incrementStat(widget.matchId, playerId, PlayerStatsStore.statYellow);
}

void _awardMotm(String playerId) {
  final statsStore = context.read<PlayerStatsStore>();
  statsStore.incrementStat(widget.matchId, playerId, PlayerStatsStore.statMotm);
}

// Goal handler with animation:
void _handleGoalScored(String playerId, String matchId) {
  final statsStore = context.read<PlayerStatsStore>();
  final currentGoals = statsStore.getStat(playerId, PlayerStatsStore.statGoals);

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

  statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statGoals);
}

// ═══════════════════════════════════════════════════════════════
// 📄 5. SPLASH SCREEN UPDATE (OPTIONAL)
// ═══════════════════════════════════════════════════════════════

// File: lib/pages/Splash.dart
// Option A: Replace entire splash with animated version

import 'package:letsplay/widgets/animations/splash_animation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// NOTE: You may need to adjust the import paths below to match your project structure.
import 'package:letsplay/pages/Welcome.dart';
import 'package:letsplay/MainLayout.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FootballSplashAnimation(
      appName: 'LetsPlay',
      onComplete: () {
        // After the splash animation, check auth state and navigate.
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          // User is not logged in, go to the Welcome/Login screen.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        } else {
          // User is logged in, go to the main app screen.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainLayout()),
          );
        }
      },
    );
  }
}

// Option B: Add animation before existing splash

class SplashPage extends StatefulWidget {
  // ... existing code ...
  
  @override
  void initState() {
    super.initState();
    _showAnimatedSplash();
  }
  
  Future<void> _showAnimatedSplash() async {
    // Show animation for 1.2 seconds
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Then continue with existing splash logic
    _initializeLanguage();
  }
}

// ═══════════════════════════════════════════════════════════════
// 📄 6. COACH EVALUATION INTEGRATION
// ═══════════════════════════════════════════════════════════════

// File: lib/pages/Management.dart (or wherever coaches evaluate)
// Add coach rating interface:

import 'package:provider/provider.dart';
import 'package:letsplay/services/player_attributes_store.dart';

class CoachEvaluationDialog extends StatefulWidget {
  final String playerId;
  final String position;
  
  const CoachEvaluationDialog({
    super.key,
    required this.playerId,
    required this.position,
  });

  @override
  State<CoachEvaluationDialog> createState() => _CoachEvaluationDialogState();
}

class _CoachEvaluationDialogState extends State<CoachEvaluationDialog> {
  final Map<String, double> _ratings = {
    'pace': 50,
    'shooting': 50,
    'passing': 50,
    'dribbling': 50,
    'defending': 50,
    'physical': 50,
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Coach Evaluation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRatingSlider('Pace', 'pace'),
            _buildRatingSlider('Shooting', 'shooting'),
            _buildRatingSlider('Passing', 'passing'),
            _buildRatingSlider('Dribbling', 'dribbling'),
            _buildRatingSlider('Defending', 'defending'),
            _buildRatingSlider('Physical', 'physical'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitEvaluation,
          child: const Text('Save Evaluation'),
        ),
      ],
    );
  }

  Widget _buildRatingSlider(String label, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${_ratings[key]!.toInt()}'),
        Slider(
          value: _ratings[key]!,
          min: 0,
          max: 100,
          divisions: 100,
          label: _ratings[key]!.toInt().toString(),
          onChanged: (value) {
            setState(() {
              _ratings[key] = value;
            });
          },
        ),
      ],
    );
  }

  void _submitEvaluation() {
    final attributesStore = context.read<PlayerAttributesStore>();
    
    // Update player attributes using CoachEvaluation object
    attributesStore.updateFromCoachEvaluation(
      playerId: widget.playerId,
      position: widget.position,
      evaluation: CoachEvaluation(
        paceRating: _ratings['pace']!.toInt(),
        shootingRating: _ratings['shooting']!.toInt(),
        passingRating: _ratings['passing']!.toInt(),
        dribblingRating: _ratings['dribbling']!.toInt(),
        defendingRating: _ratings['defending']!.toInt(),
        physicalRating: _ratings['physical']!.toInt(),
        physicalCondition: 1.0,  // Optional: 0.0-1.0
        recentPerformance: 0.5,  // Optional: 0.0-1.0
      ),
    );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Player evaluation saved! Attributes updated.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Show dialog when coach wants to evaluate:
void _showCoachEvaluation(String playerId, String position) {
  showDialog(
    context: context,
    builder: (context) => CoachEvaluationDialog(
      playerId: playerId,
      position: position,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// 📄 7. COMPACT STATS FOR LIST VIEWS
// ═══════════════════════════════════════════════════════════════

// Use in player lists where space is limited:

import 'package:letsplay/widgets/match_stats_display.dart';

Widget _buildCompactPlayerCard(Player player) {
  return ListTile(
    leading: CircleAvatar(
      backgroundImage: NetworkImage(player.photoUrl),
    ),
    title: Text(player.name),
    subtitle: MinimalStatsRow(
      playerId: player.id,
      textColor: Colors.grey,
    ),
    trailing: Text(
      '${player.overallRating}',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.amber,
      ),
    ),
    onTap: () => _navigateToPlayerDetails(player),
  );
}

// ═══════════════════════════════════════════════════════════════
// 📄 8. TESTING YOUR INTEGRATION
// ═══════════════════════════════════════════════════════════════

// Quick test page to verify everything works:

import 'package:flutter/material.dart';
import 'package:letsplay/examples/fut_system_examples.dart';

class FutSystemTestPage extends StatelessWidget {
  const FutSystemTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FUT System Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SimpleFutCardExample(
                    playerId: 'test123',
                  ),
                ),
              );
            },
            child: const Text('Test: Simple Card'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FlippableFutCardExample(
                    playerId: 'test123',
                  ),
                ),
              );
            },
            child: const Text('Test: Flippable Card'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoalAnimationExample(
                    playerId: 'test123',
                    matchId: 'match456',
                  ),
                ),
              );
            },
            child: const Text('Test: Goal Animation'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompletePlayerProfile(
                    playerId: 'test123',
                    matchId: 'match456',
                  ),
                ),
              );
            },
            child: const Text('Test: Complete System'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🎯 9. USAGE CHECKLIST
// ═══════════════════════════════════════════════════════════════

/*

✅ Step 1: Verify Provider Setup
   - PlayerAttributesStore is in main.dart MultiProvider
   - PlayerStatsStore is in main.dart MultiProvider

✅ Step 2: Implement Home Page
   - Create a Home.dart file with the example code
   - Set it as the main destination after login

✅ Step 3: Update Players Screen
   - Replace player cards with FutCardFull
   - Add MatchStatsDisplay below cards
   - Add goal animation handler

✅ Step 3: Update Profile Page
   - Use FlippableCard for user's own profile
   - Show enlarged metrics on flip

✅ Step 4: Update Match Details
   - Initialize PlayerStatsStore for match
   - Add event recording functions
   - Show goal animation on first goal

✅ Step 5: Add Coach Evaluation
   - Create evaluation interface
   - Call updateFromCoachEvaluation

✅ Step 6: Test Everything
   - Run FutSystemTestPage
   - Verify animations work
   - Check data persistence

*/

// ═══════════════════════════════════════════════════════════════
// 🚨 10. COMMON ISSUES & FIXES
// ═══════════════════════════════════════════════════════════════

/*

❌ Issue: Card shows default values (50, 50, 50...)
✅ Fix: Make sure PlayerAttributesStore is initialized for that player
   Code: attributesStore.updateFromCoachEvaluation(...)

❌ Issue: Stats don't update
✅ Fix: Initialize PlayerStatsStore for the match first
   Code: await statsStore.initializeForMatch(matchId)

❌ Issue: Animation doesn't show
✅ Fix: Check goal count before showing animation (first goal only)
   Code: if (currentGoals == 0) { showDialog(...) }

❌ Issue: Card doesn't flip
✅ Fix: Make sure you're using FlippableCard wrapper
   Code: FlippableCard(frontSide: ..., backSide: ...)

❌ Issue: Attributes don't animate
✅ Fix: They animate automatically via AnimatedAttributeGrid
   Just call updateFromCoachEvaluation and watch!

*/
