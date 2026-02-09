// ⚽ EXAMPLE: How to use the refactored FutCard in your app
// This file shows practical usage examples

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/FutCardFull.dart';
import '../widgets/FutCardResponsive.dart';
import '../services/player_stats_store.dart';

// =============================================================================
// EXAMPLE 1: Display FutCard on Profile Screen
// =============================================================================

class ProfileScreen extends StatelessWidget {
  final String userId;
  final String playerName;
  final String position;
  final int rating;
  final String countryIcon;
  final String? avatarUrl;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.playerName,
    required this.position,
    required this.rating,
    required this.countryIcon,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ✅ FutCard automatically reads attributes from store
            FutCardResponsive(
              child: FutCardFull(
                playerId: userId,
                playerName: playerName,
                position: position,
                rating: rating,
                countryIcon: countryIcon,
                avatarUrl: avatarUrl,
              ),
            ),

            const SizedBox(height: 30),

            // Additional stats display (also reads from store)
            _buildStatsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, child) {
        final stats = statsStore.getPlayerStats(userId);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Career Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _statRow(
                'Goals',
                (stats[PlayerStatsStore.statGoals] ?? 0).toInt(),
              ),
              _statRow(
                'Assists',
                (stats[PlayerStatsStore.statAssists] ?? 0).toInt(),
              ),
              _statRow(
                'Yellow Cards',
                (stats[PlayerStatsStore.statYellow] ?? 0).toInt(),
              ),
              _statRow(
                'Red Cards',
                (stats[PlayerStatsStore.statRed] ?? 0).toInt(),
              ),
              _statRow(
                'MOTM Awards',
                (stats[PlayerStatsStore.statMotm] ?? 0).toInt(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 2: Display FutCard in a List (Team Screen)
// =============================================================================

class TeamScreen extends StatelessWidget {
  final String matchId;
  final List<Player> players;

  const TeamScreen({super.key, required this.matchId, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];

          // ✅ Each FutCard reads its own live attributes
          return FutCardResponsive(
            child: FutCardFull(
              playerId: player.id,
              playerName: player.name,
              position: player.position,
              rating: player.rating,
              countryIcon: player.countryIcon,
              avatarUrl: player.avatarUrl,
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 3: Match Summary Screen with Multiple Cards
// =============================================================================

class MatchSummaryScreen extends StatelessWidget {
  final String matchId;

  const MatchSummaryScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Summary')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final matchData = snapshot.data!;
          final playerIds = List<String>.from(matchData['players'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Top Performers',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ✅ Display cards for top 3 players
              // Each reads live stats - automatically shows current data
              ...playerIds
                  .take(3)
                  .map(
                    (playerId) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(playerId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) return const SizedBox();

                          final userData =
                              userSnapshot.data!.data() as Map<String, dynamic>;

                          return FutCardResponsive(
                            child: FutCardFull(
                              playerId: playerId,
                              playerName: userData['name'] ?? 'Unknown',
                              position: userData['position'] ?? 'MID',
                              rating: userData['rating'] ?? 75,
                              countryIcon: userData['countryIcon'] ?? '',
                              avatarUrl: userData['avatarUrl'],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// EXAMPLE 4: Real-Time Update Demo
// =============================================================================

class RealTimeStatsDemo extends StatefulWidget {
  final String matchId;
  final String playerId;

  const RealTimeStatsDemo({
    super.key,
    required this.matchId,
    required this.playerId,
  });

  @override
  State<RealTimeStatsDemo> createState() => _RealTimeStatsDemoState();
}

class _RealTimeStatsDemoState extends State<RealTimeStatsDemo> {
  @override
  void initState() {
    super.initState();
    // Initialize store
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerStatsStore>().initializeForMatch(widget.matchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Stats Demo')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              // ✅ FutCard shows live attributes
              child: FutCardResponsive(
                child: FutCardFull(
                  playerId: widget.playerId,
                  playerName: 'Hassan Hamdy',
                  position: 'ST',
                  rating: 88,
                  countryIcon: 'https://flagcdn.com/eg.svg',
                ),
              ),
            ),
          ),

          const Divider(),

          // Control buttons - update stats
          Expanded(flex: 1, child: _buildControlPanel()),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, child) {
        final goals = statsStore.getStat(
          widget.playerId,
          PlayerStatsStore.statGoals,
        );
        final assists = statsStore.getStat(
          widget.playerId,
          PlayerStatsStore.statAssists,
        );
        final motm = statsStore.getStat(
          widget.playerId,
          PlayerStatsStore.statMotm,
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Update Stats (Card updates instantly)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Goals Control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Goals: $goals', style: const TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () => statsStore.decrementStat(
                          widget.matchId,
                          widget.playerId,
                          PlayerStatsStore.statGoals,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () => statsStore.incrementStat(
                          widget.matchId,
                          widget.playerId,
                          PlayerStatsStore.statGoals,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Assists Control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Assists: $assists',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () => statsStore.decrementStat(
                          widget.matchId,
                          widget.playerId,
                          PlayerStatsStore.statAssists,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: () => statsStore.incrementStat(
                          widget.matchId,
                          widget.playerId,
                          PlayerStatsStore.statAssists,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // MOTM Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('MOTM: $motm', style: const TextStyle(fontSize: 16)),
                  ElevatedButton(
                    onPressed: () {
                      if (motm == 0) {
                        statsStore.updateStat(
                          widget.matchId,
                          widget.playerId,
                          PlayerStatsStore.statMotm,
                          1,
                        );
                      } else {
                        statsStore.updateStat(
                          widget.matchId,
                          widget.playerId,
                          PlayerStatsStore.statMotm,
                          0,
                        );
                      }
                    },
                    child: Text(motm == 0 ? 'Award MOTM' : 'Remove MOTM'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

class Player {
  final String id;
  final String name;
  final String position;
  final int rating;
  final String countryIcon;
  final String? avatarUrl;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.rating,
    required this.countryIcon,
    this.avatarUrl,
  });
}

// =============================================================================
// COMPARISON: BEFORE vs AFTER
// =============================================================================

// ❌ BEFORE: Anti-Pattern
class OldFutCardUsage extends StatelessWidget {
  const OldFutCardUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // ❌ Query Firestore every build
      future: FirebaseFirestore.instance
          .collection('player_stats')
          .doc('player123')
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        // ❌ Passing stats as parameter - creates stale copy
        return const Text('Old FutCard would go here');
      },
    );
  }
}

// ✅ AFTER: PlayFootball.me Pattern
class NewFutCardUsage extends StatelessWidget {
  const NewFutCardUsage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Simple - just pass ID and static data
    // Card reads live attributes from store automatically
    return const FutCardResponsive(
      child: FutCardFull(
        playerId: 'player123',
        playerName: 'Hassan',
        position: 'ST',
        rating: 88,
        countryIcon: 'https://flagcdn.com/eg.svg',
      ),
    );
  }
}

// =============================================================================
// KEY BENEFITS
// =============================================================================

/*
✅ REAL-TIME SYNC
- Coach updates evaluation → FutCard updates instantly
- No manual refresh needed
- All screens stay in sync

✅ PERFORMANCE
- No repeated Firestore queries
- Only Consumer widgets rebuild
- Debounced writes (efficient)

✅ SIMPLICITY
- No FutureBuilder in lists
- No prop drilling
- No state management in widgets

✅ RELIABILITY
- Single source of truth (PlayerAttributesStore)
- No stale data
- No sync bugs

✅ COACH-DRIVEN
- Attributes calculated dynamically
- Position-based base values
- Fitness and form modifiers
- Easy to maintain
*/
