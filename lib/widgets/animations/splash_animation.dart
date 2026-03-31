import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🚀 Animated Splash Screen (PlayFootball.me Style)
///
/// FIFA-style splash animation:
/// 1. Football ⚽ enters net
/// 2. Ball fades out
/// 3. Logo appears
///
/// Total duration: ~1.2 seconds
/// Plays once on app launch
class AnimatedSplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final Widget logo;
  final String? appName;

  const AnimatedSplashScreen({
    super.key,
    this.onComplete,
    required this.logo,
    this.appName,
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballController;
  late AnimationController _logoController;

  late Animation<Offset> _ballPosition;
  late Animation<double> _ballFade;
  late Animation<double> _ballScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // Ball animation: 0-800ms
    _ballController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo animation: 400-1200ms (overlaps with ball fade)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Ball enters net (moves up and scales down)
    _ballPosition =
        Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: const Offset(0, -0.8),
        ).animate(
          CurvedAnimation(parent: _ballController, curve: Curves.easeInCubic),
        );

    _ballScale = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _ballController, curve: Curves.easeInCubic),
    );

    _ballFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ballController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Logo fades in and scales up
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Start ball animation
    await _ballController.forward();

    // Start logo animation (slightly before ball finishes)
    await Future.delayed(const Duration(milliseconds: 100));
    await _logoController.forward();

    // Complete callback
    await Future.delayed(const Duration(milliseconds: 300));
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _ballController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        children: [
          // Net background effect
          Positioned.fill(child: CustomPaint(painter: _SplashNetPainter())),

          // Ball animation
          Center(
            child: AnimatedBuilder(
              animation: _ballController,
              builder: (context, child) {
                return Opacity(
                  opacity: _ballFade.value,
                  child: Transform.translate(
                    offset: Offset(
                      _ballPosition.value.dx *
                          MediaQuery.of(context).size.width,
                      _ballPosition.value.dy *
                          MediaQuery.of(context).size.height,
                    ),
                    child: Transform.scale(
                      scale: _ballScale.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Text(
                          '⚽',
                          style: TextStyle(fontSize: 80),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logo animation
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        widget.logo,
                        if (widget.appName != null) ...[
                          const SizedBox(height: 24),
                          Text(
                            widget.appName!,
                            style: GoogleFonts.saira(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: const Color(
                                    0xFF64B5F6,
                                  ).withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 🥅 Net visual painter for splash screen
class _SplashNetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw subtle net grid in center
    for (var i = -8; i <= 8; i++) {
      // Vertical lines
      canvas.drawLine(
        Offset(centerX + i * gridSize, centerY - 200),
        Offset(centerX + i * gridSize, centerY + 200),
        paint,
      );
      // Horizontal lines
      if (i >= -5 && i <= 5) {
        canvas.drawLine(
          Offset(centerX - 320, centerY + i * gridSize),
          Offset(centerX + 320, centerY + i * gridSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 🎯 Simple Splash Wrapper
///
/// Quick implementation for existing Splash page
class FootballSplashAnimation extends StatelessWidget {
  final VoidCallback? onComplete;
  final Widget? nextScreen;
  final String appName;

  const FootballSplashAnimation({
    super.key,
    this.onComplete,
    this.nextScreen,
    this.appName = 'PlayFootball.me',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      onComplete: () {
        onComplete?.call();
        if (nextScreen != null) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => nextScreen!));
        }
      },
      appName: appName,
      logo: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF64B5F6).withOpacity(0.2),
          border: Border.all(color: const Color(0xFF64B5F6), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64B5F6).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.sports_soccer, size: 60, color: Color(0xFF64B5F6)),
        ),
      ),
    );
  }
}
