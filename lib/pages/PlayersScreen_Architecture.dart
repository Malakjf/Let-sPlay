import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language.dart';
import '../services/player_stats_store.dart';
import '../services/player_metrics_store.dart';
import '../services/player_stats_providers.dart';
import '../services/firebase_service.dart';
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
  final String? matchId;
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
  String _selectedStatFilter = PlayerStatsStore.statGoals;
  String _selectedMetric = PlayerMetricsStore.metricPAC;
  String _selectedTeamFilter = 'All Teams';
  bool _isLoading = true;

  // Players loaded from Firestore (UI list only)
  List<PlayerItem> _players = [];

  // Only confirmed player userIds

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  Future<void> _initializePlayers() async {
    if (widget.matchId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Initialize both stores with match data
      await initializePlayerStatsForMatch(context, widget.matchId!);

      // Get confirmed player userIds from FirebaseService
      final confirmedIds = await FirebaseService.instance.getConfirmedPlayers(
        widget.matchId!,
      );
      final players = <PlayerItem>[];

      for (final playerId in confirmedIds) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(playerId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            players.add(
              PlayerItem(
                id: playerId,
                name: userData['name'] ?? userData['username'] ?? 'Unknown',
                age: userData['age'] ?? 25,
                number: userData['number'] ?? 0,
                photoUrl: userData['profilePicUrl'],
                teamColor: Colors.blue,
                team: 0,
                position: userData['position'] ?? 'Forward',
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Error loading player $playerId: $e');
        }
      }

      if (mounted) {
        setState(() {
          _players = players;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing players: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, child) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);

        // Filter players based on team selection
        final filteredPlayers = _selectedTeamFilter == 'All Teams'
            ? _players
            : _selectedTeamFilter == 'Team 0'
            ? _players.where((p) => p.team == 0).toList()
            : _players.where((p) => p.team == 1).toList();

        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text(
                '${widget.title} (${filteredPlayers.length})',
                style: theme.textTheme.titleMedium,
              ),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Stat filter tabs
                  SizedBox(
                    height: 84,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: PlayerStatsStore.allStatTypes.map((stat) {
                        final isSelected = _selectedStatFilter == stat;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedStatFilter = stat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.appBarTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    stat,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Team filter and metric dropdown
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedTeamFilter,
                          isExpanded: true,
                          items: ['All Teams', 'Team 0', 'Team 1']
                              .map(
                                (team) => DropdownMenuItem(
                                  value: team,
                                  child: Text(team),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTeamFilter = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedMetric,
                          isExpanded: true,
                          items: PlayerMetricsStore.allMetricTypes
                              .map(
                                (metric) => DropdownMenuItem(
                                  value: metric,
                                  child: Text(metric),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMetric = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Players list
                  Expanded(
                    child: filteredPlayers.isEmpty
                        ? Center(
                            child: Text(
                              ar ? 'لا يوجد لاعبون' : 'No players',
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredPlayers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final player = filteredPlayers[index];
                              return _PlayerRowWidget(
                                matchId: widget.matchId!,
                                player: player,
                                selectedStat: _selectedStatFilter,
                                selectedMetric: _selectedMetric,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual player row with live stat updates
/// This widget reads from PlayerStatsStore and PlayerMetricsStore
class _PlayerRowWidget extends StatefulWidget {
  final String matchId;
  final PlayerItem player;
  final String selectedStat;
  final String selectedMetric;

  const _PlayerRowWidget({
    required this.matchId,
    required this.player,
    required this.selectedStat,
    required this.selectedMetric,
  });

  @override
  State<_PlayerRowWidget> createState() => _PlayerRowWidgetState();
}

class _PlayerRowWidgetState extends State<_PlayerRowWidget> {
  late TextEditingController _metricController;

  @override
  void initState() {
    super.initState();
    _metricController = TextEditingController();
    _updateMetricController();
  }

  @override
  void didUpdateWidget(_PlayerRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMetric != widget.selectedMetric) {
      _updateMetricController();
    }
  }

  void _updateMetricController() {
    final metricsStore = context.read<PlayerMetricsStore>();
    final currentMetric = metricsStore.getMetric(
      widget.player.id,
      widget.selectedMetric,
    );
    _metricController.text = '$currentMetric';
  }

  @override
  void dispose() {
    _metricController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileBg = theme.appBarTheme.backgroundColor ?? const Color(0xFF1E2432);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Player info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player.name,
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Age: ${widget.player.age}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Stat controls - reads from PlayerStatsStore
          Consumer<PlayerStatsStore>(
            builder: (context, statsStore, _) {
              final currentValue = statsStore.getStat(
                widget.player.id,
                widget.selectedStat,
              );

              return Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // Minus button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        debugPrint(
                          '📊 Decrement: ${widget.player.id} $widget.selectedStat',
                        );
                        statsStore.decrementStat(
                          widget.matchId,
                          widget.player.id,
                          widget.selectedStat,
                        );
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Value display
                    Container(
                      width: 36,
                      height: 28,
                      decoration: BoxDecoration(
                        color: tileBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$currentValue',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Plus button
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        debugPrint(
                          '📊 Increment: ${widget.player.id} $widget.selectedStat',
                        );
                        statsStore.incrementStat(
                          widget.matchId,
                          widget.player.id,
                          widget.selectedStat,
                        );
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tileBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(width: 8),

          // Metric input - reads from PlayerMetricsStore
          Consumer<PlayerMetricsStore>(
            builder: (context, metricsStore, _) {
              return Expanded(
                flex: 1,
                child: TextField(
                  controller: _metricController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
              );
            },
          ),
        ],
      ),
    );
  }
}
