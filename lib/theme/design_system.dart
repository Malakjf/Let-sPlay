import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DesignSystem {
  // Colors
  static const Color primaryCyan = Color(0xFF2CBFF5);
  static const Color primaryCyanLight = Color(0xFF5ED4FF);
  static const Color primaryCyanDark = Color(0xFF0099CC);
  static const Color bgDark = Color(0xFF0A0E17);
  static const Color bgDarkSecondary = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1A2332);
  static const Color bgCardElevated = Color(0xFF1F2937);
  static const Color bgSurface = Color(0xFF243447);
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textOnPrimary = Color(0xFFF9FAFB);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;

  // Card styling
  static const Gradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2332), Color(0xFF0F1823)],
  );

  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2CBFF5), Color(0xFF0099CC)],
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x26000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> glowShadow(Color color) {
    return [
      BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, spreadRadius: 2),
    ];
  }
}

class AppTypography {
  static TextStyle headlineLarge = GoogleFonts.saira(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: DesignSystem.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static TextStyle headlineMedium = GoogleFonts.saira(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: DesignSystem.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle headlineSmall = GoogleFonts.saira(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: DesignSystem.textPrimary,
    height: 1.25,
  );

  static TextStyle bodyMedium = GoogleFonts.saira(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: DesignSystem.textPrimary,
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.saira(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: DesignSystem.textSecondary,
    height: 1.4,
  );

  static TextStyle labelLarge = GoogleFonts.saira(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: DesignSystem.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = GoogleFonts.saira(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: DesignSystem.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle statNumber = GoogleFonts.saira(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: DesignSystem.textPrimary,
    height: 1.0,
  );

  static TextStyle statLabel = GoogleFonts.saira(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: DesignSystem.textSecondary,
    letterSpacing: 1.0,
  );

  static TextStyle button = GoogleFonts.saira(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: DesignSystem.textPrimary,
    letterSpacing: 0.5,
  );

  static TextStyle bodyLarge = GoogleFonts.saira(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: DesignSystem.textPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.saira(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: DesignSystem.textSecondary,
  );
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressScale = 0.95,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _controller.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
