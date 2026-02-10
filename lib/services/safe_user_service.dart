import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

/// Safe user service that handles all null safety issues
class SafeUserService {
  final FirebaseService _firebaseService = FirebaseService.instance;

  /// Get current user safely
  User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Get current user ID safely
  String? get currentUserId {
    try {
      return currentUser?.uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// Get current user role safely with fallback
  Future<String> getCurrentUserRole() async {
    try {
      final role = await _firebaseService.getCurrentUserRole();
      return role; // Default fallback
    } catch (e) {
      print('Error getting current user role: $e');
      return 'Player';
    }
  }

  /// Get current user data safely with defaults
  Future<Map<String, dynamic>> getCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return _defaultUser();

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!doc.exists) return _defaultUser();

      return {..._defaultUser(), ...doc.data()!};
    } catch (e) {
      debugPrint('❌ getCurrentUserData error: $e');
      return _defaultUser(); // 🔥 يمنع الكراش
    }
  }

  Map<String, dynamic> _defaultUser() {
    return {
      'role': 'Player',
      'username': 'Guest',
      'metrics': {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0},
    };
  }

  /// Get user data by ID safely with defaults
  Future<Map<String, dynamic>> getUserDataById(String userId) async {
    try {
      if (userId.isEmpty) {
        return _getDefaultUserData();
      }

      final userData = await _firebaseService.getUserData(userId);

      // Ensure all required fields exist
      return {
        'uid': userData['uid'] ?? userId,
        'email': userData['email'] ?? '',
        'username': userData['username'] ?? 'Unknown User',
        'phone': userData['phone'] ?? '',
        'emergencyPhone': userData['emergencyPhone'] ?? '',
        'dateOfBirth': userData['dateOfBirth'] ?? '',
        'gender': userData['gender'] ?? 'Not specified',
        'role': userData['role'] ?? 'Player',
        'metrics':
            userData['metrics'] ??
            {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0},
        'avatarUrl': userData['avatarUrl'] ?? '',
        'createdAt': userData['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': userData['updatedAt'] ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting user data by ID: $e');
      return _getDefaultUserData();
    }
  }

  /// Safe username getter
  String? getCurrentUsername() {
    try {
      return currentUser?.displayName ??
          currentUser?.email?.split('@').first ??
          'Unknown User';
    } catch (e) {
      print('Error getting current username: $e');
      return 'Unknown User';
    }
  }

  /// Safe email getter
  String? getCurrentEmail() {
    try {
      return currentUser?.email ?? '';
    } catch (e) {
      print('Error getting current email: $e');
      return '';
    }
  }

  /// Safe avatar URL getter
  String? getCurrentAvatarUrl() {
    try {
      return currentUser?.photoURL ?? '';
    } catch (e) {
      print('Error getting current avatar URL: $e');
      return '';
    }
  }

  /// Check if user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final role = await getCurrentUserRole();
      return role.toLowerCase() == 'admin';
    } catch (e) {
      print('Error checking if user is admin: $e');
      return false;
    }
  }

  /// Check if user is organizer
  Future<bool> isCurrentUserOrganizer() async {
    try {
      final role = await getCurrentUserRole();
      final roleLower = role.toLowerCase();
      return roleLower == 'organizer' || roleLower == 'admin';
    } catch (e) {
      print('Error checking if user is organizer: $e');
      return false;
    }
  }

  /// Check if user is coach
  Future<bool> isCurrentUserCoach() async {
    try {
      final role = await getCurrentUserRole();
      final roleLower = role.toLowerCase();
      return roleLower == 'coach' || roleLower == 'admin';
    } catch (e) {
      print('Error checking if user is coach: $e');
      return false;
    }
  }

  /// Get user metrics safely
  Map<String, int> getUserMetrics(Map<String, dynamic> userData) {
    try {
      final metrics = userData['metrics'] as Map<String, dynamic>?;

      if (metrics == null) {
        return {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0};
      }

      return {
        'PAC': (metrics['PAC'] as num?)?.toInt() ?? 0,
        'SHO': (metrics['SHO'] as num?)?.toInt() ?? 0,
        'PAS': (metrics['PAS'] as num?)?.toInt() ?? 0,
        'DRI': (metrics['DRI'] as num?)?.toInt() ?? 0,
        'DEF': (metrics['DEF'] as num?)?.toInt() ?? 0,
        'PHY': (metrics['PHY'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('Error getting user metrics: $e');
      return {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0};
    }
  }

  /// Update user data safely
  Future<bool> updateUserData(Map<String, dynamic> updates) async {
    try {
      final userId = currentUserId;
      if (userId == null || userId.isEmpty) {
        print('Cannot update user data: no current user');
        return false;
      }

      // Add updated timestamp
      updates['updatedAt'] = DateTime.now().toIso8601String();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  /// Check if user is signed in
  bool isSignedIn() {
    try {
      return currentUser != null;
    } catch (e) {
      print('Error checking if user is signed in: $e');
      return false;
    }
  }

  /// Sign out safely
  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  /// Default user data structure
  Map<String, dynamic> _getDefaultUserData() {
    return {
      'uid': currentUserId ?? '',
      'email': getCurrentEmail(),
      'username': getCurrentUsername(),
      'phone': '',
      'emergencyPhone': '',
      'dateOfBirth': '',
      'gender': 'Not specified',
      'role': 'Player',
      'metrics': {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0},
      'avatarUrl': '',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// Stream builder wrapper for safe data handling
class SafeStreamBuilder<T> extends StatelessWidget {
  final Stream<T>? stream;
  final Widget Function(BuildContext context, T? data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const SafeStreamBuilder({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Stream error: ${snapshot.error}');
          return errorWidget ?? Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return emptyWidget ?? const Center(child: Text('No data available'));
        }

        return builder(context, snapshot.data);
      },
    );
  }
}

/// Future builder wrapper for safe data handling
class SafeFutureBuilder<T> extends StatelessWidget {
  final Future<T>? future;
  final Widget Function(BuildContext context, T? data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const SafeFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Future error: ${snapshot.error}');
          return errorWidget ?? Center(child: Text('Error: ${snapshot.error}'));
        }

        return builder(context, snapshot.data);
      },
    );
  }
}
