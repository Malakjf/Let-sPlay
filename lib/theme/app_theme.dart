import 'package:flutter/material.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'app_theme.tailor.dart';

@TailorMixin()
class AppTheme extends ThemeExtension<AppTheme> with _$AppThemeTailorMixin {
  @override
  final Color primaryColor;
  @override
  final Color secondaryColor;
  @override
  final Color backgroundColor;
  @override
  final Color surfaceColor;
  @override
  final Color errorColor;
  @override
  final Color textPrimaryColor;
  @override
  final Color textSecondaryColor;
  @override
  final Color buttonBackgroundColor;
  @override
  final Color buttonTextColor;
  @override
  final double borderRadius;
  @override
  final double spacing;

  const AppTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.errorColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.buttonBackgroundColor,
    required this.buttonTextColor,
    required this.borderRadius,
    required this.spacing,
  });

  /// Dark theme only
  static const AppTheme dark = AppTheme(
    primaryColor: Color(0xFF2CBFF5),
    secondaryColor: Color(0xFF1E88E5),
    backgroundColor: Color(0xFF111827),
    surfaceColor: Color(0xFF1F2937),
    errorColor: Color(0xFFEF5350),
    textPrimaryColor: Color(0xFFF9FAFB),
    textSecondaryColor: Color(0xFF9CA3AF),
    buttonBackgroundColor: Colors.white,
    buttonTextColor: Colors.black,
    borderRadius: 12,
    spacing: 16,
  );

  static const AppTheme light = AppTheme(
    primaryColor: Color(0xFF2CBFF5),
    secondaryColor: Color(0xFF1E88E5),
    backgroundColor: Color(0xFFF2F4F7),
    surfaceColor: Colors.white,
    errorColor: Color(0xFFD32F2F),
    textPrimaryColor: Color(0xFF101828),
    textSecondaryColor: Color(0xFF667085),
    buttonBackgroundColor: Color(0xFF2CBFF5),
    buttonTextColor: Colors.white,
    borderRadius: 12,
    spacing: 16,
  );
}
