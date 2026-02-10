import 'package:flutter/material.dart';

/// 🎯 Glow Pulse Effect - Soft glowing border animation
/// Stronger glow for high ratings (85+), subtle for lower
class GlowPulse extends StatefulWidget {
  final Widget child;
  final int rating;
  final Duration duration;

  const GlowPulse({
    super.key,
    required this.child,
    required this.rating,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    // 🎯 Glow intensity: stronger for high ratings
    final maxGlow = widget.rating >= 85 ? 16.0 : 8.0;

    _glowAnimation = Tween<double>(
      begin: 4.0,
      end: maxGlow,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        // 🎯 Glow color: gold for high ratings, subtle white for lower
        final glowColor = widget.rating >= 85
            ? const Color(0xFFFFD700).withOpacity(0.6) // Gold - stronger
            : Colors.white.withOpacity(0.3); // More visible white

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              // Primary glow - main animation
              BoxShadow(
                color: glowColor,
                blurRadius: _glowAnimation.value * 2, // Doubled for visibility
                spreadRadius: _glowAnimation.value,
              ),
              // Secondary glow for more dramatic effect
              BoxShadow(
                color: glowColor.withOpacity(0.3),
                blurRadius: _glowAnimation.value * 3.5,
                spreadRadius: _glowAnimation.value * 0.5,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
