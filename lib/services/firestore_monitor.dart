import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMonitor extends StatefulWidget {
  final Widget child;

  const FirestoreMonitor({super.key, required this.child});

  @override
  State<FirestoreMonitor> createState() => _FirestoreMonitorState();
}

class _FirestoreMonitorState extends State<FirestoreMonitor> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _monitorConnection();
  }

  void _monitorConnection() {
    FirebaseFirestore.instance.snapshotsInSync().listen(
      (_) {
        if (!_isOnline) {
          setState(() => _isOnline = true);
          debugPrint('✅ Firestore back online');
        }
      },
      onError: (error) {
        if (_isOnline) {
          setState(() => _isOnline = false);
          debugPrint('❌ Firestore offline: $error');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: const Text(
                '⚠️ Firestore Offline',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
