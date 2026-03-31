import 'package:flutter/material.dart';

/// 🎯 Tilt Card Animation - Touch/Drag interaction
/// Card tilts smoothly on drag, returns to center when released
class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt; // Max rotation in degrees

  const TiltCard({super.key, required this.child, this.maxTilt = 8.0});

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with TickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<double> _tiltAnimation;

  double _currentTilt = 0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _tiltAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _resetController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  /// 🎯 Handle drag updates - tilt based on drag position
  void _onDragUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final centerX = size.width / 2;

    // Calculate tilt based on drag distance from center
    final dragDistance = details.globalPosition.dx - centerX;
    final maxDistance = centerX * 0.5; // Max distance to consider
    final tiltPercent = (dragDistance / maxDistance).clamp(-1.0, 1.0);

    setState(() {
      _currentTilt = tiltPercent * widget.maxTilt;
    });
  }

  /// 🎯 Handle drag end - smoothly return to center
  void _onDragEnd(DragEndDetails details) {
    _tiltAnimation = Tween<double>(
      begin: _currentTilt,
      end: 0,
    ).animate(CurvedAnimation(parent: _resetController, curve: Curves.easeOut));

    _resetController.forward(from: 0);

    // Listen to animation and update state
    _tiltAnimation.addListener(() {
      setState(() {
        _currentTilt = _tiltAnimation.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onDragUpdate,
      onPanEnd: _onDragEnd,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // Perspective
          ..rotateY(_currentTilt * 0.017453292519943295), // Convert to radians
        child: widget.child,
      ),
    );
  }
}
