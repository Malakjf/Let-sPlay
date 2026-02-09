import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_stats_store.dart';

/// Debug widget to verify PlayerStatsStore provider is working
class ProviderDebugWidget extends StatelessWidget {
  const ProviderDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black87,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🔍 Provider Debug',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _ProviderCheck(),
        ],
      ),
    );
  }
}

class _ProviderCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    try {
      // Try to get the store
      final store = Provider.of<PlayerStatsStore>(context, listen: false);
      final playerIds = store.getPlayerIds();

      return Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Text(
                'PlayerStatsStore: ',
                style: TextStyle(color: Colors.white),
              ),
              Text('Found ✓', style: TextStyle(color: Colors.green.shade300)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Players in store: ${playerIds.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    } catch (e) {
      return Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PlayerStatsStore: NOT FOUND ✗',
              style: TextStyle(color: Colors.red.shade300),
            ),
          ),
        ],
      );
    }
  }
}
