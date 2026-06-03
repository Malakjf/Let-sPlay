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
  final bool isGk;

  const MatchStatsDisplay({
    super.key,
    required this.playerId,
    this.compact = false,
    this.isGk = false,
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
        final yellow = statsStore
            .getStat(playerId, PlayerStatsStore.statYellow)
            .toInt();
        final red = statsStore
            .getStat(playerId, PlayerStatsStore.statRed)
            .toInt();
        final matches = statsStore
            .getStat(playerId, PlayerStatsStore.statMatches)
            .toInt();

        // GK Specific stats
        final saves = statsStore
            .getStat(playerId, PlayerStatsStore.statSaves)
            .toInt();
        final cleanSheets = statsStore
            .getStat(playerId, PlayerStatsStore.statCleanSheet)
            .toInt();

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A0E27).withOpacity(0.8),
                const Color(0xFF151B3D).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: compact
              ? _buildCompactLayout(
                  goals,
                  assists,
                  motm,
                  matches,
                  yellow,
                  red,
                  saves,
                  cleanSheets,
                )
              : _buildFullLayout(
                  goals,
                  assists,
                  motm,
                  matches,
                  yellow,
                  red,
                  saves,
                  cleanSheets,
                ),
        );
      },
    );
  }

  Widget _buildFullLayout(
    int goals,
    int assists,
    int motm,
    int matches,
    int yellow,
    int red,
    int saves,
    int cs,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (isGk) ...[
          _statItem('🧤', saves, 'SAVES'),
          _divider(),
          _statItem('🛡️', cs, 'CLEAN SHEET'),
        ] else ...[
          _statItem('⚽', goals, 'GOALS'),
          _divider(),
          _statItem('🅰️', assists, 'ASSISTS'),
        ],
        _divider(),
        _statItem('🟨', yellow, 'YELLOW'),
        _divider(),
        _statItem('🟥', red, 'RED'),
        _divider(),
        _statItem('🏆', motm, 'MOTM'),
        _divider(),
        _statItem('📅', matches, 'MATCHES'),
      ],
    );
  }

  Widget _buildCompactLayout(
    int goals,
    int assists,
    int motm,
    int matches,
    int yellow,
    int red,
    int saves,
    int cs,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 12,
      children: [
        if (isGk) ...[
          _compactStatItem('🧤', saves),
          _compactStatItem('🛡️', cs),
        ] else ...[
          _compactStatItem('⚽', goals),
          _compactStatItem('🅰️', assists),
        ],
        _compactStatItem('🟨', yellow),
        _compactStatItem('🟥', red),
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
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              value.toString(),
              style: GoogleFonts.saira(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.saira(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _compactStatItem(String icon, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          value.toString(),
          style: GoogleFonts.saira(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.08),
    );
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
        final yellow = statsStore
            .getStat(playerId, PlayerStatsStore.statYellow)
            .toInt();
        final red = statsStore
            .getStat(playerId, PlayerStatsStore.statRed)
            .toInt();

        return Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _miniStat('⚽', goals, textColor ?? Colors.white),
            _miniStat('🅰️', assists, textColor ?? Colors.white),
            _miniStat('🟨', yellow, textColor ?? Colors.white),
            _miniStat('🟥', red, textColor ?? Colors.white),
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
