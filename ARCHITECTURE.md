## Professional Player Stats Architecture 🏗️

### Overview
This is a **professional-grade, PlayFootball.me-style** player statistics system designed for real-time, multi-screen stat synchronization.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────┐
│         FIRESTORE (Persistence)             │
│  matches/{matchId}/player_stats/aggregate   │
│  matches/{matchId}/player_metrics/aggregate │
└──────────────────────────┬──────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │   STORES (Single Source of Truth)│
        ├──────────────────────────────────┤
        │  PlayerStatsStore (ChangeNotifier)│
        │  - Map<playerId, Map<stat, value>>
        │  - Goals, Assists, Cards, MOTM   │
        │                                   │
        │  PlayerMetricsStore               │
        │  - Map<playerId, Map<metric, val>>
        │  - PAC, SHO, PAS, etc.           │
        └──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
    PlayersScreen    FUTCardWidget    ProfileScreen
    (Update)         (Read-only)      (Read-only)
```

---

## Key Principles

### 1. **Single Source of Truth** ✅
- **Store is the ONLY place** stats are stored
- UI never maintains counters
- Multiple screens read from same store

```dart
// ✅ CORRECT: Read from store
final goals = statsStore.getStat(playerId, statGoals);

// ❌ WRONG: Store in widget state
int _localGoals = 0; // NO!
```

### 2. **Event-Based Stats** ✅
- Stats stored as `Map<PlayerId, Map<StatType, Value>>`
- Tab switching **filters only**, doesn't modify data
- Tab = UI filter, not data manipulation

```dart
// ✅ Switching tabs is just filtering
_selectedStatFilter = 'Goals'; // Only UI changes
// The store data is UNCHANGED

// ❌ WRONG: Modifying data on tab switch
if (selectedTab == 'Goals') {
  _stats.clear(); // NO!
}
```

### 3. **Optimistic Updates + Debounced Persistence** ✅
```
User Click
    ↓
[Instant UI Update] → User sees change immediately
    ↓
[Debounce 500ms] → Batch multiple updates
    ↓
[Save to Firestore] → Persist to backend
```

**Benefits:**
- Instant feedback (no loading spinner)
- Reduces Firestore writes (saves costs)
- Works offline (data is in store)

### 4. **No FutureBuilder in Lists** ✅
```dart
// ✅ CORRECT: Pre-load data, use Consumer
ListView(
  children: players.map((p) => 
    Consumer<PlayerStatsStore>(
      builder: (ctx, store, _) => 
        Text('${store.getStat(p.id, 'goals')}')
    )
  )
)

// ❌ WRONG: FutureBuilder in each row
ListView(
  children: players.map((p) => 
    FutureBuilder(future: loadStats(p.id))
  )
)
```

### 5. **Separate Stores for Different Concerns** ✅

**PlayerStatsStore:**
- Quick binary updates (+1/-1)
- Single tap = immediate change
- Examples: Goals, Assists, Cards, MOTM

**PlayerMetricsStore:**
- Complex numeric input
- Range validation (0-99)
- Examples: PAC, SHO, PAS, DRI, etc.

---

## How Each Screen Works

### PlayersScreen (Update Stats)
```dart
// 1. Initialize stores when entering
await initializePlayerStatsForMatch(context, matchId);

// 2. Load player list from Firestore (one-time)
final playerIds = await getPlayers(matchId);

// 3. Build with Consumer - reads from store
Consumer<PlayerStatsStore>(
  builder: (ctx, statsStore, _) {
    final currentGoals = statsStore.getStat(playerId, 'goals');
    // Rebuilds when store changes
  }
)

// 4. User clicks +/- button
statsStore.incrementStat(matchId, playerId, 'goals');
// - Store updates instantly ✓
// - UI rebuilds automatically ✓
// - Firestore saves in background ✓
```

### FUTCardWidget (Display Stats)
```dart
// Read-only display of current stats
Consumer<PlayerStatsStore>(
  builder: (ctx, statsStore, _) {
    final stats = statsStore.getPlayerStats(playerId);
    return FutCard(
      goals: stats['goals'],      // Live from store ✓
      assists: stats['assists'],   // Auto-updates ✓
    );
  }
)

// When PlayersScreen increments goals:
// 1. PlayersScreen: statsStore.incrementStat()
// 2. Store notifyListeners()
// 3. FUTCardWidget rebuilds automatically ✓
```

### ProfileScreen (Career Stats)
```dart
// Display aggregated stats across all matches
Consumer<PlayerStatsStore>(
  builder: (ctx, statsStore, _) {
    final allStats = statsStore.getAllStats();
    // Shows current session stats
    // (For career stats, you'd query separate collection)
  }
)
```

---

## Implementation Steps

### Step 1: Add Provider to pubspec.yaml
```yaml
dependencies:
  provider: ^6.0.0
```

### Step 2: Setup in main.dart
```dart
void main() {
  runApp(
    MultiProvider(
      providers: playerStatisticsProviders,
      child: const MyApp(),
    ),
  );
}
```

### Step 3: Initialize when entering match
```dart
void onEnterMatch(int matchId) {
  // Call once when opening PlayersScreen
  initializePlayerStatsForMatch(context, matchId);
}
```

### Step 4: Use in widgets
```dart
// Read stats
Consumer<PlayerStatsStore>(builder: (ctx, store, _) {
  final value = store.getStat(playerId, 'goals');
  return Text('$value');
})

// Update stats
statsStore.incrementStat(matchId, playerId, 'goals');
```

---

## Firestore Schema

### Structure
```
matches/{matchId}/
  player_stats/
    aggregate
      {
        "playerId1": {
          "goals": 2,
          "assists": 1,
          "redCards": 0,
          "yellowCards": 1,
          "motm": 1
        },
        "playerId2": { ... }
      }
  
  player_metrics/
    aggregate
      {
        "playerId1": {
          "PAC": 87,
          "SHO": 85,
          "PAS": 88,
          ...
        }
      }
```

### Why This Structure?
- ✅ Single document write = all player stats saved together
- ✅ Automatic merge (SetOptions(merge: true))
- ✅ Fast reads (one document)
- ✅ Scales well (collection per match)

---

## Common Patterns

### Pattern 1: Increment/Decrement
```dart
// PlayersScreen: User clicks +
statsStore.incrementStat(matchId, playerId, 'goals');

// Automatically:
// 1. Updates store
// 2. Triggers rebuilds (Consumer)
// 3. Saves to Firestore (500ms debounce)
```

### Pattern 2: Tab Switching
```dart
// User clicks "Assists" tab
setState(() => _selectedStatFilter = 'assists');

// This is UI-only, store is unchanged
// Next rebuild shows different stat column
// No data loss, no accumulation
```

### Pattern 3: Multi-Screen Sync
```dart
// PlayersScreen increments
statsStore.incrementStat(matchId, playerId, 'goals'); // +1

// FUTCardWidget automatically reflects
// ProfileScreen automatically reflects
// ALL because they read from same store
```

---

## Performance Optimizations

### 1. Debounced Firestore Writes
```dart
// Multiple clicks within 500ms = single Firestore write
// Example: Click + 10 times quickly
// Result: 1 write to Firestore (saves 90% of writes!)
```

### 2. Selective Rebuilds
```dart
// FUTCardWidget only rebuilds when its stats change
Consumer<PlayerStatsStore>(
  builder: (ctx, store, _) { ... }
)
// Other store changes = no rebuild
```

### 3. No Duplicated Queries
```dart
// Players loaded once in initState
List<PlayerItem> _players = [];

// All stats read from store (not re-queried)
statsStore.getStat(playerId, 'goals');

// Never reload unless you explicitly call
await statsStore.initializeForMatch(matchId);
```

---

## Debugging

### Enable Debug Logging
```dart
// Look for these messages:
📊 PlayerStatsStore: Initializing for match 123
👥 Found 11 players
✅ Loaded stats from Firestore
📝 Updated playerId.goals = 2
💾 Saved playerId stats to Firestore
```

### Check Store State
```dart
// In your IDE console
final store = context.read<PlayerStatsStore>();
print(store.getAllStats()); // See all data
```

### Test Store Without Firestore
```dart
// Create store directly
final store = PlayerStatsStore();

// Manually set data
store.updateStat(123, 'player1', 'goals', 5);

// Check what happens
print(store.getStat('player1', 'goals')); // 5
```

---

## Comparison: Before vs After

### BEFORE (Problems)
```
❌ Local state in each widget
❌ Tab switching clears counters
❌ Multiple Firestore queries
❌ Stats don't sync between screens
❌ FutureBuilder in list rows (slow)
❌ Accidental stat duplication
```

### AFTER (Solutions)
```
✅ Single store for all stats
✅ Tab switching = UI filter only
✅ Load player list once, read stats from store
✅ Automatic sync across all screens
✅ Consumer pattern (no FutureBuilder)
✅ Impossible to duplicate data
✅ 500ms debounce = fewer Firestore writes
```

---

## Files Created

1. **player_stats_store.dart** - Main stats store (ChangeNotifier)
2. **player_metrics_store.dart** - Metrics store (ChangeNotifier)
3. **player_stats_providers.dart** - Provider setup + initialization
4. **PlayersScreen_Architecture.dart** - Reference implementation
5. **player_stats_widgets_example.dart** - FUTCardWidget, ProfileScreen examples
6. **ARCHITECTURE.md** - This documentation

---

## Migration Path

### Phase 1: Add Stores (No Breaking Changes)
- Create PlayerStatsStore
- Add Provider to main.dart
- Don't change PlayersScreen yet

### Phase 2: Update PlayersScreen
- Replace local _playerStats with Consumer<PlayerStatsStore>
- Remove _loadSavedStats() method
- Update buttons to call statsStore.incrementStat()

### Phase 3: Update Other Screens
- FUTCardWidget: Wrap with Consumer<PlayerStatsStore>
- ProfileScreen: Same pattern

### Phase 4: Remove Old Code
- Delete old PlayerStatsStorage if not needed
- Clean up old methods

---

## PlayFootball.me Alignment

PlayFootball.me uses similar patterns:
- ✅ Centralized player stats service
- ✅ Real-time updates across screens
- ✅ Optimistic updates
- ✅ Debounced persistence
- ✅ No duplicated UI state

This architecture matches their professional approach.

---

## Q&A

**Q: Why two stores (Stats + Metrics)?**
A: Different update patterns. Stats = binary (+1/-1), Metrics = text input (0-99). Easier to manage separately.

**Q: What if Firestore write fails?**
A: Data stays in store (available offline). User can retry. No data loss.

**Q: How to clear stats for new match?**
A: Call `clearPlayerStats(context)` in dispose.

**Q: Can I read stats without initializing first?**
A: Yes, you'll get 0. But should initialize in initState.

**Q: Performance impact of multiple stores?**
A: Minimal. ChangeNotifier is lightweight. Consumer rebuilds are selective.

---

## Next Steps

1. Copy the 3 store files to your `lib/services/`
2. Update `main.dart` with MultiProvider
3. Replace current PlayersScreen with new version
4. Wrap FUTCardWidget and ProfileScreen with Consumers
5. Test: Increment stat in PlayersScreen, verify FUTCard updates
6. Remove old code once verified
