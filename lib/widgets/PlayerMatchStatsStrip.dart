import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlayerMatchStatsStrip extends StatelessWidget {
  final String playerId;
  final bool isGk;
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int motm;
  final int matches;
  final int saves;
  final int cleanSheets;

  const PlayerMatchStatsStrip({
    super.key,
    required this.playerId,
    this.isGk = false,
    required this.goals,
    required this.assists,
    required this.yellowCards,
    required this.redCards,
    required this.motm,
    required this.matches,
    this.saves = 0,
    this.cleanSheets = 0,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (isGk) ...[
            _statItem(Icons.front_hand, Colors.white, saves, 'SAVES'),
            _divider(),
            _statItem(
              Icons.shield,
              Colors.blueAccent,
              cleanSheets,
              'CLEAN SHEET',
            ),
          ] else ...[
            _statItem(Icons.sports_soccer, Colors.white, goals, 'GOALS'),
            _divider(),
            _statItem(
              Icons.assistant_direction,
              Colors.blueAccent,
              assists,
              'ASSISTS',
            ),
          ],
          _divider(),
          _statItem(Icons.style, Colors.yellowAccent, yellowCards, 'YELLOW'),
          _divider(),
          _statItem(Icons.style, Colors.redAccent, redCards, 'RED'),
          _divider(),
          _statItem(Icons.emoji_events, Colors.amber, motm, 'MOTM'),
          _divider(),
          _statItem(Icons.calendar_month, Colors.white70, matches, 'MATCHES'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, Color iconColor, int value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
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
            letterSpacing: 1,
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
