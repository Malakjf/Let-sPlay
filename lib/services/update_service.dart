import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateService {
  static bool _hasChecked = false;

  /// Main entry point to check for updates. Typically called once in Home initState.
  static Future<void> checkForUpdate(BuildContext context) async {
    if (_hasChecked) return;
    _hasChecked = true;

    try {
      // 1. Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch config from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;
      final latestVersion = data['latestVersion']?.toString() ?? '';
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      final updateMessage =
          data['updateMessage']?.toString() ??
          'A new version is available with exciting new features!';
      final androidUrl = data['androidUrl']?.toString() ?? '';
      final iosUrl = data['iosUrl']?.toString() ?? '';

      // 3. Compare versions
      if (_shouldUpdate(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(
            context,
            forceUpdate: forceUpdate,
            message: updateMessage,
            androidUrl: androidUrl,
            iosUrl: iosUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ UpdateService Error: $e');
      // Fail silently in production to avoid crashing user experience
    }
  }

  /// Compares semantic versions (e.g., "1.0.0" vs "1.1.0")
  static bool _shouldUpdate(String current, String latest) {
    if (latest.isEmpty) return false;

    try {
      final currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final latestParts = latest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      for (var i = 0; i < 3; i++) {
        final currPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currPart) return true;
        if (latestPart < currPart) return false;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required bool forceUpdate,
    required String message,
    required String androidUrl,
    required String iosUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Update Available 🚀',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: GoogleFonts.spaceGrotesk()),
                if (forceUpdate)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                      'This update is required to continue using the app.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Later',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _launchStore(androidUrl, iosUrl),
                child: const Text('Update Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _launchStore(String androidUrl, String iosUrl) async {
    final urlString = Platform.isAndroid ? androidUrl : iosUrl;
    if (urlString.isEmpty) return;

    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ Could not launch store URL: $e');
    }
  }
}
