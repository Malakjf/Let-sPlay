// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_theme.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$AppThemeTailorMixin on ThemeExtension<AppTheme> {
  Color get primaryColor;
  Color get secondaryColor;
  Color get backgroundColor;
  Color get surfaceColor;
  Color get errorColor;
  Color get textPrimaryColor;
  Color get textSecondaryColor;
  Color get buttonBackgroundColor;
  Color get buttonTextColor;
  double get borderRadius;
  double get spacing;

  @override
  AppTheme copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? errorColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    Color? buttonBackgroundColor,
    Color? buttonTextColor,
    double? borderRadius,
    double? spacing,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      errorColor: errorColor ?? this.errorColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      buttonBackgroundColor:
          buttonBackgroundColor ?? this.buttonBackgroundColor,
      buttonTextColor: buttonTextColor ?? this.buttonTextColor,
      borderRadius: borderRadius ?? this.borderRadius,
      spacing: spacing ?? this.spacing,
    );
  }

  @override
  AppTheme lerp(covariant ThemeExtension<AppTheme>? other, double t) {
    if (other is! AppTheme) return this as AppTheme;
    return AppTheme(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      textPrimaryColor: Color.lerp(
        textPrimaryColor,
        other.textPrimaryColor,
        t,
      )!,
      textSecondaryColor: Color.lerp(
        textSecondaryColor,
        other.textSecondaryColor,
        t,
      )!,
      buttonBackgroundColor: Color.lerp(
        buttonBackgroundColor,
        other.buttonBackgroundColor,
        t,
      )!,
      buttonTextColor: Color.lerp(buttonTextColor, other.buttonTextColor, t)!,
      borderRadius: t < 0.5 ? borderRadius : other.borderRadius,
      spacing: t < 0.5 ? spacing : other.spacing,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AppTheme &&
            const DeepCollectionEquality().equals(
              primaryColor,
              other.primaryColor,
            ) &&
            const DeepCollectionEquality().equals(
              secondaryColor,
              other.secondaryColor,
            ) &&
            const DeepCollectionEquality().equals(
              backgroundColor,
              other.backgroundColor,
            ) &&
            const DeepCollectionEquality().equals(
              surfaceColor,
              other.surfaceColor,
            ) &&
            const DeepCollectionEquality().equals(
              errorColor,
              other.errorColor,
            ) &&
            const DeepCollectionEquality().equals(
              textPrimaryColor,
              other.textPrimaryColor,
            ) &&
            const DeepCollectionEquality().equals(
              textSecondaryColor,
              other.textSecondaryColor,
            ) &&
            const DeepCollectionEquality().equals(
              buttonBackgroundColor,
              other.buttonBackgroundColor,
            ) &&
            const DeepCollectionEquality().equals(
              buttonTextColor,
              other.buttonTextColor,
            ) &&
            const DeepCollectionEquality().equals(
              borderRadius,
              other.borderRadius,
            ) &&
            const DeepCollectionEquality().equals(spacing, other.spacing));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(primaryColor),
      const DeepCollectionEquality().hash(secondaryColor),
      const DeepCollectionEquality().hash(backgroundColor),
      const DeepCollectionEquality().hash(surfaceColor),
      const DeepCollectionEquality().hash(errorColor),
      const DeepCollectionEquality().hash(textPrimaryColor),
      const DeepCollectionEquality().hash(textSecondaryColor),
      const DeepCollectionEquality().hash(buttonBackgroundColor),
      const DeepCollectionEquality().hash(buttonTextColor),
      const DeepCollectionEquality().hash(borderRadius),
      const DeepCollectionEquality().hash(spacing),
    );
  }
}

extension AppThemeBuildContextProps on BuildContext {
  AppTheme get appTheme => Theme.of(this).extension<AppTheme>()!;
  Color get primaryColor => appTheme.primaryColor;
  Color get secondaryColor => appTheme.secondaryColor;
  Color get backgroundColor => appTheme.backgroundColor;
  Color get surfaceColor => appTheme.surfaceColor;
  Color get errorColor => appTheme.errorColor;
  Color get textPrimaryColor => appTheme.textPrimaryColor;
  Color get textSecondaryColor => appTheme.textSecondaryColor;
  Color get buttonBackgroundColor => appTheme.buttonBackgroundColor;
  Color get buttonTextColor => appTheme.buttonTextColor;
  double get borderRadius => appTheme.borderRadius;
  double get spacing => appTheme.spacing;
}
