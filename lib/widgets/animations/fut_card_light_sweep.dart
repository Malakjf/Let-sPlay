import 'package:flutter/material.dart';

/// ✨ Premium Light Sweep Animation
///
/// A subtle, diagonal light sweep that passes over the card background.
/// - Runs once every 7 seconds
/// - Duration: 1.2 seconds
/// - Purely visual (IgnorePointer)
/// - Adds a "Rare/Premium" feel without movement
class FutCardLightSweep extends StatefulWidget {
  const FutCardLightSweep({super.key});

  @override
  State<FutCardLightSweep> createState() => _FutCardLightSweepState();
}

class _FutCardLightSweepState extends State<FutCardLightSweep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _startAnimationLoop();
  }

  void _startAnimationLoop() async {
    while (mounted) {
      // Wait for 6-8 seconds interval
      await Future.delayed(const Duration(seconds: 7));
      if (mounted) {
        await _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SweepPainter(_controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  final double progress;

  _SweepPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0 || progress == 1.0) return;

    final rect = Offset.zero & size;
    final paint = Paint();

    // Map progress to gradient movement (Top-Left to Bottom-Right)
    // Start well outside (-2.0) and end well outside (2.0) to ensure full pass
    final step = 4.0 * progress;
    final start = -2.0 + step;
    final end = 0.5 + step;

    paint.shader = LinearGradient(
      begin: Alignment(start, start * 0.6), // Slight angle adjustment
      end: Alignment(end, end * 0.6),
      colors: [
        Colors.white.withOpacity(0.0),
        const Color(0xFFFFD700).withOpacity(0.05), // Subtle Gold
        Colors.white.withOpacity(0.1), // Peak White (Low Opacity)
        const Color(0xFFFFD700).withOpacity(0.05), // Subtle Gold
        Colors.white.withOpacity(0.0),
      ],
      stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
    ).createShader(rect);

    // Draw the sweep over the card area
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_SweepPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
