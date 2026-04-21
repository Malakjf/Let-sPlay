import 'package:flutter/material.dart';
import '../widgets/color_palette_selector.dart';

/// A reusable color picker for team selection.
/// Provides a horizontal palette and a dynamic preview.
class TeamColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final String label;
  final Color fallbackColor;

  const TeamColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChanged,
    required this.label,
    this.fallbackColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Use the new dynamic AdvancedColorPicker
            Flexible(
              child: AdvancedColorPicker(
                selectedColor: selectedColor,
                onColorChanged: onColorChanged,
                title: 'Team Color',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
