import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../widgets/UpdatePopup.dart';

/// 🚀 Service to handle global app version checks and update notifications
class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  /// Fetches the latest version info from Firestore and compares with installed version
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_updates')
          .doc('latest')
          .get();

      if (!doc.exists) return;

      final raw = doc.data();
      final data = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(raw);
      final latestVersion = data['latestVersion'] as String? ?? '1.0.0';
      final isMandatory = data['isMandatory'] as bool? ?? false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        final prefs = await SharedPreferences.getInstance();
        final lastSeenVersion = prefs.getString('last_seen_update_version');

        // Show if mandatory OR if the user hasn't seen this specific version yet
        if (isMandatory || lastSeenVersion != latestVersion) {
          if (context.mounted) {
            // Ensure data is a Map<String, dynamic> to avoid runtime type errors
            final dataMap = Map<String, dynamic>.from(data);
            showDialog(
              context: context,
              builder: (context) => UpdatePopup(data: dataMap),
            );
            if (!isMandatory) {
              await prefs.setString('last_seen_update_version', latestVersion);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Update check error: $e');
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
