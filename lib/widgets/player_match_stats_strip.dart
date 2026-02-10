import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/player_stats_store.dart';

/// 📊 Live Match Stats Strip
///
/// Displays referee-entered statistics directly from PlayerStatsStore.
/// - Read-only
/// - Auto-updates via Provider
/// - No fake numbers
/// - Flat, minimal design
class PlayerMatchStatsStrip extends StatelessWidget {
  final String playerId;

  const PlayerMatchStatsStrip({super.key, required this.playerId});

  @override
  Widget build(BuildContext context) {
    // 1. Read from Provider (Live updates)
    final store = context.watch<PlayerStatsStore>();
    final hasData = store.hasPlayer(playerId);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat(
            Icons.sports_soccer,
            store.getStat(playerId, PlayerStatsStore.statGoals).toInt(),
            'Goals',
            Colors.white,
            hasData,
          ),
          _buildStat(
            Icons.arrow_upward_rounded,
            store.getStat(playerId, PlayerStatsStore.statAssists).toInt(),
            'Assists',
            Colors.blueAccent,
            hasData,
          ),
          _buildStat(
            Icons.style, // Card icon
            store.getStat(playerId, PlayerStatsStore.statYellow).toInt(),
            'Yellow',
            Colors.yellowAccent,
            hasData,
          ),
          _buildStat(
            Icons.style, // Card icon
            store.getStat(playerId, PlayerStatsStore.statRed).toInt(),
            'Red',
            Colors.redAccent,
            hasData,
          ),
          _buildStat(
            Icons.emoji_events,
            store.getStat(playerId, PlayerStatsStore.statMotm).toInt(),
            'MOTM',
            Colors.amber,
            hasData,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    int value,
    String label,
    Color color,
    bool hasData,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          hasData ? '$value' : '--',
          style: GoogleFonts.saira(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
