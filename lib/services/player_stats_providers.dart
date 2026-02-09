import 'package:provider/provider.dart';
import 'player_stats_store.dart';
import 'player_metrics_store.dart';
import 'player_attributes_store.dart';

/// Provider setup for player statistics architecture
///
/// Usage in main.dart:
/// ```
/// MultiProvider(
///   providers: [
///     ...playerStatisticsProviders,
///   ],
///   child: MyApp(),
/// )
/// ```
final List<ChangeNotifierProvider> playerStatisticsProviders = [
  ChangeNotifierProvider(create: (_) => PlayerStatsStore()),
  ChangeNotifierProvider(create: (_) => PlayerMetricsStore()),
  ChangeNotifierProvider(
    create: (_) => PlayerAttributesStore(),
  ), // 🎯 Coach-driven attributes
];

/// Initialize stores for a specific match
/// Call this when entering PlayersScreen
Future<void> initializePlayerStatsForMatch(
  dynamic context,
  String matchId,
) async {
  final statsStore = context.read<PlayerStatsStore>();
  final metricsStore = context.read<PlayerMetricsStore>();

  await Future.wait<void>([
    statsStore.initializeForMatch(matchId),
    metricsStore.initializeForMatch(matchId),
  ]);
}

/// Clear all stats and metrics
/// Call this when leaving match management
void clearPlayerStats(dynamic context) {
  context.read<PlayerStatsStore>().clearAll();
  context.read<PlayerMetricsStore>().clearAll();
}
