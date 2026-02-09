import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/language.dart';
import '../services/matches_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/guest_service.dart';
import '../utils/firestore_helper.dart';
import '../widgets/logobutton.dart' show LogoButton;

import '../utils/permissions.dart';
import '../models/user_permission.dart';

class HomeScreen extends StatefulWidget {
  final LocaleController ctrl;
  const HomeScreen({super.key, required this.ctrl});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _allJoinedMatches = []; // ALL joined matches
  String _username = 'User'; // Default username
  String? _profilePicUrl; // Profile picture URL
  int _unreadNotificationsCount = 0;
  UserPermission _userPermission = UserPermission.player;
  DateTime _calendarFocusedDay = DateTime.now();
  DateTime? _calendarSelectedDay;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadNotificationsCount();
    _loadJoinedMatches();
    // Load matches from Firestore
    MatchesService().loadMatchesFromFirestore();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final firebaseService = FirebaseService.instance;
        final userData = await firebaseService.getUserData(user.uid);
        if (mounted) {
          setState(() {
            if (userData['username'] != null &&
                userData['username'] is String) {
              _username = userData['username'] as String;
            }
            if (userData['profilePicUrl'] != null &&
                userData['profilePicUrl'] is String) {
              _profilePicUrl = userData['profilePicUrl'] as String;
            }
            final role = userData['role'] as String? ?? 'player';
            final permissionLevel = userData['permissionLevel'] as String?;
            _userPermission = permissionFromRole(permissionLevel ?? role);
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final notifications = await NotificationService().getNotifications();
      final unreadCount = notifications
          .where((n) => !(n['read'] ?? false))
          .length;
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread notifications count: $e');
    }
  }

  Future<void> _loadJoinedMatches() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in');
        return;
      }

      // Query matches where the current user is in the players list
      final matchesSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('players', arrayContains: user.uid)
          .get();

      if (matchesSnapshot.docs.isEmpty) {
        debugPrint('ℹ️ User has not joined any matches');
        if (mounted) {
          setState(() {
            _allJoinedMatches = [];
          });
        }
        return;
      }

      // Collect ALL joined matches with parsed dates
      final List<Map<String, dynamic>> allJoined = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var doc in matchesSnapshot.docs) {
        final matchData = Map<String, dynamic>.from(doc.data());
        matchData['id'] = doc.id;

        // Parse the match date
        final matchDate = parseFirestoreDate(matchData['date']);
        matchData['_parsedDate'] = matchDate;
        allJoined.add(matchData);
      }

      // Sort by date (upcoming first, then past)
      allJoined.sort((a, b) {
        final dateA = a['_parsedDate'] as DateTime?;
        final dateB = b['_parsedDate'] as DateTime?;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

      // Find the next upcoming match
      Map<String, dynamic>? nextMatch;
      for (var match in allJoined) {
        final matchDate = match['_parsedDate'] as DateTime?;
        if (matchDate != null) {
          final matchDay = DateTime(
            matchDate.year,
            matchDate.month,
            matchDate.day,
          );
          if (matchDay.isAtSameMomentAs(today) || matchDay.isAfter(today)) {
            nextMatch = match;
            break;
          }
        }
      }

      // If no upcoming match, use the most recent past match
      if (nextMatch == null && allJoined.isNotEmpty) {
        nextMatch = allJoined.last; // Most recent past match
      }

      if (mounted) {
        setState(() {
          _allJoinedMatches = allJoined;
        });
        debugPrint('✅ Loaded ${allJoined.length} joined matches');
        if (nextMatch != null) {
          debugPrint(
            '✅ Next match: ${nextMatch['title']} (ID: ${nextMatch['id']})',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading joined matches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.ctrl, MatchesService()]),
      builder: (context, child) {
        final ar = widget.ctrl.isArabic;
        final matchesService = MatchesService();
        var allMatches = matchesService.matches;

        // 🔒 Filter matches based on permission
        if (_userPermission == UserPermission.player) {
          allMatches = allMatches.where((m) {
            final title = (m['title'] ?? m['name'] ?? '')
                .toString()
                .toLowerCase();
            return !title.contains('private') && !title.contains('academy');
          }).toList();
        }

        // Find the joined match (next match)

        final theme = Theme.of(context);

        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Localizations.override(
            // ← FIX: supplies MaterialLocalizations
            context: context,
            delegates: const [DefaultMaterialLocalizations.delegate],
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section (moved from AppBar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                  backgroundImage:
                                      _profilePicUrl != null &&
                                          _profilePicUrl!.isNotEmpty
                                      ? NetworkImage(
                                          _profilePicUrl!.contains('?')
                                              ? '$_profilePicUrl&t=${DateTime.now().millisecondsSinceEpoch}'
                                              : '$_profilePicUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                        )
                                      : null,
                                  onBackgroundImageError:
                                      _profilePicUrl != null &&
                                          _profilePicUrl!.isNotEmpty
                                      ? (exception, stackTrace) {
                                          debugPrint(
                                            '❌ Avatar load error: $exception',
                                          );
                                        }
                                      : null,
                                  child:
                                      _profilePicUrl == null ||
                                          _profilePicUrl!.isEmpty
                                      ? Text(
                                          _username.isNotEmpty
                                              ? _username
                                                    .substring(0, 1)
                                                    .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${_welcome(ar)} $_username',
                                    style: GoogleFonts.spaceGrotesk(
                                      color:
                                          theme.textTheme.displayLarge?.color ??
                                          Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Stack(
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    if (_unreadNotificationsCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            _unreadNotificationsCount
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onPressed: () {
                                  // Check if user is guest before accessing notifications
                                  if (!GuestService.handleGuestInteraction(
                                    context,
                                    ar,
                                  )) {
                                    return; // Guest user - blocked
                                  }
                                  Navigator.pushNamed(
                                    context,
                                    '/notifications',
                                  ).then(
                                    (_) => _loadUnreadNotificationsCount(),
                                  );
                                },
                              ),
                              const LogoButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _calendar(context, ar),
                    // Your Matches Section (ALL joined matches)
                    if (_allJoinedMatches.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ar ? 'مبارياتك' : 'Your Matches',
                            style: GoogleFonts.spaceGrotesk(
                              color:
                                  theme.textTheme.displayLarge?.color ??
                                  Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_allJoinedMatches.length}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Show ALL joined matches grouped by date
                      ..._buildGroupedMatchesSection(
                        context,
                        ar,
                        _allJoinedMatches,
                        theme,
                        isJoinedSection: true,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      _near(ar),
                      style: GoogleFonts.spaceGrotesk(
                        color:
                            theme.textTheme.displayLarge?.color ?? Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (allMatches.isNotEmpty) ...[
                      ..._buildGroupedMatchesSection(
                        context,
                        ar,
                        allMatches,
                        theme,
                        isJoinedSection: false,
                      ),
                    ] else ...[
                      _noMatchesCard(context, ar),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /* ---------- texts ---------- */
  String _welcome(bool ar) => ar ? 'أهلاً بعودتك،' : 'Welcome back,';
  String _near(bool ar) => ar ? 'مباريات قريبة منك' : 'Matches Near You';

  /// Helper to format match date from various types (String, Timestamp, DateTime)
  String _formatMatchDate(dynamic date) {
    if (date == null) return '';

    final dateTime = parseFirestoreDate(date);
    if (dateTime.millisecondsSinceEpoch == 0) return date.toString();

    // Format: "Jan 6, 2026 at 2:00 PM"
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:$minute $amPm';
  }

  /// Helper to format date header (YYYY-MM-DD only)
  String _formatDateHeader(dynamic date) {
    if (date == null) return '';

    final dateTime = parseFirestoreDate(date);
    if (dateTime.millisecondsSinceEpoch == 0) return date.toString();

    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  /// Helper to group matches by date (YYYY-MM-DD)
  Map<String, List<Map<String, dynamic>>> _groupMatchesByDate(
    List<Map<String, dynamic>> matches,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final match in matches) {
      final date = parseFirestoreDate(match['date']);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(match);
    }

    // Sort groups by date ascending
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedGrouped = <String, List<Map<String, dynamic>>>{};
    for (final key in sortedKeys) {
      // Sort matches within each group by time
      final matchesInGroup = grouped[key]!;
      matchesInGroup.sort((a, b) {
        final dateA = parseFirestoreDate(a['date']);
        final dateB = parseFirestoreDate(b['date']);
        return dateA.compareTo(dateB);
      });
      sortedGrouped[key] = matchesInGroup;
    }

    return sortedGrouped;
  }

  /// Helper to build grouped matches section
  List<Widget> _buildGroupedMatchesSection(
    BuildContext context,
    bool ar,
    List<Map<String, dynamic>> matches,
    ThemeData theme, {
    required bool isJoinedSection,
  }) {
    final groupedMatches = _groupMatchesByDate(matches);
    final widgets = <Widget>[];

    for (final dateKey in groupedMatches.keys) {
      final matchesOnDate = groupedMatches[dateKey]!;
      final firstMatch = matchesOnDate.first;

      // Date Header
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _formatDateHeader(firstMatch['date']),
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.displayLarge?.color ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // Flat list - individual match cards wrapped in soft elevated containers
      widgets.addAll(
        matchesOnDate.map((match) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isJoinedSection
                  ? _buildGroupedMatchCard(
                      context,
                      ar,
                      match,
                      theme,
                      isJoined: true,
                    )
                  : _buildGroupedMatchCard(
                      context,
                      ar,
                      match,
                      theme,
                      isJoined: false,
                    ),
            ),
          );
        }).toList(),
      );
    }

    return widgets;
  }

  /// Helper to build match card for grouped sections (without extra margins)
  Widget _buildGroupedMatchCard(
    BuildContext context,
    bool ar,
    Map<String, dynamic> match,
    ThemeData theme, {
    required bool isJoined,
  }) {
    if (isJoined) {
      return _buildNextMatchCard(context, ar, match, theme);
    } else {
      return _nearCard(context, ar, match);
    }
  }

  /* ---------- calendar widget ---------- */
  Widget _calendar(BuildContext context, bool ar) {
    final theme = Theme.of(context);
    final matchesService = MatchesService();
    final allMatches = matchesService.matches;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _calendarFocusedDay,
        selectedDayPredicate: (d) => isSameDay(_calendarSelectedDay, d),
        onDaySelected: (s, f) => setState(() {
          _calendarSelectedDay = s;
          _calendarFocusedDay = f;
        }),
        eventLoader: (day) {
          final matchesOnDay = allMatches.where((match) {
            final matchDate = parseFirestoreDate(match['date']);
            return isSameDay(matchDate, day);
          }).toList();

          if (matchesOnDay.isNotEmpty) {
            debugPrint(
              'Found ${matchesOnDay.length} matches on ${day.toString()}',
            );
          }

          return matchesOnDay;
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;

            return Positioned(
              bottom: 4,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
                child: const Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
          singleMarkerBuilder: (context, date, event) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              width: 6,
              height: 6,
              child: const Center(
                child: Icon(Icons.sports_soccer, size: 12, color: Colors.white),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          defaultTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          weekendTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
          markerDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
          markerSize: 6.0,
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.textTheme.bodyMedium?.color,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  /* ---------- Your Next Match card (flat design) ---------- */
  Widget _buildNextMatchCard(
    BuildContext context,
    bool ar,
    Map<String, dynamic> match,
    ThemeData theme,
  ) {
    final visibility = match['visibility'] as String?;
    final isAcademy = visibility == 'academy';
    final isPrivate = visibility == 'private';

    // Check payment status
    bool hasPaid = false;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && match['participants'] != null) {
      final participants = List.from(match['participants']);
      final p = participants.firstWhere(
        (p) => p['userId'] == currentUser.uid,
        orElse: () => null,
      );
      if (p != null) {
        hasPaid = p['hasPaid'] ?? false;
      }
    }

    return InkWell(
      onTap: () => _navigateToMatchDetails(context, match),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Joined Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    match['title'] ?? match['name'] ?? 'Match',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAcademy) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'أكاديمية' : 'Academy',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isPrivate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'خاص' : 'Private',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ar ? 'انضممت' : 'Joined',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPaid) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: const Text('✅', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Date
            Text(
              _formatMatchDate(match['date']),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            // Meta info row
            Row(
              children: [
                if (match['fieldName'] != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      match['fieldName'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Players bar and action button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match['playersCount'] ?? 0}/${match['maxPlayers'] ?? 10}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (match['maxPlayers'] ?? 10) > 0
                            ? (match['playersCount'] ?? 0) /
                                  (match['maxPlayers'] ?? 10)
                            : 0,
                        backgroundColor: theme.dividerColor.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary.withOpacity(0.6),
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _navigateToMatchDetails(context, match),
                  icon: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  label: Text(ar ? 'عرض التفاصيل' : 'View Details'),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /* ---------- next match card (clickable) ---------- */

  /* ---------- no match card ---------- */

  /* ---------- near you card (flat design) ---------- */
  Widget _nearCard(BuildContext context, bool ar, Map match) {
    final theme = Theme.of(context);
    final matchId = match['id']?.toString();
    // Check if this match is in the user's joined matches list
    final isJoined = _allJoinedMatches.any(
      (m) => m['id']?.toString() == matchId,
    );
    final visibility = match['visibility'] as String?;
    final isAcademy = visibility == 'academy';
    final isPrivate = visibility == 'private';

    // Check payment status
    bool hasPaid = false;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && match['participants'] != null) {
      final participants = List.from(match['participants']);
      final p = participants.firstWhere(
        (p) => p['userId'] == currentUser.uid,
        orElse: () => null,
      );
      if (p != null) {
        hasPaid = p['hasPaid'] ?? false;
      }
    }

    return InkWell(
      onTap: () => _navigateToMatchDetails(context, match),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Joined Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    match['title'] ?? match['name'] ?? 'Match',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAcademy) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'أكاديمية' : 'Academy',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isPrivate) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'خاص' : 'Private',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isJoined) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ar ? 'انضممت' : 'Joined',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPaid) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: const Text('✅', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Date
            Text(
              _formatMatchDate(match['date']),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            // Meta info row
            Row(
              children: [
                if (match['fieldName'] != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      match['fieldName'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                if (match['time'] != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    match['time'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Players bar and action button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${match['playersCount'] ?? 0}/${match['maxPlayers'] ?? 10}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: (match['maxPlayers'] ?? 10) > 0
                            ? (match['playersCount'] ?? 0) /
                                  (match['maxPlayers'] ?? 10)
                            : 0,
                        backgroundColor: theme.dividerColor.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary.withOpacity(0.6),
                        ),
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: isJoined
                      ? () => _navigateToMatchDetails(context, match)
                      : () => _joinToMatch(match),
                  icon: Icon(
                    isJoined ? Icons.info_outline : Icons.person_add,
                    size: 18,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: Text(
                    isJoined
                        ? (ar ? 'عرض التفاصيل' : 'View Details')
                        : ((match['playersCount'] ?? 0) >=
                                  (match['maxPlayers'] ?? 10)
                              ? (ar ? 'قائمة الانتظار' : 'Waiting List')
                              : (ar ? 'انضم' : 'Join')),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /* ---------- no matches card ---------- */
  Widget _noMatchesCard(BuildContext context, bool ar) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_soccer,
            color: theme.colorScheme.primary.withOpacity(0.6),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            ar ? 'لا توجد مباريات' : 'No matches available',
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.displayLarge?.color ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'أضف مباراة جديدة  استكشف المباريات القريبة'
                : 'Add a new match or explore nearby matches',
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.bodyMedium?.color ?? Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /* ---------- Navigation Methods ---------- */
  void _navigateToMatchDetails(BuildContext context, Map match) {
    // Check if user is guest before navigating
    final ar = widget.ctrl.isArabic;
    if (!GuestService.handleGuestInteraction(context, ar)) {
      return; // Guest user - blocked
    }

    // Debug print to check match data
    debugPrint('Navigating to MatchDetails with match:');
    debugPrint(match.toString());
    debugPrint('Field: ${match['field']?.toString()}');

    Navigator.pushNamed(
      context,
      '/matchDetails',
      arguments: {'match': match, 'field': match['field']},
    ).then((_) {
      // Reload joined matches when returning from MatchDetails
      _loadJoinedMatches();
    });
  }

  void _joinToMatch(Map match) {
    // Check if user is guest before joining
    final ar = widget.ctrl.isArabic;
    if (!GuestService.handleGuestInteraction(context, ar)) {
      return; // Guest user - blocked
    }

    final currentPlayers = match['playersCount'] ?? 0;
    final maxPlayers = match['maxPlayers'] ?? 10;
    final isFull = currentPlayers >= maxPlayers;
    final matchId = match['id']?.toString();

    setState(() {
      // Add to _allJoinedMatches if not already there
      if (!_allJoinedMatches.any((m) => m['id']?.toString() == matchId)) {
        _allJoinedMatches.add(Map<String, dynamic>.from(match));
      }

      // Add to waiting list if full, otherwise increment player count
      if (isFull) {
        match['waitingList'] = match['waitingList'] ?? [];
        match['waitingList'].add({
          'userId': 'current_user_id', // Replace with actual user ID
          'joinedAt': DateTime.now().toIso8601String(),
        });
      } else {
        match['playersCount'] = currentPlayers + 1;
      }
    });

    // Show appropriate success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFull
              ? (widget.ctrl.isArabic
                    ? 'تمت الإضافة إلى قائمة الانتظار!'
                    : 'Added to waiting list!')
              : (widget.ctrl.isArabic
                    ? 'تم الانضمام إلى المباراة بنجاح!'
                    : 'Successfully joined the match!'),
        ),
        backgroundColor: isFull ? Colors.orange : Colors.green,
      ),
    );
  }
}
