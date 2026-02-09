import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedOutlineButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final IconData icon;

  const AnimatedOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.width,
    required this.icon,
  });

  @override
  State<AnimatedOutlineButton> createState() => _AnimatedOutlineButtonState();
}

class _AnimatedOutlineButtonState extends State<AnimatedOutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: widget.width,
        height: 55,
        child: OutlinedButton.icon(
          onPressed: () {
            _controller.forward().then((_) => _controller.reverse());
            widget.onPressed();
          },
          icon: Icon(widget.icon, color: Colors.white),
          label: Text(
            widget.text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}