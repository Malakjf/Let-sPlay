import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper to safely parse dates from Firestore which might be String, Timestamp, or DateTime
DateTime parseFirestoreDate(dynamic value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    if (value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(value);
    } catch (e) {
      // Fallback for DD/MM/YYYY format
      if (value.contains('/')) {
        try {
          final parts = value.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }
    }
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}
