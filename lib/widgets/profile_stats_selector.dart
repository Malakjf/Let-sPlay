import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileStatsSelector extends StatelessWidget {
  final String selectedStat;
  final ValueChanged<String> onStatSelected;

  const ProfileStatsSelector({
    super.key,
    required this.selectedStat,
    required this.onStatSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'key': 'goals', 'label': 'GOALS', 'icon': Icons.sports_soccer},
      {
        'key': 'assists',
        'label': 'ASSISTS',
        'icon': Icons.arrow_upward_rounded,
      },
      {
        'key': 'redCards',
        'label': 'RED',
        'icon': Icons.square,
        'color': Colors.redAccent,
      },
      {
        'key': 'yellowCards',
        'label': 'YELLOW',
        'icon': Icons.square,
        'color': Colors.yellowAccent,
      },
      {'key': 'motm', 'label': 'MOTM', 'icon': FontAwesomeIcons.trophy},
    ];

    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item['key'] == selectedStat;
          final color = item['color'] as Color?;

          return _StatItem(
            label: item['label'] as String,
            icon: item['icon'] as IconData,
            isSelected: isSelected,
            iconColor: color,
            onTap: () => onStatSelected(item['key'] as String),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color? iconColor;
  final VoidCallback onTap;

  const _StatItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2A3447) // Slightly brighter navy
              : const Color(0xFF1E293B), // Dark navy
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: primaryColor.withOpacity(0.3), width: 1)
              : Border.all(color: Colors.transparent),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? (iconColor ?? primaryColor)
                  : (iconColor?.withOpacity(0.5) ?? Colors.white38),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.white38,
                letterSpacing: 0.5,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
