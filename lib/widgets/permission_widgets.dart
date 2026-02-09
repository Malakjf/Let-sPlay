import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// Widget to request permissions with nice UI
class PermissionRequestWidget extends StatefulWidget {
  final Widget child;
  final bool requestOnInit;

  const PermissionRequestWidget({
    super.key,
    required this.child,
    this.requestOnInit = false,
  });

  @override
  State<PermissionRequestWidget> createState() =>
      _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState extends State<PermissionRequestWidget> {
  final _permissionService = PermissionService.instance;
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.requestOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPermissions();
      });
    }
  }

  Future<void> _checkPermissions() async {
    if (_permissionsChecked) return;

    final results = await _permissionService.requestAllPermissions();
    setState(() {
      _permissionsChecked = true;
    });

    debugPrint('🔐 Permissions checked: $results');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Floating action button for requesting specific permissions
class PermissionFab extends StatelessWidget {
  final String type; // 'camera', 'location', or 'all'
  final IconData? icon;
  final VoidCallback? onPermissionGranted;

  const PermissionFab({
    super.key,
    required this.type,
    this.icon,
    this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'permission_$type',
      onPressed: () => _requestPermission(context),
      child: Icon(_getIcon()),
    );
  }

  IconData _getIcon() {
    if (icon != null) return icon!;

    switch (type) {
      case 'camera':
        return Icons.camera_alt;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.security;
    }
  }

  Future<void> _requestPermission(BuildContext context) async {
    final permissionService = PermissionService.instance;
    bool granted = false;

    switch (type) {
      case 'camera':
        granted = await permissionService.requestCameraWithDialog(context);
        break;
      case 'location':
        granted = await permissionService.requestLocationWithDialog(context);
        break;
      case 'all':
        final results = await permissionService.requestAllPermissions();
        granted = results.values.any((element) => element);
        break;
    }

    if (granted && onPermissionGranted != null) {
      onPermissionGranted!();
    } else if (!granted) {
      _showPermissionDeniedSnackbar(context);
    }
  }

  void _showPermissionDeniedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type permission denied'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => PermissionService.instance.openAppSettings(),
        ),
      ),
    );
  }
}

/// Permission status indicator widget
class PermissionStatusIndicator extends StatefulWidget {
  final String permission; // 'camera', 'location', 'storage'

  const PermissionStatusIndicator({super.key, required this.permission});

  @override
  State<PermissionStatusIndicator> createState() =>
      _PermissionStatusIndicatorState();
}

class _PermissionStatusIndicatorState extends State<PermissionStatusIndicator> {
  bool? _isGranted;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    final permissionService = PermissionService.instance;
    bool granted = false;

    switch (widget.permission) {
      case 'camera':
        granted = await permissionService.isCameraPermissionGranted();
        break;
      case 'location':
        granted = await permissionService.isLocationPermissionGranted();
        break;
      case 'storage':
        granted = await permissionService.isStoragePermissionGranted();
        break;
    }

    if (mounted) {
      setState(() {
        _isGranted = granted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGranted == null) {
      return const CircularProgressIndicator(strokeWidth: 2);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _isGranted! ? Icons.check_circle : Icons.error,
          color: _isGranted! ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _isGranted! ? 'Granted' : 'Denied',
          style: TextStyle(
            color: _isGranted! ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Settings page section for permissions
class PermissionsSection extends StatelessWidget {
  const PermissionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _PermissionTile(
              title: 'Camera',
              subtitle: 'Take photos for profile and matches',
              permission: 'camera',
              icon: Icons.camera_alt,
            ),
            _PermissionTile(
              title: 'Location',
              subtitle: 'Find nearby fields and show directions',
              permission: 'location',
              icon: Icons.location_on,
            ),
            _PermissionTile(
              title: 'Storage',
              subtitle: 'Save and access photos',
              permission: 'storage',
              icon: Icons.folder,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String permission;
  final IconData icon;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.permission,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PermissionStatusIndicator(permission: permission),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _requestPermission(context),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    final permissionService = PermissionService.instance;
    bool granted = false;

    switch (permission) {
      case 'camera':
        granted = await permissionService.requestCameraWithDialog(context);
        break;
      case 'location':
        granted = await permissionService.requestLocationWithDialog(context);
        break;
      case 'storage':
        granted = await permissionService.requestStoragePermission();
        break;
    }

    if (granted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$title permission granted!')));
    } else {
      await permissionService.handlePermissionDenied(
        context,
        permissionName: title,
        reason: 'This permission is needed for $subtitle',
      );
    }
  }
}
