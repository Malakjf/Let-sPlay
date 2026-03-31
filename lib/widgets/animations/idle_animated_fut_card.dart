import 'package:flutter/material.dart';

class IdleAnimatedFutCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;

  const IdleAnimatedFutCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
  });

  @override
  State<IdleAnimatedFutCard> createState() => _IdleAnimatedFutCardState();
}

class _IdleAnimatedFutCardState extends State<IdleAnimatedFutCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Slower breathing (Calm)
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 1.0,
      end: 1.03, // 👈 Increased slightly for visibility
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _translateY = Tween<double>(
      begin: 0,
      end: -8, // 👈 Increased vertical movement
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
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}
