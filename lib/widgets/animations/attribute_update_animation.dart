import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ✨ Attribute Update Animation Widget
///
/// Smooth, subtle animation when player attributes change.
/// FIFA-style with progressive background fill.
///
/// Features:
/// - Background fills from bottom to top based on value
/// - Color coded ranges (Red -> Orange -> Green -> Teal)
/// - Static text overlay
/// - Duration: 500ms
///
/// Usage:
/// ```dart
/// AnimatedAttributeValue(
///   value: playerAttributes.pace,
///   label: 'PAC',
/// )
/// ```
class AnimatedAttributeValue extends StatefulWidget {
  final int value;
  final String label;
  final double scale;

  const AnimatedAttributeValue({
    super.key,
    required this.value,
    required this.label,
    this.scale = 1.0,
  });

  @override
  State<AnimatedAttributeValue> createState() => _AnimatedAttributeValueState();
}

class _AnimatedAttributeValueState extends State<AnimatedAttributeValue> {
  double _fillFactor = 0.0;

  @override
  void initState() {
    super.initState();
    // Animate from 0 to value on first appearance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _fillFactor = widget.value / 100.0;
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedAttributeValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate to new value when it changes
    if (oldWidget.value != widget.value) {
      setState(() {
        _fillFactor = widget.value / 100.0;
      });
    }
  }

  /// 🎨 Resolve fill color based on value range (Discrete)
  Color _getFillColor(int value) {
    if (value <= 40) {
      return const Color(0xFFEF5350).withOpacity(0.6); // Weak (Red)
    } else if (value <= 70) {
      return const Color(0xFFFFA726).withOpacity(0.6); // Average (Orange)
    } else if (value <= 85) {
      return const Color(0xFF9CCC65).withOpacity(0.6); // Good (Light Green)
    } else {
      return const Color(0xFF26A69A).withOpacity(0.6); // Elite (Premium Teal)
    }
  }

  /// 🎨 Resolve text color based on value
  Color _getAttributeTextColor(int value) {
    if (value >= 90) {
      return const Color(0xFFFFD700); // Elite Gold
    } else if (value >= 80) {
      return const Color(0xFFFFA500); // Gold
    } else if (value >= 70) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (value >= 60) {
      return const Color(0xFFCD7F32); // Bronze
    } else {
      return Colors.white70; // Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final double boxHeight = 52 * widget.scale;
    final double boxWidth = 75 * widget.scale;
    // Calculate fill height based on value (0-100)
    final double targetHeight = (boxHeight * _fillFactor).clamp(0.0, boxHeight);

    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2218).withOpacity(0.85),
        borderRadius: BorderRadius.circular(6 * widget.scale),
        border: Border.all(
          color: const Color(0xFF8B6F47).withOpacity(0.5),
          width: 1.5 * widget.scale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Animated Fill Layer (Bottom -> Top)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: boxWidth,
            height: targetHeight,
            decoration: BoxDecoration(
              color: _getFillColor(widget.value),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4.5 * widget.scale),
                bottomRight: Radius.circular(4.5 * widget.scale),
              ),
            ),
          ),

          // 2. Static Content Layer (Text)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.value.toString(),
                  style: GoogleFonts.saira(
                    fontSize: 18 * widget.scale,
                    fontWeight: FontWeight.w900,
                    color: _getAttributeTextColor(widget.value),
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 2 * widget.scale,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2 * widget.scale),
                Text(
                  widget.label,
                  style: GoogleFonts.saira(
                    fontSize: 10 * widget.scale,
                    color: const Color(0xFFB8A88A),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
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

/// 🎯 Attribute Grid with Animations
///
/// Complete 2x3 grid with animated attribute values
class AnimatedAttributeGrid extends StatelessWidget {
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final double scale;
  final String? position;

  const AnimatedAttributeGrid({
    super.key,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    this.scale = 1.0,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    // GK Special Layout (4 Attributes: PAS, SAV, CS, GR)
    if (position?.toUpperCase() == 'GK') {
      return SizedBox(
        width: 170 * scale, // Force 2x2 grid
        child: Wrap(
          spacing: 8 * scale,
          runSpacing: 8 * scale,
          alignment: WrapAlignment.center,
          children: [
            AnimatedAttributeValue(value: passing, label: 'PAS', scale: scale),
            AnimatedAttributeValue(
              value: defending,
              label: 'SAV',
              scale: scale,
            ),
            AnimatedAttributeValue(value: physical, label: 'CS', scale: scale),
            AnimatedAttributeValue(value: pace, label: 'GR', scale: scale),
          ],
        ),
      );
    }

    return SizedBox(
      width: 250 * scale,
      child: Wrap(
        spacing: 8 * scale,
        runSpacing: 8 * scale,
        alignment: WrapAlignment.center,
        children: [
          AnimatedAttributeValue(value: pace, label: 'PAC', scale: scale),
          AnimatedAttributeValue(value: shooting, label: 'SHO', scale: scale),
          AnimatedAttributeValue(value: passing, label: 'PAS', scale: scale),
          AnimatedAttributeValue(value: dribbling, label: 'DRI', scale: scale),
          AnimatedAttributeValue(value: defending, label: 'DEF', scale: scale),
          AnimatedAttributeValue(value: physical, label: 'PHY', scale: scale),
        ],
      ),
    );
  }
}
