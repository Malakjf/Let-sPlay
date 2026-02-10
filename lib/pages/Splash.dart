import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letsplay/pages/MainLayout.dart';
import 'package:provider/provider.dart';

// NOTE: You may need to adjust the import paths below to match your project structure.
import 'package:letsplay/pages/Welcome.dart';
import '../services/language.dart';

/// Animation Sequence (STRICT):
/// 1. Football Entrance (~600ms)
/// 2. Net Impact (~300ms)
/// 3. Logo Reveal (~500ms)
///
/// Total duration: ~2 seconds
/// Runs once, then triggers onComplete
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animations
  late Animation<Offset> _ballSlide;
  late Animation<double> _netImpactScale;
  late Animation<double> _ballFade;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // Total duration ~2 seconds to accommodate sequence + pauses
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 1️⃣ Football Entrance (0 - 600ms)
    // Enters from bottom
    _ballSlide = Tween<Offset>(begin: const Offset(0.0, 2.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
          ),
        );

    // 2️⃣ Net Impact (600ms - 900ms)
    // Subtle scale up/down to simulate impact
    _netImpactScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.45, curve: Curves.easeInOut),
          ),
        );

    // Fade out ball/net before logo appears (900ms - 1100ms)
    _ballFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.55, curve: Curves.easeOut),
      ),
    );

    // 3️⃣ Logo Reveal (1000ms - 1600ms)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.8, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Start
    _controller.forward().then((_) {
      // Small delay before navigation
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onComplete?.call();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🥅 Net & Ball Layer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _ballFade.value,
                child: Transform.scale(
                  scale: _netImpactScale.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Net Background
                      CustomPaint(
                        painter: _SplashNetPainter(),
                        size: const Size(300, 200),
                      ),
                      // Ball
                      Transform.translate(
                        offset: Offset(
                          0,
                          _ballSlide.value.dy *
                              (MediaQuery.of(context).size.height / 3),
                        ),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('⚽', style: TextStyle(fontSize: 60)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 💎 Logo Layer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _logoFade.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Center(
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 🚀 Splash Page with Authentication Logic
// ═══════════════════════════════════════════════════════════════
// This page always shows the splash animation on app launch, then
// navigates to the correct screen based on the user's login status.

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FootballSplashAnimation(
      appName: 'LetsPlay',
      onComplete: () {
        // 1. Get dependencies (LocaleController)
        final localeCtrl = Provider.of<LocaleController>(
          context,
          listen: false,
        );

        // 2. Check Auth State (Firebase)
        final user = FirebaseAuth.instance.currentUser;

        // 3. Navigate based on Auth State
        if (user != null) {
          // User is logged in -> Go to Home (MainLayout)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainLayout(ctrl: localeCtrl)),
          );
        } else {
          // User is NOT logged in -> Go to Login (WelcomePage)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => WelcomePage(ctrl: localeCtrl)),
          );
        }
      },
    );
  }
}

/// 🥅 Net visual painter for splash screen
class _SplashNetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
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
  final VoidCallback onComplete;
  final String appName;

  const FootballSplashAnimation({
    super.key,
    required this.onComplete,
    this.appName = 'LetsPlay',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      onComplete: onComplete,
      appName: appName,
      logo: Image.asset(
        'assets/images/logo.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
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
              child: Icon(
                Icons.sports_soccer,
                size: 60,
                color: Color(0xFF64B5F6),
              ),
            ),
          );
        },
      ),
    );
  }
}
