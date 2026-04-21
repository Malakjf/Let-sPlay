import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'team_color_picker.dart';

/// Refactored Dialog for dynamic team color selection.
class ChooseTeamDialog extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> existingMatchData;

  const ChooseTeamDialog({
    super.key,
    required this.matchId,
    required this.existingMatchData,
  });

  @override
  State<ChooseTeamDialog> createState() => _ChooseTeamDialogState();
}

class _ChooseTeamDialogState extends State<ChooseTeamDialog> {
  // State management for dynamic colors
  late Color teamAColor;
  late Color teamBColor;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    // Load colors from Firestore data or provide defaults
    teamAColor = _parseColor(
      widget.existingMatchData['teamAColor'],
      Colors.blue,
    );
    teamBColor = _parseColor(
      widget.existingMatchData['teamBColor'],
      Colors.red,
    );
  }

  Color _parseColor(dynamic value, Color fallback) {
    if (value is int) return Color(value);
    return fallback;
  }

  Future<void> _saveColors() async {
    setState(() => isSaving = true);
    try {
      // Persistence: Update Firestore document
      await FirebaseService.instance.updateMatch(widget.matchId, {
        'teamAColor': teamAColor.value,
        'teamBColor': teamBColor.value,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving colors: $e')));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorsMatch = teamAColor.value == teamBColor.value;

    return AlertDialog(
      backgroundColor: theme.dialogBackgroundColor,
      title: const Text('Configure Teams'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TeamColorPicker(
            label: 'TEAM A',
            selectedColor: teamAColor,
            onColorChanged: (color) => setState(() => teamAColor = color),
          ),
          const SizedBox(height: 24),
          TeamColorPicker(
            label: 'TEAM B',
            selectedColor: teamBColor,
            onColorChanged: (color) => setState(() => teamBColor = color),
          ),
          if (colorsMatch)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Warning: Teams should have different colors.',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
          ),
          onPressed: (isSaving || colorsMatch) ? null : _saveColors,
          child: isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('SAVE CONFIG'),
        ),
      ],
    );
  }
}
