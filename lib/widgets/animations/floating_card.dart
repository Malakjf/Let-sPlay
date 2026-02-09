import 'package:flutter/material.dart';

/// 🎯 Floating Card Animation - Idle breathing effect
/// Subtle vertical floating that makes the card feel alive
class FloatingCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double floatingDistance;

  const FloatingCard({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.floatingDistance = 8.0,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    // 🎯 Smooth floating: up and down infinitely
    // MORE VISIBLE: increased floating distance
    _floatAnimation = Tween<double>(
      begin: -widget.floatingDistance * 1.5, // Increased distance
      end: widget.floatingDistance * 1.5,
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
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
