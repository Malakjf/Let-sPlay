import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_stats_store.dart';
import '../services/player_metrics_store.dart';

/// Example: FUTCardWidget reading live stats from PlayerStatsStore
///
/// This widget automatically updates whenever stats change in the store.
/// No FutureBuilder, no duplicated queries.
class FUTCardWidget extends StatelessWidget {
  final String playerId;
  final String playerName;
  final String? imageUrl;

  const FUTCardWidget({
    super.key,
    required this.playerId,
    required this.playerName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to PlayerStatsStore changes
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, _) {
        // Get all stats for this player - automatically rebuilds when any stat changes
        final stats = statsStore.getPlayerStats(playerId);
        final goals = (stats[PlayerStatsStore.statGoals] ?? 0).toInt();
        final assists = (stats[PlayerStatsStore.statAssists] ?? 0).toInt();
        final yellowCards = (stats[PlayerStatsStore.statYellow] ?? 0).toInt();
        final redCards = (stats[PlayerStatsStore.statRed] ?? 0).toInt();
        final motm = (stats[PlayerStatsStore.statMotm] ?? 0).toInt();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            children: [
              // Player card header
              if (imageUrl != null)
                Image.network(imageUrl!, height: 200, fit: BoxFit.cover)
              else
                Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Icon(Icons.person, size: 100),
                ),

              const SizedBox(height: 12),

              // Player name
              Text(
                playerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Stats grid - LIVE FROM STORE
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 24,
                runSpacing: 24,
                children: [
                  _StatBadge(label: 'Goals', value: goals, color: Colors.blue),
                  _StatBadge(
                    label: 'Assists',
                    value: assists,
                    color: Colors.green,
                  ),
                  _StatBadge(
                    label: 'Yellow',
                    value: yellowCards,
                    color: Colors.yellow,
                  ),
                  _StatBadge(label: 'Red', value: redCards, color: Colors.red),
                  _StatBadge(label: 'MOTM', value: motm, color: Colors.orange),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Example: ProfileScreen reading live stats
/// Shows career stats across all matches
class PlayerProfileStatsSection extends StatelessWidget {
  final String playerId;
  final String playerName;

  const PlayerProfileStatsSection({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, _) {
        final stats = statsStore.getPlayerStats(playerId);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$playerName - Career Stats',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _ProfileStatTile(
                      label: 'Goals',
                      value: (stats[PlayerStatsStore.statGoals] ?? 0).toInt(),
                      icon: Icons.sports_soccer,
                    ),
                    _ProfileStatTile(
                      label: 'Assists',
                      value: (stats[PlayerStatsStore.statAssists] ?? 0).toInt(),
                      icon: Icons.swap_vert,
                    ),
                    _ProfileStatTile(
                      label: 'Yellow Cards',
                      value: (stats[PlayerStatsStore.statYellow] ?? 0).toInt(),
                      icon: Icons.warning,
                    ),
                    _ProfileStatTile(
                      label: 'Red Cards',
                      value: (stats[PlayerStatsStore.statRed] ?? 0).toInt(),
                      icon: Icons.stop_circle,
                    ),
                    _ProfileStatTile(
                      label: 'MOTM',
                      value: (stats[PlayerStatsStore.statMotm] ?? 0).toInt(),
                      icon: Icons.emoji_events,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _ProfileStatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12)),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Example: PlayerMetrics display in ProfileScreen
class PlayerMetricsSection extends StatelessWidget {
  final String playerId;

  const PlayerMetricsSection({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerMetricsStore>(
      builder: (context, metricsStore, _) {
        final metrics = metricsStore.getPlayerMetrics(playerId);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Ratings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...PlayerMetricsStore.allMetricTypes.map((metric) {
                  final value = metrics[metric] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 50, child: Text(metric)),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: value / 99,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text('$value', textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
