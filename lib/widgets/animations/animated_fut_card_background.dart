import 'package:flutter/material.dart';

/// ✨ Animated Background Wrapper for FUT Cards
///
/// Adds a premium "foil" shimmer effect to the card.
/// - Subtle light sweep (left -> right)
/// - Continuous loop
/// - FIFA / EA Sports style
/// - Affects background feel without changing content
class AnimatedFutCardBackground extends StatefulWidget {
  final Widget child;

  const AnimatedFutCardBackground({super.key, required this.child});

  @override
  State<AnimatedFutCardBackground> createState() =>
      _AnimatedFutCardBackgroundState();
}

class _AnimatedFutCardBackgroundState extends State<AnimatedFutCardBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Slow, continuous loop (8s per cycle) for subtle premium feel
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Card (Static Content)
        widget.child,

        // 2. Animated Shimmer Overlay (The "Foil" Effect)
        // Placed on top to be visible over the opaque card background
        // Clipped to match FutCardFull's border radius (20)
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-2.5 + (_controller.value * 5), -0.3),
                        end: Alignment(-0.5 + (_controller.value * 5), 0.3),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.12), // Peak opacity
                          Colors.white.withOpacity(0.0),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
