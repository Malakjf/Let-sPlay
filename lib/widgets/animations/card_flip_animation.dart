import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🔄 Card Flip Animation (Optional Feature)
///
/// FIFA-style card flip with Y-axis rotation.
/// Tap card to flip between front and back views.
///
/// Front: Player Card
/// Back: Enlarged performance metrics
///
/// Curve: easeOutExpo
class FlippableCard extends StatefulWidget {
  final Widget frontSide;
  final Widget backSide;
  final Duration duration;
  final bool initiallyFlipped;

  const FlippableCard({
    super.key,
    required this.frontSide,
    required this.backSide,
    this.duration = const Duration(milliseconds: 600),
    this.initiallyFlipped = false,
  });

  @override
  State<FlippableCard> createState() => FlippableCardState();
}

class FlippableCardState extends State<FlippableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();

    _isFlipped = widget.initiallyFlipped;

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _flipAnimation = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));

    if (_isFlipped) {
      _controller.value = 1.0;
    }
  }

  void flip() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          // Determine which side to show
          final isFrontVisible = _flipAnimation.value <= math.pi / 2;
          final rotationValue = _flipAnimation.value;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective
              ..rotateY(rotationValue),
            child: isFrontVisible
                ? widget.frontSide
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.backSide,
                  ),
          );
        },
      ),
    );
  }
}

/// 🎯 FUT Card with Flip (Complete Implementation)
///
/// Combines FUT card with flip functionality
class FlippableFutCard extends StatelessWidget {
  final Widget futCardFront;
  final Widget enlargedMetricsBack;
  final Duration flipDuration;

  const FlippableFutCard({
    super.key,
    required this.futCardFront,
    required this.enlargedMetricsBack,
    this.flipDuration = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) {
    return FlippableCard(
      frontSide: futCardFront,
      backSide: enlargedMetricsBack,
      duration: flipDuration,
    );
  }
}

/// 📊 Enlarged Metrics Back Side
///
/// Shows performance metrics in larger format when card is flipped
class EnlargedMetricsBack extends StatelessWidget {
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final String playerName;
  final Color backgroundColor;

  const EnlargedMetricsBack({
    super.key,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    required this.playerName,
    this.backgroundColor = const Color(0xFF1A1F2E),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B6F47), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player name at top
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              playerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const Divider(color: Color(0xFF8B6F47), thickness: 2),

          // Enlarged metrics
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _enlargedMetricRow('PACE', pace),
                  _enlargedMetricRow('SHOOTING', shooting),
                  _enlargedMetricRow('PASSING', passing),
                  _enlargedMetricRow('DRIBBLING', dribbling),
                  _enlargedMetricRow('DEFENDING', defending),
                  _enlargedMetricRow('PHYSICAL', physical),
                ],
              ),
            ),
          ),

          // Tap hint
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.white54, size: 16),
                SizedBox(width: 8),
                Text(
                  'Tap to flip back',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enlargedMetricRow(String label, int value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: _getColorForValue(value).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getColorForValue(value), width: 2),
            ),
            child: Text(
              value.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _getColorForValue(value),
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForValue(int value) {
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
}
