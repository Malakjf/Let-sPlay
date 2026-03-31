import 'package:flutter/material.dart';

/// 🥅 Goal Micro Animation Widget
///
/// FIFA-style celebration animation triggered when a goal is scored.
/// Shows a football entering a virtual net with smooth fade-out.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierColor: Colors.transparent,
///   builder: (context) => GoalMicroAnimation(
///     onComplete: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
class GoalMicroAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;

  const GoalMicroAnimation({
    super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<GoalMicroAnimation> createState() => _GoalMicroAnimationState();
}

class _GoalMicroAnimationState extends State<GoalMicroAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _ballPosition;
  late Animation<double> _fadeOut;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    // Ball moves into the net (upward + slight curve)
    _ballPosition = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));

    // Fade out in the last 30% of animation
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Scale up slightly for impact
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.3,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    // Start animation
    _controller.forward().then((_) {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Transform.translate(
              offset: Offset(
                _ballPosition.value.dx * 100,
                _ballPosition.value.dy * 100,
              ),
              child: Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    '⚽',
                    style: TextStyle(fontSize: 60),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 🎯 Goal Animation Overlay
///
/// Shows goal animation with net visual effect
class GoalAnimationOverlay extends StatelessWidget {
  const GoalAnimationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Net background (subtle)
          Positioned.fill(child: CustomPaint(painter: _NetPainter())),
          // Ball animation
          const Center(child: GoalMicroAnimation()),
        ],
      ),
    );
  }
}

/// 🥅 Net visual painter
class _NetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw grid in center area (net effect)
    for (var i = -5; i <= 5; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(centerX + i * gridSize, centerY - 150),
        Offset(centerX + i * gridSize, centerY + 150),
        paint,
      );
      // Horizontal lines
      canvas.drawLine(
        Offset(centerX - 150, centerY + i * gridSize),
        Offset(centerX + 150, centerY + i * gridSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
