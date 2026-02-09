import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedFutCardBackground extends StatefulWidget {
  final Widget child;
  final int? updateTrigger; // Sum of attributes to trigger pulse

  const AnimatedFutCardBackground({
    super.key,
    required this.child,
    this.updateTrigger,
  });

  @override
  State<AnimatedFutCardBackground> createState() =>
      _AnimatedFutCardBackgroundState();
}

class _AnimatedFutCardBackgroundState extends State<AnimatedFutCardBackground>
    with TickerProviderStateMixin {
  // 1. Kickoff Reveal
  late final AnimationController _kickoffController;
  late final Animation<double> _kickoffAnimation;

  // 2. Live Match Energy (Loop)
  late final AnimationController _loopController;

  // 3. Event Pulse
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  double _pulseIntensity = 0.0;

  // 4. Premium 3D Tilt (New)
  late final AnimationController _tiltController;
  late final Animation<double> _tiltXAnimation;
  late final Animation<double> _tiltYAnimation;

  @override
  void initState() {
    super.initState();

    // --- Kickoff Reveal Setup ---
    _kickoffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Slide up (10px -> -2px -> 0px) with micro snap-back
    _kickoffAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 10.0,
          end: -2.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 80,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -2.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ]).animate(_kickoffController);

    _kickoffController.forward();

    // --- Live Match Loop Setup ---
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // --- Event Pulse Setup ---
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // --- Premium 3D Tilt Setup ---
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Long, subtle duration
    )..repeat(reverse: true); // Oscillate back and forth

    // Very low amplitude rotations (radians)
    _tiltXAnimation =
        Tween<double>(
          begin: -0.02, // ~1.15 degrees
          end: 0.02, // ~-1.15 degrees
        ).animate(
          CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut),
        );

    _tiltYAnimation =
        Tween<double>(
          begin: -0.015, // ~0.86 degrees
          end: 0.015, // ~-0.86 degrees
        ).animate(
          CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(AnimatedFutCardBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger pulse if attributes changed
    if (oldWidget.updateTrigger != null &&
        widget.updateTrigger != null &&
        oldWidget.updateTrigger != widget.updateTrigger) {
      final diff = (widget.updateTrigger! - oldWidget.updateTrigger!).abs();
      // Normalize intensity based on change magnitude
      _pulseIntensity = (diff / 5.0).clamp(0.3, 1.0);

      _pulseController
          .forward(from: 0.0)
          .then((_) => _pulseController.reverse());
    }
  }

  @override
  void dispose() {
    _kickoffController.dispose();
    _loopController.dispose();
    _pulseController.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _kickoffController,
        _loopController,
        _pulseController,
        _tiltController,
      ]),
      child: widget.child,
      builder: (context, child) {
        // 1. Kickoff Translation
        final slideY = _kickoffAnimation.value;

        // 2. Loop Calculation (Fast -> Slow -> Fast)
        final t = _loopController.value;
        // Custom curve: t + A * sin(2*pi*t) creates velocity variation
        final sweepPos = t + 0.15 * math.sin(2 * math.pi * t);

        // Flicker effect (high frequency noise) - reduced for premium feel
        final flicker = 0.01 * math.sin(t * 30) * math.sin(t * 15);

        // 3. Pulse Opacity
        final pulseOpacity = _pulseAnimation.value * _pulseIntensity * 0.8;

        // 4. 3D Tilt Values
        final tiltX = _tiltXAnimation.value;
        final tiltY = _tiltYAnimation.value;

        // Create 3D perspective transform
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateX(tiltX)
          ..rotateY(tiltY);

        return Transform.translate(
          offset: Offset(0, slideY),
          child: Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: Stack(
              children: [
                // Base Card
                child!,

                // Event Pulse Glow
                if (_pulseController.isAnimating)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFD700,
                              ).withOpacity(pulseOpacity),
                              blurRadius: 15 + (pulseOpacity * 10),
                              spreadRadius: 2 * pulseOpacity,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Premium Light Sweep Overlay (Diagonal)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment(
                            -1.5 + (sweepPos * 3.0),
                            -1.0 + (sweepPos * 0.5),
                          ),
                          end: Alignment(
                            0.5 + (sweepPos * 3.0),
                            1.5 - (sweepPos * 0.5),
                          ),
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(
                              0.02 + flicker.abs() * 0.5,
                            ), // Very subtle
                            Colors.white.withOpacity(
                              0.08 + flicker.abs(),
                            ), // Soft highlight
                            Colors.white.withOpacity(
                              0.02 + flicker.abs() * 0.5,
                            ),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.overlay,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white, // Required for ShaderMask
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
