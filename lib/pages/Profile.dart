import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:letsplay/utils/permissions.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_permission.dart' show UserPermission;
import '../services/language.dart';
import '../models/player.dart';
import '../widgets/FutCardFull.dart';
import '../widgets/FutCardResponsive.dart';
import '../widgets/AnimatedButton.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import '../services/firebase_service.dart';
import '../widgets/LogoButton.dart' show LogoButton;
import '../widgets/PlayerMatchStatsStrip.dart';
import 'package:letsplay/services/player_stats_store.dart';
import 'package:letsplay/services/player_metrics_store.dart';

class ProfileScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Player player;
  final UserPermission userPermission;

  const ProfileScreen({
    super.key,
    required this.ctrl,
    required this.player,
    this.userPermission = UserPermission.coach,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

    // ✅ Subscription Safety: Subscribe once per session/entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Provider.of<PlayerAttributesStore>(
        context,
        listen: false,
      ).subscribeToPlayer(userId);

      Provider.of<PlayerMetricsStore>(
        context,
        listen: false,
      ).subscribeToUser(userId);

      Provider.of<PlayerStatsStore>(
        context,
        listen: false,
      ).loadCareerStats(userId);
    });
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
            final data = snapshot.hasData ? snapshot.data!.data() : null;

            final name =
                data?['name'] ?? data?['username'] ?? widget.player.name;
            final position = data?['position'] ?? widget.player.position;
            final avatarUrl = data?['avatarUrl'] ?? widget.player.imageUrl;
            final countryFlagUrl =
                data?['countryFlagUrl'] ?? widget.player.countryFlagUrl;
            final role = data?['role'] ?? 'Player';
            final permissionLevel = data?['permissionLevel'] as String?;
            final currentPermission = permissionFromRole(
              permissionLevel ?? role,
            );
            final isGk = (position.toUpperCase() == 'GK');
            final level = data?['level'] ?? widget.player.level;
            final double xp = (data?['xp'] as num?)?.toDouble() ?? 0.0;
            final isAcademy = data?['isAcademyPlayer'] == true;

            return Directionality(
              textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                body: SafeArea(
                  child: SingleChildScrollView(
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

                        // FUT Card
                        FutCardResponsive(
                          child: FutCardFull(
                            playerId: userId,
                            playerName: name,
                            position: position,
                            rating: level,
                            countryIcon: countryFlagUrl.isNotEmpty
                                ? countryFlagUrl
                                : 'https://flagcdn.com/w320/jo.png',
                            avatarUrl: avatarUrl,
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
                              ),

                              const SizedBox(height: 22),

                              // Permission-specific action buttons
                              _buildPermissionBasedActions(
                                context,
                                ar,
                                theme,
                                currentPermission,
                              ),

                              const SizedBox(height: 18),

                              // Social icons
                              _buildSocialIcons(theme),

                              const SizedBox(height: 16),

                              // Log out button
                              _buildLogoutButton(context, ar, theme),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildSocialIcons(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: [
        Icon(
          FontAwesomeIcons.instagram,
          color:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
              Colors.grey.withOpacity(0.7),
        ),
        Icon(
          FontAwesomeIcons.facebook,
          color:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
              Colors.grey.withOpacity(0.7),
        ),
        Icon(
          FontAwesomeIcons.twitter,
          color:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
              Colors.grey.withOpacity(0.7),
        ),
        Icon(
          FontAwesomeIcons.whatsapp,
          color:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
              Colors.grey.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildPermissionBasedActions(
    BuildContext context,
    bool ar,
    ThemeData theme,
    UserPermission permission,
  ) {
    switch (permission) {
      case UserPermission.admin:
        return _buildAdminActions(context, ar, theme);
      case UserPermission.organizer:
        return _buildOrganizerActions(context, ar, theme);
      case UserPermission.coach:
        return _buildCoachActions(context, ar, theme);
      case UserPermission.academy:
        return _buildPlayerActions(context, ar, theme);
      default:
        return _buildPlayerActions(context, ar, theme);
    }
  }

  Widget _buildAdminActions(BuildContext context, bool ar, ThemeData theme) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () => Navigator.pushNamed(context, '/profileDetails'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () => Navigator.pushNamed(context, '/settings'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'اللاعبين' : 'Players',
          Icons.group,
          () => Navigator.pushNamed(context, '/players'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'التنظيم' : 'Organization',
          Icons.business,
          () => Navigator.pushNamed(context, '/organization'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإدارة' : 'Management',
          Icons.dashboard,
          () => Navigator.pushNamed(context, '/management'),
        ),
      ],
    );
  }

  Widget _buildOrganizerActions(
    BuildContext context,
    bool ar,
    ThemeData theme,
  ) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () => Navigator.pushNamed(context, '/profileDetails'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () => Navigator.pushNamed(context, '/settings'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'المنظمة' : 'Organization',
          Icons.business,
          () => Navigator.pushNamed(context, '/organization'),
        ),
      ],
    );
  }

  Widget _buildCoachActions(BuildContext context, bool ar, ThemeData theme) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () => Navigator.pushNamed(context, '/profileDetails'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () => Navigator.pushNamed(context, '/settings'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'اللاعبين' : 'Players',
          Icons.group,
          () => Navigator.pushNamed(context, '/players'),
        ),
      ],
    );
  }

  Widget _buildPlayerActions(BuildContext context, bool ar, ThemeData theme) {
    return Column(
      children: [
        _buildActionButton(
          context,
          ar ? 'تفاصيل الملف' : 'Profile Details',
          Icons.person,
          () => Navigator.pushNamed(context, '/profileDetails'),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          ar ? 'الإعدادات' : 'Settings',
          Icons.settings,
          () => Navigator.pushNamed(context, '/settings'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
            const SizedBox(width: 16),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool ar, ThemeData theme) {
    return Center(
      child: AnimatedButton(
        onPressed: () async {
          try {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(ar ? 'تسجيل الخروج' : 'Logout'),
                content: Text(
                  ar
                      ? 'هل أنت متأكد من تسجيل الخروج؟'
                      : 'Are you sure you want to logout?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(ar ? 'إلغاء' : 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(ar ? 'تسجيل الخروج' : 'Logout'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await FirebaseService.instance.signOut();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/splash', (route) => false);
              }
            }
          } catch (e) {
            debugPrint('❌ Logout error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ar ? 'فشل تسجيل الخروج' : 'Logout failed'),
                ),
              );
            }
          }
        },
        text: ar ? 'تسجيل الخروج' : 'Logout',
        icon: Icons.logout,
      ),
    );
  }
}
