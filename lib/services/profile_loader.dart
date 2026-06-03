import 'package:flutter/widgets.dart';

import '../main.dart' show loadProfileSafe;

// Re-export permissionFromRole for convenience.
export 'package:letsplay/utils/permissions.dart' show permissionFromRole;

// Re-export loadProfileSafe so other files can import from a stable location.
Future<Map<String, dynamic>> loadProfileSafeWrapped(
  BuildContext context,
  String userId,
) {
  return loadProfileSafe(context, userId);
}
