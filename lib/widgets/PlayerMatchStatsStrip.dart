import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:letsplay/services/player_stats_store.dart';

class PlayerMatchStatsStrip extends StatelessWidget {
  final String playerId;
  final bool isGk;

  const PlayerMatchStatsStrip({
    super.key,
    required this.playerId,
    this.isGk = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStatsStore>(
      builder: (context, store, child) {
        final stats = store.getPlayerStats(playerId);
        final isGoalkeeper = isGk;

        // Always render the same stat row for all positions
        final goals = isGoalkeeper
            ? 0
            : (stats[PlayerStatsStore.statGoals] ?? 0).toInt();
        final assists = isGoalkeeper
            ? 0
            : (stats[PlayerStatsStore.statAssists] ?? 0).toInt();
        final redCards = (stats[PlayerStatsStore.statRed] ?? 0).toInt();
        final yellowCards = (stats[PlayerStatsStore.statYellow] ?? 0).toInt();
        final motm = (stats[PlayerStatsStore.statMotm] ?? 0).toInt();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: [
              _buildStatItem(
                context,
                Icons.sports_soccer,
                goals,
                'Goals',
                null,
              ),
              _buildStatItem(
                context,
                Icons.compare_arrows,
                assists,
                'Assists',
                null,
              ),
              _buildStatItem(
                context,
                Icons.style,
                redCards,
                'Red',
                Colors.redAccent,
              ),
              _buildStatItem(
                context,
                Icons.style,
                yellowCards,
                'Yellow',
                Colors.yellowAccent,
              ),
              _buildStatItem(
                context,
                Icons.emoji_events,
                motm,
                'MOTM',
                const Color(0xFFFFD700), // Gold
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    int value,
    String label,
    Color? fixedColor,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use fixed color if provided (for cards/trophy), otherwise theme-aware muted color
    final iconColor = fixedColor ?? (isDark ? Colors.white70 : Colors.black54);
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: labelColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
