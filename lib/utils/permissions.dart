import 'package:flutter/foundation.dart';
import '../models/user_permission.dart';

/// Safely converts a role or permission level string from Firestore
/// into a non-nullable [UserPermission] enum.
///
/// This function is the single source of truth for permission mapping.
/// It handles `null`, empty, and unknown strings by defaulting to [UserPermission.player].
UserPermission permissionFromRole(String? roleOrPermissionLevel) {
  debugPrint('🔐 Converting to permission: "$roleOrPermissionLevel"');

  if (roleOrPermissionLevel == null || roleOrPermissionLevel.isEmpty) {
    debugPrint('✅ Null/empty role -> Player permission');
    return UserPermission.player;
  }

  final normalized = roleOrPermissionLevel.toLowerCase().trim();
  debugPrint('🔐 Normalized permission string: "$normalized"');

  switch (normalized) {
    case 'admin':
      return UserPermission.admin;
    case 'organizer':
      return UserPermission.organizer;
    case 'coach':
      return UserPermission.coach;
    case 'academy_player':
    case 'academy player':
    case 'academy':
      return UserPermission.academy;
    case 'player':
    default:
      return UserPermission.player;
  }
}
