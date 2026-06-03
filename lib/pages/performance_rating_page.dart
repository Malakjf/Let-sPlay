import 'package:flutter/material.dart';
import 'package:letsplay/services/language.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:letsplay/models/player.dart';
import 'package:provider/provider.dart';
import 'package:letsplay/services/player_stats_store.dart';
import 'package:letsplay/services/player_metrics_store.dart';
import 'package:letsplay/widgets/FutCardFull.dart';
import 'package:letsplay/services/firebase_service.dart';
import '../models/user_permission.dart'
    show UserPermission; // Import UserPermission

/// A placeholder page to display performance ratings for a player.
class PerformanceRatingPage extends StatefulWidget {
  final LocaleController ctrl;
  final String playerId;
  final String playerName;

  final UserPermission userPermission; // Add userPermission
  final bool showOnlyCurrentUser; // NEW PARAMETER

  const PerformanceRatingPage({
    super.key,
    required this.ctrl,
    required this.playerId,
    required this.playerName,
    this.userPermission = UserPermission.player,
    required this.showOnlyCurrentUser, // Default to player
  });

  @override
  State<PerformanceRatingPage> createState() => _PerformanceRatingPageState();
}

class _PerformanceRatingPageState extends State<PerformanceRatingPage> {
  bool _showAcademyOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Declare isStaff here, at the beginning of the build method
  bool get _isStaff =>
      !widget.showOnlyCurrentUser &&
      (widget.userPermission == UserPermission.admin ||
          widget.userPermission == UserPermission.coach);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initRole();
  }

  Future<void> _initRole() async {
    try {
      await FirebaseService.instance.getCurrentUserRole();
      if (mounted) {}
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          title: Text(
            ar ? 'تقييم الأداء' : 'Performance Rating',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Column(
          children: [
            if (_isStaff)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        hintText: ar
                            ? 'بحث عن لاعب...'
                            : 'Search for a player...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintStyle: TextStyle(
                          color: theme.hintColor.withOpacity(0.5),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                    const SizedBox(height: 12),
                    // Only show filters if the user is an admin
                    if (_isStaff) // Use the declared _isStaff here
                      Row(
                        // This Row is conditionally included in the Column's children
                        children: [
                          ChoiceChip(
                            label: Text(ar ? 'الكل' : 'All Players'),
                            selected: !_showAcademyOnly,
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: !_showAcademyOnly
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _showAcademyOnly = false);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(ar ? 'الأكاديمية' : 'Academy Only'),
                            selected: _showAcademyOnly,
                            selectedColor: theme.colorScheme.primary,
                            labelStyle: TextStyle(
                              color: _showAcademyOnly
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() => _showAcademyOnly = true);
                              }
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(ar ? 'حدث خطأ' : 'Error occurred'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(ar ? 'لا يوجد لاعبون' : 'No players found.'),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    // If showOnlyCurrentUser is true, always filter by widget.playerId
                    if (widget.showOnlyCurrentUser) {
                      return doc.id == widget.playerId;
                    }

                    // Only show players if admin, or if it's the current player
                    if (!_isStaff && doc.id != widget.playerId) {
                      return false; // Non-admin can only see their own
                    }
                    final data = doc.data() as Map<String, dynamic>;
                    if (_showAcademyOnly && data['isAcademyPlayer'] != true) {
                      return false;
                    }
                    if (_searchQuery.isNotEmpty) {
                      final name = (data['name'] ?? data['username'] ?? '')
                          .toString()
                          .toLowerCase();
                      final pos = (data['position'] ?? '')
                          .toString()
                          .toLowerCase();
                      if (!name.contains(_searchQuery) &&
                          !pos.contains(_searchQuery)) {
                        return false;
                      }
                    }
                    return true;
                  }).toList();

                  final users = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Player(
                      id: doc.id,
                      name: data['name'] ?? data['username'] ?? 'Unknown',
                      position: data['position'] ?? 'N/A',
                      level: FirebaseService.safeInt(data['level'], 1),
                      rating: FirebaseService.safeInt(data['rating']),
                      imageUrl: data['avatarUrl'] ?? '',
                      countryFlagUrl: data['countryFlagUrl'] ?? '',
                      goals: FirebaseService.safeInt(data['goals']),
                      assists: FirebaseService.safeInt(data['assists']),
                      motm: FirebaseService.safeInt(data['motm']),
                      matches: FirebaseService.safeInt(data['matches']),
                      yellowCards: FirebaseService.safeInt(data['yellowCards']),
                      redCards: FirebaseService.safeInt(data['redCards']),
                      nationality: data['nationality'] ?? '',
                      club: data['club'] ?? '',
                      metrics: _getMetrics(data),
                      badges: (data['badges'] is List)
                          ? List<String>.from(data['badges'])
                          : [],
                      notes: data['notes'] ?? '',
                    );
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: users.length,
                    itemBuilder: (context, index) =>
                        _buildPlayerCard(context, users[index], theme),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, int> _getMetrics(Map<String, dynamic> data) {
    if (data['metrics'] is Map) {
      final m = Map<String, dynamic>.from(data['metrics']);
      return m.map((k, v) => MapEntry(k, FirebaseService.safeInt(v)));
    }
    return {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0};
  }

  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  String _getBustedUrl(String url) {
    if (!_isValidImageUrl(url)) return url;
    // نستخدم الساعة والدقيقة كحد أدنى لضمان التحديث الفوري عند الرفع
    return '$url${url.contains('?') ? '&' : '?'}v=${DateTime.now().hour}${DateTime.now().minute}';
  }

  Widget _buildPlayerCard(BuildContext context, Player user, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => _showRatingPopup(
          context,
          user,
          widget.userPermission,
        ), // Pass userPermission
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: _isValidImageUrl(user.imageUrl)
                      ? NetworkImage(_getBustedUrl(user.imageUrl))
                      : null,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: user.imageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user.position,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.level.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRatingPopup(
    BuildContext context,
    Player player,
    UserPermission currentUserPermission,
  ) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);
    final notesController = TextEditingController(text: player.notes);

    // Load role and player evaluations before showing dialog
    final dataFuture = Future.wait([
      FirebaseService.instance.getCurrentUserRole(),
      FirebaseService.instance.listEvaluationsForPlayer(player.id),
    ]);

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: dataFuture,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final role = (snap.data![0] as String).toLowerCase();
            // Force player-only role when viewing only the current user's performance
            final effectiveRole = widget.showOnlyCurrentUser ? 'player' : role;
            final evals = List<Map<String, dynamic>>.from(
              snap.data![1] as List,
            );
            // pick latest evaluation for this player
            Map<String, dynamic>? latest;
            if (evals.isNotEmpty) {
              evals.sort((a, b) {
                final ta = a['createdAt'];
                final tb = b['createdAt'];
                return (tb?.toString() ?? '').compareTo(ta?.toString() ?? '');
              });
              latest = evals.first;
            }

            return Directionality(
              textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  ar ? 'تقييم اللاعب' : 'Rate Player',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            player.name,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildStatSection(
                          context,
                          player,
                          ar,
                          theme,
                          effectiveRole,
                        ),
                        const Divider(height: 32),
                        _buildMetricsSection(
                          context,
                          player,
                          ar,
                          theme,
                          effectiveRole,
                        ),
                        const Divider(height: 32),
                        // Notes / Evaluation area: role-based
                        if (effectiveRole == 'coach')
                          _buildEditableEvaluationSection(
                            context,
                            player,
                            latest,
                            notesController,
                            ar,
                            theme,
                          )
                        else if (effectiveRole == 'admin')
                          _buildAdminEvaluationSection(
                            context,
                            player,
                            latest,
                            notesController,
                            ar,
                            theme,
                          )
                        else
                          _buildReadOnlyEvaluationSection(
                            context,
                            player,
                            latest,
                            notesController,
                            ar,
                            theme,
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      showPlayerProfilePopup(context, player);
                    },
                    child: Text(ar ? 'الملف الشخصي' : 'Profile View'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(ar ? 'إغلاق' : 'Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatSection(
    BuildContext context,
    Player player,
    bool ar,
    ThemeData theme,
    String role,
  ) {
    final bool canEdit = role == 'admin' || role == 'coach';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'إحصائيات المباراة' : 'Match Stats',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          context,
          player,
          PlayerStatsStore.statGoals,
          ar ? 'أهداف' : 'Goals',
          Icons.sports_soccer,
          canEdit: canEdit,
        ),

        _buildStatRow(
          context,
          player,
          PlayerStatsStore.statAssists,
          ar ? 'تمريرات' : 'Assists',
          Icons.compare_arrows,
          canEdit: canEdit,
        ),
        _buildStatRow(
          context,
          player,
          PlayerStatsStore.statMotm,
          ar ? 'رجل المباراة' : 'MOTM',
          Icons.emoji_events,
          canEdit: canEdit,
        ),
        _buildStatRow(
          context,
          player,
          PlayerStatsStore.statYellow,
          ar ? 'بطاقة صفراء' : 'Yellow Card',
          Icons.style,
          color: Colors.amber,
          canEdit: canEdit,
        ),
        _buildStatRow(
          context,
          player,
          PlayerStatsStore.statRed,
          ar ? 'بطاقة حمراء' : 'Red Card',
          Icons.style,
          color: Colors.red,
          canEdit: canEdit,
        ),
      ],
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    Player player,
    String statKey,
    String label,
    IconData icon, {
    Color? color,
    bool canEdit = true,
  }) {
    return Consumer<PlayerStatsStore>(
      builder: (context, store, _) {
        final theme = Theme.of(context);
        final value = store.getStat(player.id, statKey);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (color ?? theme.colorScheme.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color ?? theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: theme.colorScheme.error.withOpacity(0.7),
                  ),
                  onPressed: () => store.decrementStat(
                    'performance_eval',
                    player.id,
                    statKey,
                  ),
                ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => store.incrementStat(
                    'performance_eval',
                    player.id,
                    statKey,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsSection(
    BuildContext context,
    Player player,
    bool ar,
    ThemeData theme,
    String role,
  ) {
    final bool canEdit = role == 'admin' || role == 'coach';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'مقاييس الأداء' : 'Performance Metrics',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricSlider(
                context,
                player,
                'PAC',
                canEdit: canEdit,
                ar ? 'السرعة' : 'Pace',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricSlider(
                context,
                player,
                'SHO',
                canEdit: canEdit,
                ar ? 'التسديد' : 'Shooting',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildMetricSlider(
                context,
                player,
                'PAS',
                canEdit: canEdit,
                ar ? 'التمرير' : 'Passing',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricSlider(
                context,
                player,
                'DRI',
                canEdit: canEdit,
                ar ? 'المراوغة' : 'Dribbling',
              ),
            ),
          ],
        ),
        _buildMetricSlider(
          context,
          player,
          'DEF',
          ar ? 'الدفاع' : 'Defending',
          canEdit: canEdit,
        ),
        _buildMetricSlider(
          context,
          player,
          'PHY',
          ar ? 'القوة البدنية' : 'Physical',
          canEdit: canEdit,
        ),
      ],
    );
  }

  Widget _buildMetricSlider(
    BuildContext context,
    Player player,
    String metricKey,
    String label, {
    bool canEdit = true,
  }) {
    return Consumer<PlayerMetricsStore>(
      builder: (context, store, _) {
        final value = store.getMetric(player.id, metricKey).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: value.clamp(0.0, 100.0), // Ensure value is within range
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: canEdit
                  ? (val) {
                      store.updateMetric(
                        'performance_eval',
                        player.id,
                        metricKey,
                        val.toInt(),
                      );
                    }
                  : null, // Disable slider if canEdit is false
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadOnlyEvaluationSection(
    BuildContext context,
    Player player,
    Map<String, dynamic>? latest,
    TextEditingController notesController,
    bool ar,
    ThemeData theme,
  ) {
    notesController.text = latest?['details']?['notes']?.toString() ?? '';
    final status = latest?['status'] ?? 'Draft';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ar ? 'تقييم المدرب' : 'Coach Evaluation',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          readOnly: true,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableEvaluationSection(
    BuildContext context,
    Player player,
    Map<String, dynamic>? latest,
    TextEditingController notesController,
    bool ar,
    ThemeData theme,
  ) {
    final user = FirebaseService.instance.currentUser;
    final coachId = user?.uid ?? '';
    final existing = latest != null && latest['coachId'] == coachId
        ? latest
        : null;
    notesController.text =
        existing?['details']?['notes']?.toString() ?? notesController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ar ? 'ملاحظات التقييم' : 'Evaluation Notes',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // Save draft
                  final payload = {
                    'playerId': player.id,
                    'coachId': coachId,
                    'createdBy': coachId,
                    'details': {'notes': notesController.text.trim()},
                    'status': 'Draft',
                    'submittedByCoach': false,
                  };
                  try {
                    await FirebaseService.instance.saveEvaluation(payload);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft saved')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Text(ar ? 'حفظ كمسودة' : 'Save Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  // Send to admin
                  final payload = {
                    'playerId': player.id,
                    'coachId': coachId,
                    'createdBy': coachId,
                    'details': {'notes': notesController.text.trim()},
                    'status': 'Pending Admin Review',
                    'submittedByCoach': true,
                  };
                  try {
                    final id = await FirebaseService.instance.saveEvaluation(
                      payload,
                    );
                    await FirebaseService.instance.sendEvaluationToAdmin(id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sent to admin')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: Text(ar ? 'إرسال للمشرف' : 'Send to Admin'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminEvaluationSection(
    BuildContext context,
    Player player,
    Map<String, dynamic>? latest,
    TextEditingController notesController,
    bool ar,
    ThemeData theme,
  ) {
    final user = FirebaseService.instance.currentUser;
    final adminId = user?.uid ?? '';
    notesController.text =
        latest?['details']?['notes']?.toString() ?? notesController.text;
    final status = latest?['status'] ?? 'Draft';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ar ? 'قوائم المرسلة من المدربين' : 'Sent By Coach',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: notesController,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  // Approve & Send to Player
                  if (latest == null) {
                    // save as approved
                    final payload = {
                      'playerId': player.id,
                      'coachId': latest?['coachId'] ?? adminId,
                      'createdBy': latest?['createdBy'] ?? adminId,
                      'details': {'notes': notesController.text.trim()},
                      'status': 'Sent to Player',
                      'submittedByCoach': latest?['submittedByCoach'] ?? false,
                    };
                    try {
                      final id = await FirebaseService.instance.saveEvaluation(
                        payload,
                      );
                      await FirebaseService.instance.approveAndSendToPlayer(id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Approved & sent')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  } else {
                    try {
                      await FirebaseService.instance.approveAndSendToPlayer(
                        latest['id'],
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Approved & sent')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: Text(ar ? 'الموافقة وإرسال للاعب' : 'Approve & Send'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  // Reject
                  if (latest != null) {
                    try {
                      await FirebaseService.instance.rejectEvaluation(
                        latest['id'],
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Rejected')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                child: Text(ar ? 'رفض' : 'Reject'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void showPlayerProfilePopup(BuildContext context, Player player) {
    final ar = widget.ctrl.isArabic;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 350,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FUT Card display - read-only (view only permissions)
                    SizedBox(
                      width: 280,
                      height: 360,
                      child: FutCardFull(
                        playerId: player.id,
                        playerName: player.name,
                        position: player.position,
                        rating: player.rating,
                        countryIcon: _isValidImageUrl(player.countryFlagUrl)
                            ? _getBustedUrl(player.countryFlagUrl)
                            : 'https://flagcdn.com/w320/jo.png',
                        avatarUrl: _isValidImageUrl(player.imageUrl)
                            ? _getBustedUrl(player.imageUrl)
                            : '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildProfileStats(player, ar),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(ar ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildProfileStats(Player player, bool ar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'إحصائيات اللاعب' : 'Player Stats',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        buildProfileStatRow(ar ? 'المستوى' : 'Level', player.level.toString()),
        buildProfileStatRow(ar ? 'الأهداف' : 'Goals', player.goals.toString()),
        buildProfileStatRow(
          ar ? 'تمريرات حاسمة' : 'Assists',
          player.assists.toString(),
        ),
        buildProfileStatRow(
          ar ? 'رجل المباراة' : 'MOTM',
          player.motm.toString(),
        ),
        buildProfileStatRow(
          ar ? 'المباريات' : 'Matches',
          player.matches.toString(),
        ),
        buildProfileStatRow(
          ar ? 'النادي' : 'Club',
          player.club.isNotEmpty ? player.club : '-',
        ),
        buildProfileStatRow(
          ar ? 'الجنسية' : 'Nationality',
          player.nationality.isNotEmpty ? player.nationality : '-',
        ),
        buildProfileStatRow(ar ? 'المركز' : 'Position', player.position),
      ],
    );
  }

  Widget buildProfileStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
