// ignore: unused_import
import 'package:flutter/material.dart';

class ValidationHelper {
  /// Validates a birthdate for any age.
  /// Allows newborns (0+ years) and blocks only future dates or empty values.
  static String? validateBirthDate(DateTime? date) {
    if (date == null) {
      return 'Please select your birthdate';
    }

    final DateTime now = DateTime.now();

    // Basic validity check: cannot be born in the future
    if (date.isAfter(now)) {
      return 'Birthdate cannot be in the future';
    }

    // All age restrictions (under 13, minimum age, etc.) have been removed.
    // Any valid past date is accepted to support users of all ages.
    return null;
  }
}
