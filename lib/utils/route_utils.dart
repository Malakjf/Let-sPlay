import 'package:flutter/material.dart';

/// Utility class for safe route argument extraction
class RouteUtils {
  /// Safely extracts route arguments with type checking
  static T? getRouteArg<T>(BuildContext context, String key) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final value = args[key];
      if (value is T) {
        return value;
      }
    }
    return null;
  }

  /// Safely extracts route arguments with fallback value
  static T getRouteArgWithFallback<T>(
    BuildContext context,
    String key,
    T fallback,
  ) {
    return getRouteArg<T>(context, key) ?? fallback;
  }

  /// Safely extracts nested route arguments (e.g., args['match']['title'])
  static T? getNestedRouteArg<T>(
    BuildContext context,
    String parentKey,
    String childKey,
  ) {
    final parent = getRouteArg<Map<String, dynamic>>(context, parentKey);
    if (parent != null) {
      final value = parent[childKey];
      if (value is T) {
        return value;
      }
    }
    return null;
  }

  /// Safely extracts nested route arguments with fallback
  static T getNestedRouteArgWithFallback<T>(
    BuildContext context,
    String parentKey,
    String childKey,
    T fallback,
  ) {
    return getNestedRouteArg<T>(context, parentKey, childKey) ?? fallback;
  }

  /// Validates that required route arguments are present
  static bool hasRequiredArgs(BuildContext context, List<String> requiredKeys) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return false;

    for (final key in requiredKeys) {
      if (!args.containsKey(key) || args[key] == null) {
        return false;
      }
    }
    return true;
  }

  /// Gets all route arguments as a Map with null safety
  static Map<String, dynamic> getAllRouteArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    return args is Map<String, dynamic> ? Map<String, dynamic>.from(args) : {};
  }
}
