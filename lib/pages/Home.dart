import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
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
  bool _isJoiningMatch = false; // Add loading state for join button

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadNotificationsCount();
    _loadJoinedMatches();
    // Load matches from Firestore - only if user is logged in
    _loadMatchesIfAuthenticated();
  }

  /// 🔒 Load matches only if user is authenticated
  Future<void> _loadMatchesIfAuthenticated() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Guest mode - skipping loadMatchesFromFirestore');
      return;
    }
    // User is authenticated, load matches
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
    // 🔒 GUARD: Don't load notifications if no user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('⚠️ Guest mode - skipping notifications load');
      return;
    }
    
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
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Calculate responsive values
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final verticalPadding = screenHeight * 0.02; // 2% of screen height
    final titleFontSize = screenWidth > 600 ? 24.0 : 20.0;
    final avatarRadius = screenWidth > 600 ? 24.0 : 20.0;
    
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
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section (moved from AppBar)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: screenHeight * 0.015,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: avatarRadius,
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
                                                  fontSize: MediaQuery.textScaleFactorOf(context) * 16,
                                                ),
                                              )
                                            : null,
                                  ),
                                  SizedBox(width: screenWidth * 0.025),
                                  Expanded(
                                    child: Text(
                                      '${_welcome(ar)} $_username',
                                      style: GoogleFonts.spaceGrotesk(
                                        color:
                                            theme.textTheme.displayLarge?.color ??
                                            Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: titleFontSize,
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
                                        size: screenWidth > 600 ? 28 : 24,
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
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: MediaQuery.textScaleFactorOf(context) * 10,
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
                      _calendar(context, ar, screenWidth, screenHeight),
                      SizedBox(height: screenHeight * 0.03), // Clean spacing to matches section
                      // Your Matches Section (ALL joined matches)
                      if (_allJoinedMatches.isNotEmpty) ...[
                        SizedBox(height: screenHeight * 0.025),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ar ? 'مبارياتك' : 'Your Matches',
                              style: GoogleFonts.spaceGrotesk(
                                color:
                                    theme.textTheme.displayLarge?.color ??
                                    Colors.white,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenHeight * 0.005,
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
                                  fontSize: MediaQuery.textScaleFactorOf(context) * 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        // Show ALL joined matches grouped by date
                        ..._buildGroupedMatchesSection(
                          context,
                          ar,
                          _allJoinedMatches,
                          theme,
                          screenWidth,
                          screenHeight,
                          isJoinedSection: true,
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.025),
                      Text(
                        _near(ar),
                        style: GoogleFonts.spaceGrotesk(
                          color:
                              theme.textTheme.displayLarge?.color ?? Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      if (allMatches.isNotEmpty) ...[
                        ..._buildGroupedMatchesSection(
                          context,
                          ar,
                          allMatches,
                          theme,
                          screenWidth,
                          screenHeight,
                          isJoinedSection: false,
                        ),
                      ] else ...[
                        _noMatchesCard(context, ar, screenWidth, screenHeight),
                      ],
                      // Bottom padding for safe area
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
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

  /// Helper to format date header (e.g., Sunday, March 15, 2026)
  String _formatDateHeader(dynamic date) {
    if (date == null) return '';

    final dateTime = parseFirestoreDate(date);
    if (dateTime.millisecondsSinceEpoch == 0) return date.toString();

    // Use DateFormat for robust and localized formatting
    // 'EEEE, MMMM d, y' -> Sunday, March 15, 2026
    return DateFormat('EEEE, MMMM d, y').format(dateTime);
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
    ThemeData theme,
    double screenWidth,
    double screenHeight, {
    required bool isJoinedSection,
  }) {
    final groupedMatches = _groupMatchesByDate(matches);
    final widgets = <Widget>[];
    
    // Responsive values
    final headerFontSize = screenWidth > 600 ? 20.0 : 18.0;
    final cardMarginBottom = screenHeight * 0.025;

    for (final dateKey in groupedMatches.keys) {
      final matchesOnDate = groupedMatches[dateKey]!;
      final firstMatch = matchesOnDate.first;

      // Date Header
      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.015),
          child: Text(
            _formatDateHeader(firstMatch['date']),
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.displayLarge?.color ?? Colors.white,
              fontSize: headerFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // Flat list - individual match cards wrapped in soft elevated containers
      widgets.addAll(
        matchesOnDate.map((match) {
          return Container(
            margin: EdgeInsets.only(bottom: cardMarginBottom),
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
                      screenWidth,
                      screenHeight,
                      isJoined: true,
                    )
                  : _buildGroupedMatchCard(
                      context,
                      ar,
                      match,
                      theme,
                      screenWidth,
                      screenHeight,
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
    ThemeData theme,
    double screenWidth,
    double screenHeight, {
    required bool isJoined,
  }) {
    if (isJoined) {
      return _buildNextMatchCard(context, ar, match, theme, screenWidth, screenHeight);
    } else {
      return _nearCard(context, ar, match, screenWidth, screenHeight);
    }
  }

  /* ---------- calendar widget ---------- */
  Widget _calendar(BuildContext context, bool ar, double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final matchesService = MatchesService();
    final allMatches = matchesService.matches;
    
    // Responsive sizing for calendar
    final rowHeight = screenHeight * 0.055; // ~44px responsive
    final headerFontSize = screenWidth > 600 ? 18.0 : 16.0;
    final dayFontSize = screenWidth > 600 ? 14.0 : 12.0;
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.42,
        ),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _calendarFocusedDay,
          calendarFormat: CalendarFormat.month,
          sixWeekMonthsEnforced: true,
        rowHeight: rowHeight,
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
            final eventCount = events.length;
            return Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 12,
                      color: Colors.white,
                    ),
                    if (eventCount > 1) ...[
                      const SizedBox(width: 2),
                      Text(
                        '${eventCount > 9 ? '9+' : eventCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          selectedDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                  theme.colorScheme.secondary.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
          ),
          defaultTextStyle: GoogleFonts.spaceGrotesk(
            color: theme.textTheme.bodyMedium?.color ?? Colors.white70,
            fontSize: dayFontSize,
            fontWeight: FontWeight.w500,
          ),
          weekendTextStyle: GoogleFonts.spaceGrotesk(
            color: theme.colorScheme.primary,
            fontSize: dayFontSize,
            fontWeight: FontWeight.bold,
          ),
          outsideTextStyle: TextStyle(
            color: Colors.grey.withOpacity(0.3),
            fontSize: dayFontSize - 1,
          ),
          markersMaxCount: 2,
          markerSize: 8.0,
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GoogleFonts.spaceGrotesk(
            color: theme.textTheme.bodyLarge?.color ?? Colors.white,
            fontSize: headerFontSize,
            fontWeight: FontWeight.w700,
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white70,
            size: 28,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white70,
            size: 28,
          ),
        ),
      ),
    )
    );
  }

  /* ---------- Your Next Match card (flat design) ---------- */
  Widget _buildNextMatchCard(
    BuildContext context,
    bool ar,
    Map<String, dynamic> match,
    ThemeData theme,
    double screenWidth,
    double screenHeight,
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
    
    // Responsive values
    final titleFontSize = screenWidth > 600 ? 18.0 : 16.0;
    final iconSize = screenWidth > 600 ? 18.0 : 16.0;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;

    return InkWell(
      onTap: () => _navigateToMatchDetails(context, match),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
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
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAcademy) ...[
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.015,
                      vertical: screenHeight * 0.003,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'أكاديمية' : 'Academy',
                      style: TextStyle(
                        fontSize: MediaQuery.textScaleFactorOf(context) * 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isPrivate) ...[
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.015,
                      vertical: screenHeight * 0.003,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'خاص' : 'Private',
                      style: TextStyle(
                        fontSize: MediaQuery.textScaleFactorOf(context) * 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenHeight * 0.005,
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
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        ar ? 'انضممت' : 'Joined',
                        style: TextStyle(
                          fontSize: MediaQuery.textScaleFactorOf(context) * 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasPaid) ...[
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.5)),
                    ),
                    child: Text('✅', style: TextStyle(fontSize: MediaQuery.textScaleFactorOf(context) * 12)),
                  ),
                ],
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            // Date
            Text(
              _formatMatchDate(match['date']),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: MediaQuery.textScaleFactorOf(context) * 14,
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            // Meta info row
            Row(
              children: [
                if (match['fieldName'] != null) ...[
                  Icon(
                    Icons.location_on,
                    size: iconSize,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Expanded(
                    child: Text(
                      match['fieldName'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                        fontSize: MediaQuery.textScaleFactorOf(context) * 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
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
                            size: iconSize,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            '${match['playersCount'] ?? 0}/${match['maxPlayers'] ?? 10}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: MediaQuery.textScaleFactorOf(context) * 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.008),
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
                SizedBox(width: screenWidth * 0.04),
                ElevatedButton.icon(
                  onPressed: () => _navigateToMatchDetails(context, match),
                  icon: Icon(
                    Icons.info_outline,
                    size: iconSize,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.035,
                      vertical: screenHeight * 0.012,
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
  Widget _nearCard(BuildContext context, bool ar, Map<String, dynamic> match, double screenWidth, double screenHeight) {
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
    
    // Responsive values
    final titleFontSize = screenWidth > 600 ? 18.0 : 16.0;
    final iconSize = screenWidth > 600 ? 18.0 : 16.0;
    final horizontalPadding = screenWidth * 0.04;
    final verticalPadding = screenHeight * 0.02;

    return InkWell(
      onTap: () => _navigateToMatchDetails(context, match),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: horizontalPadding),
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
                      fontSize: titleFontSize,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isAcademy) ...[
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.015,
                      vertical: screenHeight * 0.003,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'أكاديمية' : 'Academy',
                      style: TextStyle(
                        fontSize: MediaQuery.textScaleFactorOf(context) * 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isPrivate) ...[
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.015,
                      vertical: screenHeight * 0.003,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      ar ? 'خاص' : 'Private',
                      style: TextStyle(
                        fontSize: MediaQuery.textScaleFactorOf(context) * 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isJoined) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
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
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          ar ? 'انضممت' : 'Joined',
                          style: TextStyle(
                            fontSize: MediaQuery.textScaleFactorOf(context) * 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasPaid) ...[
                    SizedBox(width: screenWidth * 0.02),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: Text('✅', style: TextStyle(fontSize: MediaQuery.textScaleFactorOf(context) * 12)),
                    ),
                  ],
                ],
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            // Date
            Text(
              _formatMatchDate(match['date']),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: MediaQuery.textScaleFactorOf(context) * 14,
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            // Meta info row
            Row(
              children: [
                if (match['fieldName'] != null) ...[
                  Icon(
                    Icons.location_on,
                    size: iconSize,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Expanded(
                    child: Text(
                      match['fieldName'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                        fontSize: MediaQuery.textScaleFactorOf(context) * 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
                if (match['time'] != null) ...[
                  SizedBox(width: screenWidth * 0.04),
                  Icon(
                    Icons.access_time,
                    size: iconSize,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    match['time'].toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                      fontSize: MediaQuery.textScaleFactorOf(context) * 12,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
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
                            size: iconSize,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.6),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            '${match['playersCount'] ?? 0}/${match['maxPlayers'] ?? 10}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: MediaQuery.textScaleFactorOf(context) * 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.008),
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
                SizedBox(width: screenWidth * 0.04),
                ElevatedButton.icon(
                  onPressed: isJoined
                      ? () => _navigateToMatchDetails(context, match)
                      : () => _joinToMatch(match),
                  icon: Icon(
                    isJoined ? Icons.info_outline : Icons.person_add,
                    size: iconSize,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.035,
                      vertical: screenHeight * 0.012,
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
  Widget _noMatchesCard(BuildContext context, bool ar, double screenWidth, double screenHeight) {
    final theme = Theme.of(context);
    final iconSize = screenWidth > 600 ? 64.0 : 48.0;
    final titleFontSize = screenWidth > 600 ? 22.0 : 18.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      padding: EdgeInsets.all(screenHeight * 0.025),
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
            size: iconSize,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            ar ? 'لا توجد مباريات' : 'No matches available',
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.displayLarge?.color ?? Colors.white,
              fontSize: titleFontSize,
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
  void _navigateToMatchDetails(BuildContext context, Map<String, dynamic> match) {
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

  Future<void> _joinToMatch(Map<String, dynamic> match) async {
    // Check if user is guest before joining
    final ar = widget.ctrl.isArabic;
    if (GuestService.handleGuestInteraction(context, ar)) {
      return; // Guest user - blocked
    }
    if (_isJoiningMatch) {
      return; // Prevent double-taps
    }

    setState(() {
      _isJoiningMatch = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ar ? 'يجب عليك تسجيل الدخول أولاً' : 'You must be logged in.')),
        );
        setState(() => _isJoiningMatch = false);
      }
      return;
    }

    final matchId = match['id']?.toString();
    if (matchId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ar ? 'معرف المباراة غير صالح' : 'Invalid Match ID.')),
        );
        setState(() => _isJoiningMatch = false);
      }
      return;
    }

    final matchRef = FirebaseFirestore.instance.collection('matches').doc(matchId);

    try {
      // Use a Firestore Transaction for atomic read-modify-write
      String status = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(matchRef);

        if (!snapshot.exists) {
          throw Exception("Match does not exist!");
        }

        final matchData = snapshot.data()!;
        final List<dynamic> players = List.from(matchData['players'] ?? []);
        final List<dynamic> waitingList = List.from(matchData['waitingList'] ?? []);
        final int maxPlayers = matchData['maxPlayers'] ?? 10;

        if (players.contains(user.uid) || waitingList.any((p) => p is Map && p['userId'] == user.uid)) {
          throw Exception(ar ? 'لقد انضممت بالفعل إلى هذه المباراة' : 'You have already joined this match.');
        }

        if (players.length < maxPlayers) {
          transaction.update(matchRef, {
            'players': FieldValue.arrayUnion([user.uid]),
            'playersCount': FieldValue.increment(1),
          });
          return ar ? 'تم الانضمام إلى المباراة بنجاح!' : 'Successfully joined the match!';
        } else {
          transaction.update(matchRef, {
            'waitingList': FieldValue.arrayUnion([
              {'userId': user.uid, 'joinedAt': Timestamp.now()}
            ]),
          });
          return ar ? 'تمت الإضافة إلى قائمة الانتظار!' : 'Added to waiting list!';
        }
      });

      // On success, refresh data from Firestore and show message
      if (mounted) {
        await _loadJoinedMatches();
        await MatchesService().loadMatchesFromFirestore(); // Refresh public matches
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningMatch = false;
        });
      }
    }
  }
}
