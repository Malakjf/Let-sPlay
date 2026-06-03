// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:letsplay/utils/permissions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_permission.dart' show UserPermission;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language.dart';
import '../services/guest_service.dart';
import '../models/player.dart';
import '../widgets/FutCardFull.dart';
import '../widgets/FutCardResponsive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import '../widgets/LogoButton.dart' show LogoButton;
import '../widgets/PlayerMatchStatsStrip.dart';
import 'package:letsplay/services/player_stats_store.dart';
import 'package:letsplay/pages/performance_rating_page.dart';
import 'package:letsplay/services/player_metrics_store.dart';
import '../widgets/AvatarUploadDialog.dart';

class ProfileScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Player player;
  final UserPermission userPermission;
  final bool isPopup;

  const ProfileScreen({
    super.key,
    required this.ctrl,
    required this.player,
    this.userPermission = UserPermission.coach,
    this.isPopup = false,
  });

  /// Reusable method to open a player's profile from anywhere in the app.
  static void show(
    BuildContext context, {
    required LocaleController ctrl,
    required Player player,
    required UserPermission viewerPermission,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          ctrl: ctrl,
          player: player,
          userPermission: viewerPermission,
        ),
      ),
    );
  }

  /// Opens the exact same profile layout as a premium modal popup.
  /// Used for "View Profile" actions in Users Management and Performance Rating.
  static void showPlayerProfilePopup(
    BuildContext context, {
    required LocaleController ctrl,
    required Player player,
    required UserPermission viewerPermission,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E27),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: ProfileScreen(
              ctrl: ctrl,
              player: player,
              userPermission: viewerPermission,
              isPopup: true,
            ),
          ),
        ),
      ),
    );
  }

  /// Opens a player profile from dynamic data maps (User Management / Match Lists).
  static void showFromMap(
    BuildContext context, {
    required LocaleController ctrl,
    required Map<String, dynamic> data,
    required UserPermission viewerPermission,
    bool asPopup = false,
  }) {
    final p = Player(
      id: data['uid'] ?? data['id'] ?? '',
      name: data['name'] ?? data['username'] ?? 'Player',
      position: data['position'] ?? 'ST',
      imageUrl: data['avatarUrl'] ?? data['imageUrl'] ?? '',
      goals: 0,
      assists: 0,
      motm: 0,
      matches: 0,
      level: 1,
      metrics: {},
      countryFlagUrl: '',
      club: '',
      nationality: '',
      rating: 0,
      badges: [],
      yellowCards: 0,
      redCards: 0,
      notes: '',
    );

    if (asPopup) {
      showPlayerProfilePopup(
        context,
        ctrl: ctrl,
        player: p,
        viewerPermission: viewerPermission,
      );
    } else {
      show(context, ctrl: ctrl, player: p, viewerPermission: viewerPermission);
    }
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;
  String? _optimisticAvatarUrl;

  // Prevent showing fallback/stale defaults (LV=1, 0s) before Firebase career stats arrive.
  // We consider stats "ready" only when the store has a real entry for the user.

  // 🚀 Level Up Logic
  int? _lastSeenLevel;
  int? _lastLevelUpTimestampMillis;
  bool _isPlayingCelebration = false;
  int _prevLevel = 0;
  int _currLevel = 0;
  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF38BDF8)),
        label: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: const Color(0xFF38BDF8),
          elevation: 0,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool ar, ThemeData theme) {
    return SizedBox(
      width: 140,
      child: ElevatedButton.icon(
        onPressed: () async {
          await FirebaseAuth.instance.signOut();

          if (!context.mounted) return;

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: Text(ar ? 'تسجيل الخروج' : 'Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E293B),
          foregroundColor: Colors.redAccent,
          minimumSize: const Size(140, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Initializes level tracking from SharedPreferences
  Future<void> _initLevelTracking() async {
    final prefs = await SharedPreferences.getInstance();
    // Support legacy key `last_seen_level_{id}` but prefer new keys.
    final shown =
        prefs.getInt('lastLevelShown_${widget.player.id}') ??
        prefs.getInt('last_seen_level_${widget.player.id}');
    final ts = prefs.getInt('lastLevelUpTimestamp_${widget.player.id}');
    if (mounted) {
      setState(() {
        _lastSeenLevel = shown;
        _lastLevelUpTimestampMillis = ts;
      });
    }
  }

  /// Triggers the Level Up celebration sequence
  void _triggerLevelUpCelebration(int oldLevel, int newLevel) {
    if (_isPlayingCelebration) return;
    setState(() {
      _prevLevel = oldLevel;
      _currLevel = newLevel;
      _isPlayingCelebration = true;
    });

    // Auto-dismiss celebration after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isPlayingCelebration = false);
    });
  }

  /// Handles the avatar update process with cache eviction and optimistic UI
  Future<void> _updateAvatar(
    BuildContext context,
    String userId,
    String? currentUrl,
  ) async {
    final ar = widget.ctrl.isArabic;

    final String? newUrl = await showAvatarUploadDialog(
      context: context,
      userId: userId,
      currentAvatarUrl: currentUrl,
    );

    if (newUrl != null && mounted) {
      setState(() {
        _isUploading = true;
        _optimisticAvatarUrl = newUrl;
      });

      // Give Firestore a moment to sync and the UI to breathe
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'تم تحديث الصورة بنجاح' : 'Profile picture updated!',
            ),
          ),
        );
      }
    }
  }

  /// Scrolls the profile page to the top.
  /// This can be called by the parent widget when the profile tab is reselected.
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final userId = widget.player.id;
    // Perform async setup after the first frame so Provider context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _postInit(userId);
    });
  }

  Future<void> _postInit(String userId) async {
    // Initialize persisted level tracking first
    await _initLevelTracking();

    // Subscribe to stores
    Provider.of<PlayerAttributesStore>(
      context,
      listen: false,
    ).subscribeToPlayer(userId);

    Provider.of<PlayerMetricsStore>(
      context,
      listen: false,
    ).subscribeToUser(userId);

    // Ensure career stats are loaded before checking level
    final statsStore = Provider.of<PlayerStatsStore>(context, listen: false);
    await statsStore.loadCareerStats(userId);

    // After loading stats and initializing prefs, check level up status
    await _checkLevelUpStatus();
  }

  /// Checks persisted level state vs current level and triggers/replays celebration.
  Future<void> _checkLevelUpStatus() async {
    final userId = widget.player.id;

    final prefs = await SharedPreferences.getInstance();

    // Read current level from PlayerStatsStore
    final statsStore = Provider.of<PlayerStatsStore>(context, listen: false);
    final level = statsStore
        .getStat(userId, PlayerStatsStore.statLevel)
        .toInt();

    print('Current Level: $level');
    print('Last Seen Level: $_lastSeenLevel');
    print('Last Timestamp: $_lastLevelUpTimestampMillis');

    // If we have no record yet, initialize persisted value without triggering
    if (_lastSeenLevel == null) {
      _lastSeenLevel = level;
      await prefs.setInt('lastLevelShown_$userId', level);
      return;
    }

    // If level increased -> persist and trigger celebration once
    if (level > _lastSeenLevel!) {
      final nowMillis = DateTime.now().millisecondsSinceEpoch;
      _lastLevelUpTimestampMillis = nowMillis;
      _lastSeenLevel = level;
      await prefs.setInt('lastLevelShown_$userId', level);
      await prefs.setInt('lastLevelUpTimestamp_$userId', nowMillis);
      print('Level Up Triggered');
      if (!_isPlayingCelebration) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _triggerLevelUpCelebration(level - 1, level);
        });
      }
      return;
    }

    // If same level, replay if within 24 hours
    if (level == _lastSeenLevel) {
      final ts =
          _lastLevelUpTimestampMillis ??
          prefs.getInt('lastLevelUpTimestamp_$userId');
      print('Checked timestamp (prefs or memory): $ts');
      if (ts != null) {
        final nowMillis = DateTime.now().millisecondsSinceEpoch;
        const dayMs = 24 * 60 * 60 * 1000;
        final elapsed = nowMillis - ts;
        if (elapsed <= dayMs) {
          print('Replaying Level Up (within 24h)');
          if (!_isPlayingCelebration) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                // ignore: curly_braces_in_flow_control_structures
                _triggerLevelUpCelebration(
                  (level > 0) ? level - 1 : level,
                  level,
                );
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);
    final userId = widget.player.id;

    // ✅ Wrap FutureBuilder with Consumer to ensure Provider scope is valid
    // and to avoid context.read() issues inside the builder
    return Consumer<PlayerStatsStore>(
      builder: (context, statsStore, _) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
          builder: (context, snapshot) {
            // Check for permission denied errors specifically for guest/unauthorized access
            final errorString = snapshot.error?.toString() ?? '';
            final isPermissionDenied =
                errorString.contains('permission-denied') ||
                errorString.contains('PERMISSION_DENIED');

            if (isPermissionDenied) {
              return _buildLimitedProfile(context, ar, theme, userId);
            }

            // We don't return early for snapshot.hasError or connectionState.waiting anymore.
            // Instead, we use widget.player as the immediate source of truth,
            // and snapshot.data as the reactive source of truth.
            final rawData = snapshot.data?.data();
            final Map<String, dynamic> data = rawData == null
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(rawData as Map);

            final name = data['name'] ?? data['username'] ?? widget.player.name;
            final position = data['position'] ?? widget.player.position;
            final avatarUrl = data['avatarUrl'] ?? widget.player.imageUrl;
            final countryFlagUrl =
                data['countryFlagUrl'] ?? widget.player.countryFlagUrl;
            final role = data['role'] ?? widget.player.notes ?? 'Player';
            final permissionLevel = data['permissionLevel'] as String?;
            final currentPermission = permissionFromRole(
              permissionLevel ?? role,
            );
            final isGk = (position.toString().toUpperCase() == 'GK');
            final isOwnProfile =
                FirebaseAuth.instance.currentUser?.uid == userId;

            // 🎯 Use PlayerStatsStore as the single source of truth for stats and level
            // This ensures values match the "View Profile" popup exactly.
            final level = statsStore
                .getStat(userId, PlayerStatsStore.statLevel)
                .toInt();
            final double xp = statsStore
                .getStat(userId, PlayerStatsStore.statXP)
                .toDouble();

            final isAcademy = data['isAcademyPlayer'] == true;

            // Level-up handling moved to init flow: use _checkLevelUpStatus()

            bool isValidUrl(String? url) {
              if (url == null || url.isEmpty) return false;
              return url.startsWith('http://') || url.startsWith('https://');
            }

            // دالة كسر الكاش: تجبر المتصفح/التطبيق على تحميل الصورة الجديدة عند تغير updatedAt
            String bust(String url) {
              if (url.isEmpty || !url.startsWith('http')) return url;
              final dynamic updatedAt =
                  data['updatedAt'] ?? data['updated_at'] ?? '1';
              // معالجة الوقت ليكون أرقاماً فقط لضمان سلامة الرابط
              final version = updatedAt is Timestamp
                  ? updatedAt.millisecondsSinceEpoch
                  : updatedAt.toString().replaceAll(RegExp(r'[^0-9]'), '');
              return '$url${url.contains('?') ? '&' : '?'}v=$version';
            }

            return Directionality(
              textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: widget.isPopup
                    ? Colors.transparent
                    : theme.scaffoldBackgroundColor,
                body: SafeArea(
                  top: !widget.isPopup,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        controller: _scrollController,
                        key: PageStorageKey('profile_scroll_$userId'),
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: Column(
                          children: [
                            // Header with LogoButton
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Center(
                                    child: Text(
                                      _getProfileTitle(
                                        ar,
                                        currentPermission,
                                        isAcademy,
                                      ),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  if (widget.isPopup)
                                    Positioned(
                                      left: ar ? 0 : null,
                                      right: ar ? null : 0,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white70,
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  const Positioned(
                                    right: 0,
                                    child: LogoButton(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // FUT Card
                            Center(
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: isOwnProfile && !_isUploading
                                        ? () => _updateAvatar(
                                            context,
                                            userId,
                                            avatarUrl,
                                          )
                                        : null,
                                    child: MouseRegion(
                                      cursor: isOwnProfile
                                          ? SystemMouseCursors.click
                                          : SystemMouseCursors.basic,
                                      child: FutCardResponsive(
                                        child: FutCardFull(
                                          playerId: userId,
                                          playerName: name,
                                          position: position,
                                          rating: level,
                                          countryIcon:
                                              isValidUrl(countryFlagUrl)
                                              ? bust(countryFlagUrl)
                                              : 'https://flagcdn.com/w320/jo.png',
                                          avatarUrl:
                                              _optimisticAvatarUrl ??
                                              (isValidUrl(avatarUrl)
                                                  ? bust(avatarUrl)
                                                  : ''),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isUploading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  if (isOwnProfile && !_isUploading)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: CircleAvatar(
                                        backgroundColor:
                                            theme.colorScheme.primary,
                                        radius: 15,
                                        child: const Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Soft container for profile details (keeps FUT Card untouched)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Level progress
                                  _buildLevelProgress(context, ar, theme, xp),

                                  const SizedBox(height: 18),

                                  // Live Player Stats Strip
                                  PlayerMatchStatsStrip(
                                    playerId: userId,
                                    isGk: isGk,
                                    goals: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statGoals,
                                        )
                                        .toInt(),
                                    assists: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statAssists,
                                        )
                                        .toInt(),
                                    yellowCards: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statYellowCards,
                                        )
                                        .toInt(),
                                    redCards: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statRedCards,
                                        )
                                        .toInt(),
                                    motm: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statMotm,
                                        )
                                        .toInt(),
                                    matches: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statMatches,
                                        )
                                        .toInt(),
                                    saves: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statSaves,
                                        )
                                        .toInt(),
                                    cleanSheets: statsStore
                                        .getStat(
                                          userId,
                                          PlayerStatsStore.statCleanSheet,
                                        )
                                        .toInt(),
                                  ),

                                  const SizedBox(height: 22),

                                  // Coach evaluation removed
                                  // Permission-specific action buttons
                                  _buildPermissionBasedActions(
                                    context,
                                    ar,
                                    theme,
                                    widget
                                        .userPermission, // Viewer's permission
                                    isOwnProfile,
                                    userId,
                                    name,
                                  ),

                                  const SizedBox(height: 18),

                                  // Social icons
                                  _buildSocialIcons(context, theme),

                                  const SizedBox(height: 16),

                                  // Log out button
                                  if (isOwnProfile)
                                    _buildLogoutButton(context, ar, theme),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ✨ Level Up Celebration Overlay
                      if (_isPlayingCelebration)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isPlayingCelebration = false),
                            child: Container(
                              color: Colors.black.withOpacity(0.8),
                              child: _LevelUpCelebrationOverlay(
                                oldLevel: _prevLevel,
                                newLevel: _currLevel,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildGkMetric(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.grey.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getProfileTitle(bool ar, UserPermission permission, bool isAcademy) {
    switch (permission) {
      case UserPermission.admin:
        return ar ? 'ملف المشرف' : 'ADMIN PROFILE';
      case UserPermission.organizer:
        return ar ? 'ملف المنظم' : 'ORGANIZER PROFILE';
      case UserPermission.coach:
        return ar ? 'ملف المدرب' : 'COACH PROFILE';
      case UserPermission.academy:
        return ar ? 'ملف لاعب الأكاديمية' : 'ACADEMY PLAYER PROFILE';
      default:
        if (isAcademy) {
          return ar ? 'ملف لاعب الأكاديمية' : 'ACADEMY PLAYER PROFILE';
        }
        return ar ? 'ملف اللاعب' : 'PLAYER PROFILE';
    }
  }

  Widget _buildLevelProgress(
    BuildContext context,
    bool ar,
    ThemeData theme,
    double xp,
  ) {
    final levelProgress = ((xp % 100) / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          ar ? 'تقدم المستوى' : 'LEVEL PROGRESS',
          style: TextStyle(
            color:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.grey.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 300),
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FractionallySizedBox(
              widthFactor: levelProgress,
              alignment: Alignment.centerLeft,
              child: Container(color: theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(levelProgress * 100).toStringAsFixed(0)}% ${ar ? 'مكتمل' : 'Complete'}',
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color ?? Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcons(BuildContext context, ThemeData theme) {
    // Social links provided by user
    final instagram = Uri.parse(
      'https://www.instagram.com/letsplay_jo?igsh=Z295YjM2NTFqOXdu',
    );
    final facebook = Uri.parse(
      'https://www.facebook.com/share/1BzzEhVUK2/?mibextid=wwXIfr',
    );
    final whatsapp = Uri.parse(
      'https://chat.whatsapp.com/FLrxj81ciwj2AQxcLfpEwz?mode=hqctcli',
    );

    Future<void> open(Uri uri) async {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open link')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error opening link')));
      }
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        IconButton(
          icon: Icon(
            FontAwesomeIcons.whatsapp,
            color:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.grey.withOpacity(0.7),
          ),
          onPressed: () => open(whatsapp),
          tooltip: 'WhatsApp',
        ),
        IconButton(
          icon: Icon(
            FontAwesomeIcons.instagram,
            color:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.grey.withOpacity(0.7),
          ),
          onPressed: () => open(instagram),
          tooltip: 'Instagram',
        ),
        IconButton(
          icon: Icon(
            FontAwesomeIcons.facebook,
            color:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.grey.withOpacity(0.7),
          ),
          onPressed: () => open(facebook),
          tooltip: 'Facebook',
        ),
      ],
    );
  }

  Widget _buildPermissionBasedActions(
    BuildContext context,
    bool ar,
    ThemeData theme,
    UserPermission viewerPermission,
    bool isOwnProfile,
    String userId,
    String name,
  ) {
    // If viewing someone else's profile (from User Management or Match list)
    if (!isOwnProfile) {
      if (viewerPermission == UserPermission.admin ||
          viewerPermission == UserPermission.coach ||
          viewerPermission == UserPermission.organizer) {
        return _buildStaffViewingPlayerActions(
          context,
          ar,
          theme,
          viewerPermission,
          userId,
          name,
        );
      }
      return const SizedBox.shrink(); // Players viewing players - restricted view
    }

    // If viewing own profile
    switch (viewerPermission) {
      case UserPermission.admin:
        return _buildAdminActions(
          context,
          ar,
          theme,
          currentPermission: viewerPermission,
          userId: userId,
          name: name,
        );
      case UserPermission.organizer:
        return _buildOrganizerActions(
          context,
          ar,
          theme,
          currentPermission: viewerPermission,
          userId: userId,
          name: name,
        );
      case UserPermission.coach:
        return _buildCoachActions(
          context,
          ar,
          theme,
          currentPermission: viewerPermission,
          userId: userId,
          name: name,
        );
      case UserPermission.academy:
        return _buildPlayerActions(
          context,
          ar,
          theme,
          currentPermission: viewerPermission,
          userId: userId,
          name: name,
        );
      default:
        return _buildPlayerActions(
          context,
          ar,
          theme,
          currentPermission: viewerPermission,
          userId: userId,
          name: name,
        );
    }
  }

  /// Specific actions available when Staff (Admin/Coach) views a player's profile.
  Widget _buildStaffViewingPlayerActions(
    BuildContext context,
    bool ar,
    ThemeData theme,
    UserPermission viewerPermission,
    String userId,
    String name,
  ) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تقييم الأداء' : 'Performance Rating',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: userId,
                  playerName: name,
                  userPermission: viewerPermission,
                  showOnlyCurrentUser: false,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAdminActions(
    BuildContext context,
    bool ar,
    ThemeData theme, {
    required UserPermission currentPermission,
    required String userId,
    required String name,
  }) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/profileDetails');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/settings');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'اللاعبين' : 'Players',
          Icons.group,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/players');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'عرض أدائي' : 'View My Performance',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            final currentUser = FirebaseAuth.instance.currentUser;
            final currentAuthUserId = currentUser?.uid ?? '';
            final currentAuthUserName =
                currentUser?.displayName ?? (ar ? 'أدائي' : 'My Performance');

            // This button is for the logged-in user to view their own performance
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: userId,
                  playerName: name,
                  userPermission: currentPermission,
                  showOnlyCurrentUser: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'تقييم الأداء' : 'Performance Rating',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            // This button is for staff to rate the viewed player
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: widget.player.id,
                  playerName: widget.player.name,
                  userPermission: currentPermission,
                  showOnlyCurrentUser: false,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'التنظيم' : 'Organization',
          Icons.business,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/organization');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإدارة' : 'Management',
          Icons.dashboard,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/management');
          },
        ),
      ],
    );
  }

  Widget _buildOrganizerActions(
    BuildContext context,
    bool ar,
    ThemeData theme, {
    required UserPermission currentPermission,
    required String userId,
    required String name,
  }) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/profileDetails');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/settings');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'عرض أدائي' : 'View My Performance',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            final currentUser = FirebaseAuth.instance.currentUser;
            final currentAuthUserId = currentUser?.uid ?? '';
            final currentAuthUserName =
                currentUser?.displayName ?? (ar ? 'أدائي' : 'My Performance');

            // This button is for the logged-in user to view their own performance
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: userId,
                  playerName: name,
                  userPermission: currentPermission,
                  showOnlyCurrentUser: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'المنظمة' : 'Organization',
          Icons.business,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/organization');
          },
        ),
      ],
    );
  }

  Widget _buildCoachActions(
    BuildContext context,
    bool ar,
    ThemeData theme, {
    required UserPermission currentPermission,
    required String userId,
    required String name,
  }) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/profileDetails');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/settings');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'اللاعبين' : 'Players',
          Icons.group,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/players');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'عرض أدائي' : 'View My Performance',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: userId,
                  playerName: name,
                  userPermission: currentPermission,
                  showOnlyCurrentUser: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'تقييم الأداء' : 'Performance Rating',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: widget.player.id,
                  playerName: widget.player.name,
                  userPermission: currentPermission,
                  showOnlyCurrentUser: false,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayerActions(
    BuildContext context,
    bool ar,
    ThemeData theme, {
    required UserPermission currentPermission,
    required String userId,
    required String name,
  }) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/profileDetails');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            Navigator.pushNamed(context, '/settings');
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'عرض أدائي' : 'View My Performance',
          Icons.bar_chart,
          () {
            if (!GuestService.handleGuestInteraction(context, ar)) return;
            // For a player, userId and name are already their own details
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PerformanceRatingPage(
                  ctrl: widget.ctrl,
                  playerId: userId,
                  playerName: name,
                  userPermission: currentPermission,
                  showOnlyCurrentUser: true, // Show only their own performance
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLimitedProfile(
    BuildContext context,
    bool ar,
    ThemeData theme,
    String userId,
  ) {
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            key: PageStorageKey('profile_scroll_$userId'),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                // Header with LogoButton
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          ar ? 'الملف الشخصي' : 'PROFILE',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Positioned(right: 0, child: LogoButton()),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Guest user message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ar ? 'تسجيل الدخول مطلوب' : 'Login Required',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ar
                            ? 'يرجى تسجيل الدخول للوصول إلى ملفات اللاعبين والمميزات الكاملة'
                            : 'Please login to access player profiles and full features',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        icon: const Icon(Icons.login),
                        label: Text(ar ? 'تسجيل الدخول' : 'Login'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ✨ EA FC Style Level Up Celebration Overlay
class _LevelUpCelebrationOverlay extends StatefulWidget {
  final int oldLevel;
  final int newLevel;

  const _LevelUpCelebrationOverlay({
    required this.oldLevel,
    required this.newLevel,
  });

  @override
  State<_LevelUpCelebrationOverlay> createState() =>
      __LevelUpCelebrationOverlayState();
}

class __LevelUpCelebrationOverlayState extends State<_LevelUpCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.elasticOut),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
    ]).animate(_controller);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.2)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL UP!',
                style: GoogleFonts.saira(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD700),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 4,
                  shadows: [
                    const Shadow(color: Colors.black, blurRadius: 10),
                    Shadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E27),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFFFD700), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LV. ${widget.oldLevel}',
                      style: GoogleFonts.saira(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                    ),
                    Text(
                      'LV. ${widget.newLevel}',
                      style: GoogleFonts.saira(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'TAP TO CONTINUE',
                style: GoogleFonts.saira(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
