import 'package:flutter/foundation.dart';

class MatchesStore extends ChangeNotifier {
  MatchesStore._internal();
  static final MatchesStore _instance = MatchesStore._internal();
  factory MatchesStore() => _instance;

  final List<Map<String, dynamic>> _matches = [];

  List<Map<String, dynamic>> get matches => List.unmodifiable(_matches);

  void addMatch(Map<String, dynamic> match) {
    // Ensure default players fields
    final m = Map<String, dynamic>.from(match);
    m['playersCount'] = m['playersCount'] ?? 0;
    m['maxPlayers'] = m['maxPlayers'] ?? 10;
    _matches.insert(0, m);
    notifyListeners();
  }

  void incrementPlayers(String matchIdOrName) {
    // matchIdOrName can be name or id; fallback: find by name
    final idx = _matches.indexWhere((m) =>
        (m['id'] != null && m['id'] == matchIdOrName) ||
        (m['name'] != null && m['name'] == matchIdOrName));
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
}

class MatchesStoreMock extends ChangeNotifier {
  MatchesStoreMock._internal();
  static final MatchesStoreMock instance = MatchesStoreMock._internal();

  List<Map<String, dynamic>> get _matches => [
        //{
        //   'title': 'Casual Kickabout',
        //   'type': '5v5',
        //   'date': '10/26',
        //   'playersCount': 8,
        //   'maxPlayers': 10,
        //   'image': 'assets/images/logo.png',
        // },
        // {
        //   'title': 'Evening Scrimmage',
        //   'type': '7v7',
        //   'date': '10/27',
        //   'playersCount': 10,
        //   'maxPlayers': 14,
        //   'image': 'assets/images/logo.png',
        // },
      ];

  List<Map<String, dynamic>> get matches => _matches;

  void addMatch(Map<String, dynamic> match) {
    // Ensure keys exist and sensible defaults
    match.putIfAbsent('title', () => 'New Match');
    match.putIfAbsent('type', () => '5v5');
    match.putIfAbsent('date', () => 'TBD');
    match.putIfAbsent('playersCount', () => 0);
    match.putIfAbsent('maxPlayers', () => 10);
    match.putIfAbsent('image', () => 'assets/images/logo.png');

    _matches.insert(0, match);
    notifyListeners();
  }

  void joinMatch(Map<String, dynamic> match) {
    final idx = _matches.indexOf(match);
    if (idx == -1) return;
    final current = _matches[idx]['playersCount'] ?? 0;
    final max = _matches[idx]['maxPlayers'] ?? 0;
    if (current < max) {
      _matches[idx]['playersCount'] = current + 1;
      notifyListeners();
    }
  }
}
