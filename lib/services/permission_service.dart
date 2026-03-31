import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Service to handle all app permissions (camera, location, storage)
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static PermissionService get instance => _instance;

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.location.request();
      if (status.isGranted) return true;

      // If denied, try requesting precise location
      final preciseStatus = await Permission.locationWhenInUse.request();
      return preciseStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Request storage permission (for photo saving)
  Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      // For Android 13+, try photos permission
      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting storage permission: $e');
      return false;
    }
  }

  /// Request all necessary permissions at once
  Future<Map<String, bool>> requestAllPermissions() async {
    if (kIsWeb) {
      return {'camera': true, 'location': true, 'storage': true};
    }
    final results = <String, bool>{};

    try {
      final permissions = [
        Permission.camera,
        Permission.location,
        Permission.locationWhenInUse,
        Permission.storage,
        Permission.photos,
      ];

      final statuses = await permissions.request();

      results['camera'] = statuses[Permission.camera]?.isGranted ?? false;
      results['location'] =
          statuses[Permission.location]?.isGranted ??
          statuses[Permission.locationWhenInUse]?.isGranted ??
          false;
      results['storage'] =
          statuses[Permission.storage]?.isGranted ??
          statuses[Permission.photos]?.isGranted ??
          false;

      debugPrint('✅ Permission results: $results');
      return results;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return {'camera': false, 'location': false, 'storage': false};
    }
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking camera permission: $e');
      return false;
    }
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.location.status;
      if (status.isGranted) return true;

      final whenInUseStatus = await Permission.locationWhenInUse.status;
      return whenInUseStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      return false;
    }
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.storage.status;
      if (status.isGranted) return true;

      final photosStatus = await Permission.photos.status;
      return photosStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking storage permission: $e');
      return false;
    }
  }

  /// Show permission dialog with explanation
  Future<bool> showPermissionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onRequest,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              onRequest();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Request camera with user-friendly dialog
  Future<bool> requestCameraWithDialog(BuildContext context) async {
    // Check if already granted
    if (await isCameraPermissionGranted()) return true;

    // Show explanation dialog
    final shouldRequest = await showPermissionDialog(
      context,
      title: 'Camera Access Required',
      message:
          'This app needs camera access to take photos for your profile and match documentation.',
      onRequest: () {},
    );

    if (!shouldRequest) return false;

    // Request permission
    return await requestCameraPermission();
  }

  /// Request location with user-friendly dialog
  Future<bool> requestLocationWithDialog(BuildContext context) async {
    // Check if already granted
    if (await isLocationPermissionGranted()) return true;

    // Show explanation dialog
    final shouldRequest = await showPermissionDialog(
      context,
      title: 'Location Access Required',
      message:
          'This app needs location access to find nearby football fields and show match locations.',
      onRequest: () {},
    );

    if (!shouldRequest) return false;

    // Request permission
    return await requestLocationPermission();
  }

  /// Open app settings if permission permanently denied
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      debugPrint('📱 Opened app settings');
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
    }
  }

  /// Handle permission denial with options
  Future<void> handlePermissionDenied(
    BuildContext context, {
    required String permissionName,
    required String reason,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Denied'),
        content: Text(
          '$reason\n\nYou can grant this permission in Settings > Apps > LetsPlay > Permissions',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}

/// Extension methods for easy permission checking
extension PermissionServiceExtension on BuildContext {
  PermissionService get permissions => PermissionService.instance;
}
