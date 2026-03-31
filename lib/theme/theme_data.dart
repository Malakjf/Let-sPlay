import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

ThemeData createThemeData(AppTheme theme, {required bool isDark}) {
  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: theme.backgroundColor,

    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: theme.primaryColor,
      onPrimary: theme.buttonTextColor,
      secondary: theme.secondaryColor,
      onSecondary: Colors.white,
      error: theme.errorColor,
      onError: Colors.white,
      surface: theme.surfaceColor,
      onSurface: theme.textPrimaryColor,
      onSurfaceVariant: theme.textSecondaryColor,
      outline: theme.textSecondaryColor.withOpacity(0.5),
      surfaceTint: Colors.transparent,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: theme.surfaceColor,
      foregroundColor: theme.textPrimaryColor,
      elevation: 0,
      centerTitle: true,
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: theme.surfaceColor,
      headerBackgroundColor: theme.primaryColor,
      headerForegroundColor: theme.buttonTextColor,
      surfaceTintColor: Colors.transparent,
      dayForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return theme.buttonTextColor;
        }
        if (states.contains(MaterialState.disabled)) {
          return theme.textSecondaryColor.withOpacity(0.3);
        }
        return theme.textPrimaryColor;
      }),
      todayForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return theme.buttonTextColor;
        }
        return theme.primaryColor;
      }),
      yearForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return theme.buttonTextColor;
        }
        return theme.textPrimaryColor;
      }),
      weekdayStyle: TextStyle(color: theme.textSecondaryColor),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.buttonBackgroundColor,
        foregroundColor: theme.buttonTextColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
        ),
        elevation: 4,
        shadowColor: theme.primaryColor.withOpacity(0.4),
      ),
    ),

    textTheme:
        GoogleFonts.sairaTextTheme(
          ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
          ).textTheme,
        ).copyWith(
          displayLarge: TextStyle(color: theme.textPrimaryColor),
          displayMedium: TextStyle(color: theme.textPrimaryColor),
          displaySmall: TextStyle(color: theme.textPrimaryColor),
          headlineLarge: TextStyle(color: theme.textPrimaryColor),
          headlineMedium: TextStyle(color: theme.textPrimaryColor),
          headlineSmall: TextStyle(color: theme.textPrimaryColor),
          titleLarge: TextStyle(color: theme.textPrimaryColor),
          titleMedium: TextStyle(color: theme.textPrimaryColor),
          titleSmall: TextStyle(color: theme.textPrimaryColor),
          bodyLarge: TextStyle(color: theme.textPrimaryColor),
          bodyMedium: TextStyle(color: theme.textPrimaryColor),
          bodySmall: TextStyle(color: theme.textSecondaryColor),
          labelLarge: TextStyle(color: theme.textPrimaryColor),
          labelMedium: TextStyle(color: theme.textPrimaryColor),
          labelSmall: TextStyle(color: theme.textSecondaryColor),
        ),

    // 🎨 Modern Input Styles
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: theme.surfaceColor.withOpacity(0.5),
      contentPadding: EdgeInsets.symmetric(
        horizontal: theme.spacing * 2,
        vertical: theme.spacing * 1.5,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        borderSide: BorderSide(color: theme.primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        borderSide: BorderSide(color: theme.errorColor),
      ),
      labelStyle: TextStyle(color: theme.textSecondaryColor),
      hintStyle: TextStyle(color: theme.textSecondaryColor.withOpacity(0.5)),
    ),

    // 🃏 Unified Card Style
    cardTheme: CardThemeData(
      color: theme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      margin: EdgeInsets.all(theme.spacing),
    ),

    // 💬 Premium Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: theme.backgroundColor,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius * 1.5),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      titleTextStyle: GoogleFonts.saira(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: theme.textPrimaryColor,
      ),
    ),

    // 📱 Modern Bottom Sheets
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: theme.backgroundColor,
      modalBackgroundColor: theme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.borderRadius * 1.5),
        ),
      ),
    ),

    // 🔔 Floating SnackBars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: theme.surfaceColor,
      contentTextStyle: GoogleFonts.saira(color: theme.textPrimaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.borderRadius),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: EdgeInsets.all(theme.spacing * 2),
    ),

    dividerTheme: DividerThemeData(
      color: theme.textSecondaryColor.withOpacity(0.1),
      thickness: 1,
      space: theme.spacing * 2,
    ),

    extensions: [theme],
  );
}
