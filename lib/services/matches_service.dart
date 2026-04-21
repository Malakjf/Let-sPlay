import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'guest_service.dart';
import '../utils/firestore_helper.dart';

class MatchesService extends ChangeNotifier {
  MatchesService._internal();
  static final MatchesService _instance = MatchesService._internal();
  factory MatchesService() => _instance;

  final List<Map<String, dynamic>> _matches = [];
  final FirebaseService _firebaseService = FirebaseService.instance;

  List<Map<String, dynamic>> get matches => List.unmodifiable(_matches);

  Future<void> addMatch(Map<String, dynamic> match) async {
    try {
      final m = Map<String, dynamic>.from(match);
      m['playersCount'] = (m['playersCount'] ?? 0) as int;
      m['maxPlayers'] = (m['maxPlayers'] ?? 10) as int;
      m['name'] = m['name'] ?? m['title'] ?? m['matchName'] ?? 'Match';
      m['id'] = DateTime.now().millisecondsSinceEpoch.toString();

      // Save to Firestore
      await _firebaseService.saveMatch(m);

      // Update local list
      _matches.insert(0, m);
      notifyListeners();

      // Send notification for new match
      await NotificationService().sendNewMatchNotification(m);
    } catch (e) {
      print('Error adding match: $e');
      rethrow;
    }
  }

  void incrementPlayersByName(String name) {
    final idx = _matches.indexWhere((m) => (m['name'] ?? '') == name);
    if (idx == -1) return;
    final m = _matches[idx];
    final current = (m['playersCount'] ?? 0) as int;
    final max = (m['maxPlayers'] ?? 10) as int;
    if (current < max) {
      m['playersCount'] = current + 1;
      notifyListeners();
    }
  }

  void setMatches(List<Map<String, dynamic>> list) {
    _matches
      ..clear()
      ..addAll(list.map((e) => Map<String, dynamic>.from(e)));
    notifyListeners();
  }

  void clear() {
    _matches.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getAllMatches() {
    return List.unmodifiable(_matches);
  }

  List<Map<String, dynamic>> getUpcomingMatches() {
    final now = DateTime.now();
    return _matches.where((match) {
      if (match['date'] == null) return false;

      try {
        final matchDate = DateTime.parse(match['date']);
        return matchDate.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList()..sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date'] ?? '');
        final dateB = DateTime.parse(b['date'] ?? '');
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
  }

  List<Map<String, dynamic>> getPastMatches() {
    final now = DateTime.now();
    return _matches.where((match) {
      if (match['date'] == null) return false;

      try {
        final matchDate = DateTime.parse(match['date']);
        return matchDate.isBefore(now);
      } catch (e) {
        return false;
      }
    }).toList()..sort((a, b) {
      try {
        final dateA = DateTime.parse(a['date'] ?? '');
        final dateB = DateTime.parse(b['date'] ?? '');
        return dateB.compareTo(dateA); // Most recent first
      } catch (e) {
        return 0;
      }
    });
  }

  Future<void> updateMatch(Map<String, dynamic> updatedMatch) async {
    try {
      // Preserve the original ID if not present
      updatedMatch['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();

      // Find the existing match by ID or create a new one
      final existingIndex = _matches.indexWhere(
        (match) =>
            match['id'] == updatedMatch['id'] ||
            match['title'] == updatedMatch['title'] ||
            match['name'] == updatedMatch['name'],
      );

      // Save to Firestore
      await _firebaseService.saveMatch(updatedMatch);

      // Update local list
      if (existingIndex != -1) {
        _matches[existingIndex] = Map<String, dynamic>.from(updatedMatch);
      } else {
        _matches.insert(0, Map<String, dynamic>.from(updatedMatch));
      }
      notifyListeners();
    } catch (e) {
      print('Error updating match: $e');
      rethrow;
    }
  }

  Future<void> deleteMatch(dynamic identifier) async {
    try {
      String? matchId;

      if (identifier is Map<String, dynamic>) {
        matchId = identifier['id'];
      } else if (identifier is String) {
        matchId = identifier;
        // Try to find by title if not found by ID
        final match = _matches.firstWhere(
          (m) =>
              m['id'] == identifier ||
              m['title'] == identifier ||
              m['name'] == identifier,
          orElse: () => {},
        );
        matchId = match['id'];
      }

      if (matchId != null && matchId.isNotEmpty) {
        // Delete from Firestore
        await _firebaseService.deleteMatch(matchId);
      }

      // Remove from local list
      if (identifier is Map<String, dynamic>) {
        _matches.removeWhere(
          (m) => m == identifier || m['id'] == identifier['id'],
        );
      } else if (identifier is String) {
        _matches.removeWhere(
          (m) =>
              m['id'] == identifier ||
              m['title'] == identifier ||
              m['name'] == identifier,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error deleting match: $e');
      rethrow;
    }
  }

  // Additional helper methods
  Map<String, dynamic>? getMatchById(String id) {
    try {
      return _matches.firstWhere((match) => match['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// Unified logic to join a match or the waiting list.
  /// Handles validations, transactions, and UI feedback.
  Future<void> joinMatch({
    required BuildContext context,
    required Map<String, dynamic> match,
    required bool ar,
  }) async {
    // 1. Guest Check
    if (!GuestService.handleGuestInteraction(context, ar)) {
      return;
    }

    // 2. Auth Check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(
        context,
        ar ? 'يجب تسجيل الدخول أولاً' : 'Please login first',
        isError: true,
      );
      return;
    }

    // 3. Match ID Validation
    final matchId = (match['id'] ?? match['matchId'])?.toString();
    if (matchId == null || matchId.isEmpty) {
      _showSnackBar(
        context,
        ar ? 'معرف المباراة غير صالح' : 'Invalid Match ID',
        isError: true,
      );
      return;
    }

    try {
      // 4. Fetch Fresh Data (Ensure we aren't joining an ended/full match based on stale cache)
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      if (!matchDoc.exists) {
        _showSnackBar(
          context,
          ar ? 'المباراة لم تعد موجودة' : 'Match no longer exists',
          isError: true,
        );
        return;
      }
      final data = matchDoc.data()!;

      // 5. Match Ended Validation
      final matchDate = parseFirestoreDate(data['date']);
      int durationMin = 90;
      if (data['duration'] is num) {
        durationMin = (data['duration'] as num).toInt();
      } else if (data['duration'] is String) {
        durationMin = int.tryParse(data['duration']) ?? 90;
      }

      final matchEnd = matchDate.add(Duration(minutes: durationMin));
      final now = DateTime.now();

      if (now.isAfter(matchEnd)) {
        _showSnackBar(
          context,
          ar ? 'هذه المباراة انتهت بالفعل' : 'This match has already ended.',
          isError: true,
        );
        return;
      }

      // 6. Registration Open Validation
      final openRegistry = data['openRegistryDate'];
      final registrationStartTime = openRegistry != null
          ? parseFirestoreDate(openRegistry)
          : matchDate;

      if (now.isBefore(registrationStartTime)) {
        _showRegistrationClosedDialog(context, ar, registrationStartTime);
        return;
      }

      // 7. Execute Transaction (Players vs Waiting List)
      final maxPlayers = data['maxPlayers'] ?? 10;
      final currentCount = data['playersCount'] ?? 0;
      final isFull = currentCount >= maxPlayers;

      await FirebaseService.instance.joinMatchTransaction(
        matchId: matchId,
        userId: user.uid,
      );

      // 8. Notifications Logic
      if (maxPlayers > 0) {
        if (currentCount == maxPlayers - 1) {
          NotificationService().sendLastSpotNotification(matchId);
        } else if (currentCount >= maxPlayers) {
          NotificationService().sendMatchFullNotification(matchId);
        }
      }

      // 9. Success Feedback
      if (context.mounted) {
        _showSnackBar(
          context,
          ar
              ? (isFull
                    ? 'تمت الإضافة إلى قائمة الانتظار'
                    : 'تم الانضمام بنجاح')
              : (isFull ? 'Added to Waiting List' : 'Successfully joined'),
          isError: false,
        );

        // Refresh local cache
        loadMatchesFromFirestore();
      }
    } catch (e) {
      debugPrint('❌ Error in joinMatch: $e');
      String errorMsg = ar ? 'حدث خطأ أثناء الانضمام' : 'Error joining match';
      if (e.toString().contains('already requested')) {
        errorMsg = ar ? 'لقد انضممت بالفعل' : 'You have already joined';
      }
      _showSnackBar(context, errorMsg, isError: true);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showRegistrationClosedDialog(
    BuildContext context,
    bool ar,
    DateTime openTime,
  ) {
    final hour = openTime.hour.toString().padLeft(2, '0');
    final minute = openTime.minute.toString().padLeft(2, '0');
    final timeStr = '${openTime.day}/${openTime.month} • $hour:$minute';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(ar ? 'التسجيل مغلق' : 'Registration Closed'),
        content: Text(
          ar
              ? 'سيفتح باب التسجيل لهذه المباراة في: $timeStr'
              : 'Registration for this match will open at: $timeStr',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ar ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> getMatchesByField(String fieldName) {
    return _matches.where((match) => match['fieldName'] == fieldName).toList();
  }

  List<Map<String, dynamic>> searchMatches(String query) {
    if (query.trim().isEmpty) return List.unmodifiable(_matches);

    final searchTerm = query.trim();
    return _matches.where((match) {
      final title = (match['title'] ?? match['name'] ?? '').toString();
      final fieldName = (match['fieldName'] ?? '').toString();
      final location = (match['fieldLocation'] ?? '').toString();

      return title.startsWith(searchTerm) ||
          fieldName.startsWith(searchTerm) ||
          location.startsWith(searchTerm);
    }).toList();
  }

  // Firestore integration methods
  Future<void> loadMatchesFromFirestore() async {
    // Load public matches from Firestore. Allow anonymous users to view matches.
    try {
      final matchesData = await _firebaseService.getMatches();
      _matches
        ..clear()
        ..addAll(matchesData);
      notifyListeners();
    } catch (e) {
      print('Error loading matches from Firestore: $e');
    }
  }

  Future<void> saveMatchToFirestore(Map<String, dynamic> match) async {
    try {
      await _firebaseService.saveMatch(match);
      // Update local list if not already present
      final matchId = match['id'];
      final existingIndex = _matches.indexWhere((m) => m['id'] == matchId);
      if (existingIndex == -1) {
        _matches.insert(0, match);
        notifyListeners();
      }

      // Send notification for new match
      await NotificationService().sendNewMatchNotification(match);
    } catch (e) {
      print('Error saving match to Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateMatchInFirestore(
    String matchId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firebaseService.updateMatch(matchId, updates);
      // Update local list
      final existingIndex = _matches.indexWhere((m) => m['id'] == matchId);
      if (existingIndex != -1) {
        _matches[existingIndex] = {..._matches[existingIndex], ...updates};
        notifyListeners();
      }
    } catch (e) {
      print('Error updating match in Firestore: $e');
      rethrow;
    }
  }

  Future<void> deleteMatchFromFirestore(String matchId) async {
    try {
      await _firebaseService.deleteMatch(matchId);
      _matches.removeWhere((m) => m['id'] == matchId);
      notifyListeners();
    } catch (e) {
      print('Error deleting match from Firestore: $e');
      rethrow;
    }
  }

  void loadMatches() {
    // Load matches from Firestore when service is initialized
    // 🔒 GUARD: Only load if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in - skipping loadMatches');
      return;
    }
    loadMatchesFromFirestore();
  }

  Future<Map<String, dynamic>?> getMatch(String matchId) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching match: $e');
      return null;
    }
  }
}
