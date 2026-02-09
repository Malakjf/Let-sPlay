import 'package:flutter/material.dart';
import '../models/players_view_mode.dart';

class PlayersTabs extends StatelessWidget {
  final PlayersViewMode selectedMode;
  final Function(PlayersViewMode) onModeChanged;
  final bool isArabic;

  const PlayersTabs({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context,
              isArabic ? 'القائمة' : 'Roster',
              PlayersViewMode.roster,
              theme,
            ),
          ),
          Expanded(
            child: _buildTab(
              context,
              isArabic ? 'المدفوعات' : 'Payments',
              PlayersViewMode.payments,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    PlayersViewMode mode,
    ThemeData theme,
  ) {
    final isSelected = selectedMode == mode;
    return InkWell(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : Colors.white60,
          ),
        ),
      ),
    );
  }
}
