import 'package:flutter/material.dart';

/// 🎯 Animated Attribute Box - Value change animation
/// Triggers when PAC/SHO/PAS/DRI/DEF/PHY values change
/// Animates: Scale up → Color pulse (gold) → Fade back
class AnimatedAttributeBox extends StatefulWidget {
  final int value;
  final String label;
  final Duration duration;

  const AnimatedAttributeBox({
    super.key,
    required this.value,
    required this.label,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<AnimatedAttributeBox> createState() => _AnimatedAttributeBoxState();
}

class _AnimatedAttributeBoxState extends State<AnimatedAttributeBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;
  late int _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _setupAnimations();
  }

  void _setupAnimations() {
    // 🎯 Scale: 1.0 → 1.15 → 1.0 (pop effect)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // 🎯 Color pulse: Normal → Gold → Normal
    _colorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(AnimatedAttributeBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != _previousValue) {
      _previousValue = widget.value;
      _controller.forward(from: 0);
    }
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
      builder: (context, child) {
        // 🎯 Calculate color: white → gold → white
        final colorValue = _colorAnimation.value;
        final glowColor = Color.lerp(
          Colors.white,
          const Color(0xFFFFD700), // Gold
          colorValue,
        )!;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: glowColor.withOpacity(colorValue * 0.6),
                width: 1,
              ),
              boxShadow: colorValue > 0
                  ? [
                      BoxShadow(
                        color: glowColor.withOpacity(colorValue * 0.3),
                        blurRadius: colorValue * 8,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
