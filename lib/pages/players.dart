import 'package:flutter/material.dart';
import 'package:letsplay/widgets/App_Bottom_Nav.dart';
import 'package:letsplay/widgets/LogoButton.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/language.dart';
import 'package:letsplay/services/player_stats_store.dart';
import 'package:letsplay/services/player_metrics_store.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlayerItem {
  final String id;
  final String name;
  final int age;
  final int number;
  final String? photoUrl;
  final Color teamColor;
  final int team;
  final String position;

  const PlayerItem({
    required this.id,
    required this.name,
    required this.age,
    required this.number,
    this.photoUrl,
    required this.teamColor,
    required this.team,
    required this.position,
  });

  String get avatarInitials {
    return name
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }
}

class PlayersScreen extends StatefulWidget {
  final LocaleController ctrl;
  final String? matchId; // ✅ Made nullable for safety
  final String title;

  const PlayersScreen({
    super.key,
    required this.ctrl,
    this.matchId,
    this.title = 'Players',
  });

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  // UI state ONLY - not data state
  String _selectedFilter = PlayerStatsStore.statGoals;
  int _activeFilterIndex = 0;
  String _selectedTeamFilter = 'All Teams';
  String _selectedMetric = PlayerMetricsStore.metricPAC;

  // Logic state
  Stream<List<PlayerItem>>? _playersStream;
  String? _resolvedMatchId;

  final List<Map<String, dynamic>> _filterOptions = [
    {'icon': Icons.sports_soccer, 'label': PlayerStatsStore.statGoals},
    {'icon': Icons.swap_vert, 'label': PlayerStatsStore.statAssists},
    {'color': Colors.red, 'label': PlayerStatsStore.statRed},
    {'color': Colors.yellow, 'label': PlayerStatsStore.statYellow},
    {'icon': Icons.emoji_events, 'label': PlayerStatsStore.statMotm},
  ];

  final List<Map<String, dynamic>> _teamSortingOptions = [
    {'value': 'All Teams', 'label': 'All Teams', 'icon': Icons.groups},
    {'value': 'Team 0', 'label': 'Team 0', 'color': Colors.blue},
    {'value': 'Team 1', 'label': 'Team 1', 'color': Colors.red},
    {'value': 'Sort by Team', 'label': 'Sort by Team', 'icon': Icons.sort},
  ];

  @override
  void initState() {
    super.initState();
    // Logic moved to didChangeDependencies to safely access ModalRoute
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Always resolve matchId and rehydrate stores on every mount
    String? matchId;
    if (widget.matchId != null) {
      matchId = widget.matchId;
    } else {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        matchId = args;
      }
    }
    if (matchId != null) {
      if (_resolvedMatchId != matchId) {
        _resolvedMatchId = matchId;
        _playersStream = _createPlayersStream(_resolvedMatchId!);
      }
      // Always rehydrate stores for this match
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _resolvedMatchId != null) {
          _initializeStores(_resolvedMatchId!);
        }
      });
    }
  }

  // ✅ Helper for date parsing (requested)

  Future<void> _initializeStores(String matchId) async {
    try {
      final statsStore = context.read<PlayerStatsStore>();
      final metricsStore = context.read<PlayerMetricsStore>();
      final attributesStore = context.read<PlayerAttributesStore>();
      await Future.wait([
        statsStore.initializeForMatch(matchId),
        metricsStore.initializeForMatch(matchId),
        attributesStore.loadMultiplePlayerAttributes(statsStore.getPlayerIds()),
      ]);
    } catch (e) {
      debugPrint('❌ Error initializing stores: $e');
    }
  }

  // ✅ Real-time stream creation
  Stream<List<PlayerItem>> _createPlayersStream(String matchId) {
    return FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .snapshots()
        .asyncMap((matchDoc) async {
          if (!matchDoc.exists) return [];
          final data = matchDoc.data();
          if (data == null) return [];

          // ✅ Merge and deduplicate players
          final List<dynamic> playersList = data['players'] is List
              ? data['players']
              : [];
          final List<dynamic> joinedList = data['joinedPlayers'] is List
              ? data['joinedPlayers']
              : [];

          final Set<String> allIds = {};
          allIds.addAll(playersList.map((e) => e.toString()));
          allIds.addAll(joinedList.map((e) => e.toString()));

          final Map<String, dynamic> teams = data['teams'] is Map
              ? data['teams']
              : {};

          if (allIds.isEmpty) return [];

          // ✅ Fetch user details
          final List<PlayerItem> items = [];
          // Fetch in parallel for performance
          final userDocs = await Future.wait(
            allIds.map(
              (id) =>
                  FirebaseFirestore.instance.collection('users').doc(id).get(),
            ),
          );

          for (final userDoc in userDocs) {
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final int teamIdx = teams[userDoc.id] is int
                  ? teams[userDoc.id]
                  : 0;

              items.add(
                PlayerItem(
                  id: userDoc.id,
                  name: userData['name'] ?? userData['username'] ?? 'Unknown',
                  age: userData['age'] ?? 25,
                  number: userData['number'] ?? 0,
                  photoUrl: userData['avatarUrl'] ?? userData['profilePicUrl'],
                  teamColor: teamIdx == 1 ? Colors.red : Colors.blue,
                  team: teamIdx,
                  position: userData['position'] ?? 'Forward',
                ),
              );
            }
          }
          return items;
        });
  }

  void _onFilterChanged(int index, String filterLabel) {
    setState(() {
      _activeFilterIndex = index;
      _selectedFilter = filterLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Handle missing matchId
    if (_resolvedMatchId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No Match ID provided')),
      );
    }

    // ✅ StreamBuilder for real-time updates
    return StreamBuilder<List<PlayerItem>>(
      stream: _playersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final players = snapshot.data ?? [];

        return ListenableBuilder(
          listenable: widget.ctrl,
          builder: (context, child) {
            final ar = widget.ctrl.isArabic;

            // Apply team filtering and sorting
            List<PlayerItem> filteredPlayers = List.from(players);

            if (_selectedTeamFilter != 'All Teams') {
              if (_selectedTeamFilter == 'Team 0') {
                filteredPlayers = filteredPlayers
                    .where((p) => p.team == 0)
                    .toList();
              } else if (_selectedTeamFilter == 'Team 1') {
                filteredPlayers = filteredPlayers
                    .where((p) => p.team == 1)
                    .toList();
              }
            }

            if (_selectedTeamFilter == 'Sort by Team') {
              filteredPlayers.sort((a, b) {
                if (a.team != b.team) {
                  return a.team.compareTo(b.team);
                }
                return a.number.compareTo(b.number);
              });
            }

            final displayPlayers = filteredPlayers;
            final theme = Theme.of(context);
            final panelBg =
                theme.appBarTheme.backgroundColor ??
                theme.scaffoldBackgroundColor;
            final tileBg = theme.cardColor;
            final mutedText =
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                Colors.grey;

            return Directionality(
              textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: theme.scaffoldBackgroundColor,
                appBar: AppBar(
                  backgroundColor: panelBg,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    ar
                        ? '${widget.title} (${displayPlayers.length})'
                        : '${widget.title} (${displayPlayers.length})',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: const [LogoButton()],
                ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Filters / stat selectors (horizontal)
                      SizedBox(
                        height: 84,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filterOptions.length,
                          itemBuilder: (context, index) {
                            final filter = _filterOptions[index];
                            final isSelected = _activeFilterIndex == index;
                            return Row(
                              children: [
                                if (index == 0) const SizedBox(width: 6),
                                _buildFilterItem(
                                  icon: filter['icon'] as IconData?,
                                  color: filter['color'] as Color?,
                                  label: filter['label'] as String,
                                  isSelected: isSelected,
                                  onTap: () {
                                    _onFilterChanged(
                                      index,
                                      filter['label'] as String,
                                    );
                                  },
                                ),
                                if (index < _filterOptions.length - 1)
                                  const SizedBox(width: 12)
                                else
                                  const SizedBox(width: 6),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Team Filter and Metric Dropdown
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: tileBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  setState(() {
                                    _selectedTeamFilter = value;
                                  });
                                },
                                itemBuilder: (context) {
                                  return _teamSortingOptions.map((option) {
                                    return PopupMenuItem<String>(
                                      value: option['value'] as String,
                                      child: Row(
                                        children: [
                                          if (option['icon'] != null) ...[
                                            Icon(
                                              option['icon'] as IconData,
                                              size: 16,
                                              color: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                            ),
                                            const SizedBox(width: 8),
                                          ] else if (option['color'] !=
                                              null) ...[
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: option['color'] as Color,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Text(
                                            option['label'] as String,
                                            style: TextStyle(
                                              color: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.filter_list,
                                            size: 16,
                                            color: theme
                                                .textTheme
                                                .bodyMedium
                                                ?.color,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedTeamFilter,
                                            style: TextStyle(
                                              color: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: tileBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  setState(() {
                                    _selectedMetric = value;
                                  });
                                },
                                itemBuilder: (context) {
                                  return PlayerMetricsStore.allMetricTypes.map((
                                    metric,
                                  ) {
                                    return PopupMenuItem<String>(
                                      value: metric,
                                      child: Text(
                                        metric,
                                        style: TextStyle(
                                          color:
                                              theme.textTheme.bodyMedium?.color,
                                          fontSize: 14,
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _selectedMetric,
                                        style: TextStyle(
                                          color:
                                              theme.textTheme.bodyMedium?.color,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Header labels row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: panelBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                ar ? 'الاسم' : 'Name',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  ar ? 'الرقم' : 'No.',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  ar ? 'اللون' : 'Color',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text(
                                  _selectedFilter,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  _selectedMetric,
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Players list
                      Expanded(
                        child: displayPlayers.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: mutedText,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      ar
                                          ? 'لا توجد بيانات للاعبين'
                                          : 'No players data',
                                      style: TextStyle(
                                        color: mutedText,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: displayPlayers.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final player = displayPlayers[index];
                                  return _PlayerRow(
                                    player: player,
                                    matchId: _resolvedMatchId!,
                                    selectedFilter: _selectedFilter,
                                    selectedMetric: _selectedMetric,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: const AppBottomNav(index: 0),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterItem({
    IconData? icon,
    Color? color,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : (Theme.of(context).textTheme.titleMedium?.color ??
                          Theme.of(context).textTheme.bodyMedium?.color),
                size: 22,
              ),
            ] else if (color != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : (Theme.of(context).textTheme.titleMedium?.color ??
                          Theme.of(context).textTheme.bodyMedium?.color),
                fontSize: 12,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ✅ Using Consumer pattern for reactivity
class _PlayerRow extends StatefulWidget {
  final PlayerItem player;
  final String matchId;
  final String selectedFilter;
  final String selectedMetric;

  const _PlayerRow({
    required this.player,
    required this.matchId,
    required this.selectedFilter,
    required this.selectedMetric,
  });

  @override
  State<_PlayerRow> createState() => _PlayerRowState();
}

class _PlayerRowState extends State<_PlayerRow> {
  late TextEditingController _metricController;

  @override
  void initState() {
    super.initState();
    _metricController = TextEditingController();
  }

  @override
  void dispose() {
    _metricController.dispose();
    super.dispose();
  }

  void _updateGkAttributes(BuildContext context, PlayerStatsStore statsStore) {
    if (widget.player.position != 'GK') return;

    final metricsStore = context.read<PlayerMetricsStore>();
    final stats = statsStore.getPlayerStats(widget.player.id);

    metricsStore.updateGkRatingsFromStats(
      userId: widget.player.id,
      saves: (stats[PlayerStatsStore.statSaves] ?? 0).toInt(),
      goalsReceived: (stats[PlayerStatsStore.statGoalsReceived] ?? 0).toInt(),
      cleanSheet: (stats[PlayerStatsStore.statCleanSheet] ?? 0).toInt(),
      passing: (stats[PlayerStatsStore.statPassing] ?? 0).toInt(),
    );
  }

  void _showTeamSelectionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Choose Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTeamOption(0, 'Team', Colors.blue),
            const SizedBox(height: 8),
            _buildTeamOption(1, 'Team', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOption(int teamIndex, String label, Color color) {
    return InkWell(
      onTap: () {
        _updateTeam(teamIndex);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 8),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            if (widget.player.team == teamIndex) ...[
              const Spacer(),
              Icon(Icons.check, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateTeam(int newTeam) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(widget.matchId)
        .set({
          'teams': {widget.player.id: newTeam},
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileBg = theme.cardColor;
    final mutedText = theme.textTheme.bodyMedium?.color ?? Colors.white70;

    // ✅ Consumer2 for both stores - updates automatically!
    return Consumer2<PlayerStatsStore, PlayerMetricsStore>(
      builder: (context, statsStore, metricsStore, _) {
        // Read from store (not local state!)
        final currentStat = statsStore.getStat(
          widget.player.id,
          widget.selectedFilter,
        );

        final currentMetric = metricsStore.getMetric(
          widget.player.id,
          widget.selectedMetric,
        );

        // Update controller when metric or player changes
        if (_metricController.text != currentMetric.toString()) {
          _metricController.text = currentMetric.toString();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Name + avatar
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: widget.player.teamColor,
                      backgroundImage:
                          (widget.player.photoUrl != null &&
                              widget.player.photoUrl!.isNotEmpty &&
                              (widget.player.photoUrl!.startsWith('http') ||
                                  widget.player.photoUrl!.startsWith('https')))
                          ? NetworkImage(
                              widget.player.photoUrl!.contains('?')
                                  ? '${widget.player.photoUrl}&t=${DateTime.now().millisecondsSinceEpoch}'
                                  : '${widget.player.photoUrl}?t=${DateTime.now().millisecondsSinceEpoch}',
                            )
                          : null,
                      child:
                          (widget.player.photoUrl == null ||
                              widget.player.photoUrl!.isEmpty ||
                              !widget.player.photoUrl!.startsWith('http'))
                          ? Text(
                              widget.player.avatarInitials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.player.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age: ${widget.player.age} | ${widget.player.position}',
                            style: TextStyle(color: mutedText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Number
              Expanded(
                flex: 1,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 36,
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.player.number}',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Color box
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: _showTeamSelectionDialog,
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: widget.player.teamColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.player.team}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Stats display with + and - buttons
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Minus button - calls store method
                    GestureDetector(
                      onTap: () {
                        statsStore.decrementStat(
                          widget.matchId,
                          widget.player.id,
                          widget.selectedFilter,
                        );
                        _updateGkAttributes(context, statsStore);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Current count from store
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$currentStat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                widget.selectedFilter ==
                                    PlayerStatsStore.statGoalsReceived
                                ? Colors.red
                                : (widget.selectedFilter ==
                                      PlayerStatsStore.statCleanSheet)
                                ? Colors.green
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Plus button - calls store method
                    GestureDetector(
                      onTap: () {
                        statsStore.incrementStat(
                          widget.matchId,
                          widget.player.id,
                          widget.selectedFilter,
                        );
                        _updateGkAttributes(context, statsStore);
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              // Metric input - updates store
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 60),
                    height: 36,
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _metricController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: mutedText, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (value) {
                        final intValue = int.tryParse(value) ?? 0;
                        metricsStore.updateMetric(
                          widget.matchId,
                          widget.player.id,
                          widget.selectedMetric,
                          intValue,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
