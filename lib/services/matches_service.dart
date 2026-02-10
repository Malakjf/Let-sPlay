import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

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

  List<Map<String, dynamic>> getMatchesByField(String fieldName) {
    return _matches.where((match) => match['fieldName'] == fieldName).toList();
  }

  List<Map<String, dynamic>> searchMatches(String query) {
    if (query.trim().isEmpty) return List.unmodifiable(_matches);

    final searchTerm = query.toLowerCase().trim();
    return _matches.where((match) {
      final title = (match['title'] ?? match['name'] ?? '')
          .toString()
          .toLowerCase();
      final fieldName = (match['fieldName'] ?? '').toString().toLowerCase();
      final location = (match['fieldLocation'] ?? '').toString().toLowerCase();

      return title.contains(searchTerm) ||
          fieldName.contains(searchTerm) ||
          location.contains(searchTerm);
    }).toList();
  }

  // Firestore integration methods
  Future<void> loadMatchesFromFirestore() async {
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
