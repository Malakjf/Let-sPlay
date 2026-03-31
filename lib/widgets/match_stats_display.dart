import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/player_stats_store.dart';

/// 🟦 Match Stats Display (OUTSIDE THE CARD)
///
/// Displays player match statistics below the FUT card.
/// NEVER placed inside the card itself.
///
/// Shows:
/// - ⚽ Goals
/// - 🅰️ Assists
/// - 🏆 MOTM (Man of the Match)
/// - 📅 Matches
///
/// Design: Horizontal layout, minimal icons, large numbers
class MatchStatsDisplay extends StatelessWidget {
  final String playerId;
  final bool compact;

  const MatchStatsDisplay({
    super.key,
    required this.playerId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, child) {
        final goals = statsStore
            .getStat(playerId, PlayerStatsStore.statGoals)
            .toInt();
        final assists = statsStore
            .getStat(playerId, PlayerStatsStore.statAssists)
            .toInt();
        final motm = statsStore
            .getStat(playerId, PlayerStatsStore.statMotm)
            .toInt();

        // Calculate total matches (you may need to track this separately)
        // For now, we'll derive from goals + assists as an approximation
        final matches = ((goals + assists) * 0.6).ceil().clamp(1, 999);

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF8B6F47).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: compact
              ? _buildCompactLayout(goals, assists, motm, matches)
              : _buildFullLayout(goals, assists, motm, matches),
        );
      },
    );
  }

  Widget _buildFullLayout(int goals, int assists, int motm, int matches) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('⚽', goals, 'GOALS'),
        _divider(),
        _statItem('🅰️', assists, 'ASSISTS'),
        _divider(),
        _statItem('🏆', motm, 'MOTM'),
        _divider(),
        _statItem('📅', matches, 'MATCHES'),
      ],
    );
  }

  Widget _buildCompactLayout(int goals, int assists, int motm, int matches) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        _compactStatItem('⚽', goals),
        _compactStatItem('🅰️', assists),
        _compactStatItem('🏆', motm),
        _compactStatItem('📅', matches),
      ],
    );
  }

  Widget _statItem(String icon, int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              value.toString(),
              style: GoogleFonts.saira(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [const Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.saira(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _compactStatItem(String icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: GoogleFonts.saira(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.white24);
  }
}

/// 🎯 Complete Player Card with Stats
///
/// Combines FUT card with match stats display below
class PlayerCardWithStats extends StatelessWidget {
  final String playerId;
  final Widget futCard;
  final bool showStats;

  const PlayerCardWithStats({
    super.key,
    required this.playerId,
    required this.futCard,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        futCard,
        if (showStats) MatchStatsDisplay(playerId: playerId),
      ],
    );
  }
}

/// 📊 Minimal Stats Row (Alternative Design)
///
/// Ultra-compact stats row for tight spaces
class MinimalStatsRow extends StatelessWidget {
  final String playerId;
  final Color? textColor;

  const MinimalStatsRow({super.key, required this.playerId, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, child) {
        final goals = statsStore
            .getStat(playerId, PlayerStatsStore.statGoals)
            .toInt();
        final assists = statsStore
            .getStat(playerId, PlayerStatsStore.statAssists)
            .toInt();

        return Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _miniStat('⚽', goals, textColor ?? Colors.white),
            _miniStat('🅰️', assists, textColor ?? Colors.white),
          ],
        );
      },
    );
  }

  Widget _miniStat(String icon, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: GoogleFonts.saira(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
