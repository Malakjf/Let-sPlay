# 🏆 FIFA-Style FUT Card System - Complete Implementation Guide

## 📋 Overview

Professional FIFA Ultimate Team card system for PlayFootball.me with:
- **Coach-driven dynamic attributes** (PAC, SHO, PAS, DRI, DEF, PHY)
- **Real-time animations** (goal celebration, attribute updates, card flip)
- **Clean architecture** with Provider state management
- **Match stats outside card** (Goals, Assists, MOTM, Matches)

---

## 🎨 Card Content Rules

### ✅ INSIDE THE CARD (Only These)
- Player Rating
- Player Position
- Country Flag
- Player Avatar
- Player Name
- **Performance Metrics Grid (2×3)**:
  ```
  PAC  SHO  PAS
  DRI  DEF  PHY
  ```

### ❌ NEVER INSIDE THE CARD
- Goals
- Assists
- MOTM
- Matches
- Red/Yellow Cards

### 🟦 Match Stats (Always Outside)
Display below the card:
```
⚽  69   GOALS
🅰️  66   ASSISTS
🏆   2   MOTM
📅  41   MATCHES
```

---

## 🎯 Architecture

### State Management (Provider)

```dart
// main.dart
runApp(
  MultiProvider(
    providers: [
      // Attributes Store (coach-driven)
      ChangeNotifierProvider(
        create: (_) => PlayerAttributesStore(),
      ),
      
      // Stats Store (match-driven)
      ChangeNotifierProvider(
        create: (_) => PlayerStatsStore(),
      ),
    ],
    child: const LetsPlayApp(),
  ),
);
```

### Data Flow

```
Coach Evaluation → PlayerAttributesStore → FUT Card UI
                         ↓
                   Firestore (persistence)

Match Events → PlayerStatsStore → Match Stats Display
                    ↓
              Firestore (persistence)
```

---

## 🚀 Quick Start

### 1. Basic FUT Card

```dart
import 'package:letsplay/widgets/FutCardFull.dart';

FutCardFull(
  playerId: 'player123',
  playerName: 'Mohamed Salah',
  position: 'RW',
  rating: 89,
  countryIcon: 'https://flagcdn.com/w320/eg.png',
  avatarUrl: 'https://example.com/salah.jpg',
)
```

**Key Point**: Card automatically reads attributes from `PlayerAttributesStore`. No need to pass PAC/SHO/PAS manually!

### 2. Add Match Stats (Outside Card)

```dart
import 'package:letsplay/widgets/match_stats_display.dart';

Column(
  children: [
    FutCardFull(/* ... */),
    MatchStatsDisplay(playerId: 'player123'),
  ],
)
```

### 3. Complete Player Card with Stats

```dart
import 'package:letsplay/widgets/match_stats_display.dart';

PlayerCardWithStats(
  playerId: 'player123',
  futCard: FutCardFull(/* ... */),
  showStats: true,
)
```

---

## ✨ Animations

### 🥅 Goal Animation

Triggered when first goal is scored:

```dart
import 'package:letsplay/widgets/animations/goal_micro_animation.dart';

void _onGoalScored() {
  final statsStore = context.read<PlayerStatsStore>();
  final currentGoals = statsStore.getStat(playerId, PlayerStatsStore.statGoals);

  // Show animation on FIRST goal only
  if (currentGoals == 0) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (context) => const GoalAnimationOverlay(),
    );

    Future.delayed(const Duration(milliseconds: 650), () {
      Navigator.of(context).pop();
    });
  }

  // Increment stat
  statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statGoals);
}
```

**Features**:
- Football ⚽ enters net
- Smooth fade out
- Duration: ~600ms
- Net visual effect

### 📈 Attribute Update Animation

Automatically triggers when coach updates ratings:

```dart
// Attributes animate automatically via AnimatedAttributeGrid
// No manual trigger needed!

// To update attributes (coach evaluation):
final store = context.read<PlayerAttributesStore>();
store.updateFromCoachEvaluation(
  playerId: 'player123',
  position: 'RW',
  coachRatings: {
    'pace': 88,
    'shooting': 92,
    'passing': 90,
    'dribbling': 94,
    'defending': 40,
    'physical': 70,
  },
);
```

**Features**:
- Number scales (1.0 → 1.15 → 1.0)
- Soft glow highlight
- Color-coded by value:
  - `90+` → Elite Gold Glow
  - `80-89` → Gold
  - `70-79` → Silver
  - `60-69` → Bronze
  - `<60` → Gray

### 🔄 Card Flip Animation

Optional: Tap to flip and see enlarged metrics:

```dart
import 'package:letsplay/widgets/animations/card_flip_animation.dart';

FlippableCard(
  frontSide: FutCardFull(/* ... */),
  backSide: EnlargedMetricsBack(
    pace: 88,
    shooting: 92,
    passing: 90,
    dribbling: 94,
    defending: 40,
    physical: 70,
    playerName: 'MOHAMED SALAH',
  ),
)
```

**Features**:
- Y-axis rotation
- Curve: `easeOutExpo`
- Duration: 600ms
- Tap to flip back

### 🚀 Splash Screen Animation

Add to app launch:

```dart
import 'package:letsplay/widgets/animations/splash_animation.dart';

FootballSplashAnimation(
  appName: 'PlayFootball.me',
  onComplete: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  },
)
```

**Features**:
- Football enters net
- Logo fades in
- Total duration: ~1.2s
- Plays once only

---

## 🧠 Coach Evaluation System

### How It Works

1. **Coach provides ratings** (0-100) for each skill area
2. **PlayerAttributesStore calculates** FIFA-style attributes
3. **FUT card updates** automatically via Provider
4. **Changes persist** to Firestore

### Example: Update Player Attributes

```dart
final store = context.read<PlayerAttributesStore>();

store.updateFromCoachEvaluation(
  playerId: 'player123',
  position: 'ST', // Position affects baseline values
  coachRatings: {
    'pace': 85,
    'shooting': 92,
    'passing': 78,
    'dribbling': 86,
    'defending': 35,
    'physical': 80,
  },
  physicalCondition: 95,    // Optional: 0-100
  recentPerformance: 88,    // Optional: 0-100
  matchesPlayed: 15,        // Optional
);
```

### Position-Based Baselines

Different positions have different base attribute profiles:

| Position | PAC | SHO | PAS | DRI | DEF | PHY |
|----------|-----|-----|-----|-----|-----|-----|
| **GK**   | 40  | 20  | 40  | 30  | 25  | 70  |
| **CB**   | 55  | 35  | 50  | 45  | 75  | 75  |
| **LB/RB**| 70  | 40  | 60  | 65  | 70  | 70  |
| **CDM**  | 60  | 50  | 70  | 65  | 75  | 75  |
| **CM**   | 65  | 60  | 75  | 70  | 65  | 70  |
| **CAM**  | 70  | 70  | 80  | 80  | 50  | 60  |
| **LW/RW**| 85  | 75  | 70  | 85  | 40  | 60  |
| **ST**   | 80  | 85  | 65  | 80  | 35  | 75  |

---

## 📊 Match Stats System

### Record Events

```dart
final statsStore = context.read<PlayerStatsStore>();

// Record goal
statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statGoals);

// Record assist
statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statAssists);

// Award MOTM
statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statMotm);

// Yellow card
statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statYellow);

// Red card
statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statRed);
```

### Get Stats

```dart
final statsStore = context.watch<PlayerStatsStore>();

final goals = statsStore.getStat(playerId, PlayerStatsStore.statGoals);
final assists = statsStore.getStat(playerId, PlayerStatsStore.statAssists);
final motm = statsStore.getStat(playerId, PlayerStatsStore.statMotm);
```

---

## 🎯 Complete Examples

See [`lib/examples/fut_system_examples.dart`](lib/examples/fut_system_examples.dart) for:

1. **SimpleFutCardExample** - Basic card with stats
2. **FlippableFutCardExample** - Card with flip animation
3. **GoalAnimationExample** - Goal celebration demo
4. **CompletePlayerProfile** - Full implementation

### Run Examples

```dart
// In your app
import 'package:letsplay/examples/fut_system_examples.dart';

// Navigate to example
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CompletePlayerProfile(
      playerId: 'player123',
      matchId: 'match456',
    ),
  ),
);
```

---

## 🎨 Customization

### Card Colors

```dart
FutCardFull(
  /* ... */
  ratingColor: const Color(0xFFFFD700),
  textColor: Colors.white,
  avatarBackgroundColor: const Color(0xFFB8956A),
  levelBackgroundColor: const Color(0xFF4A3728),
  levelBorderColor: const Color(0xFF8B6F47),
)
```

### Card Background Image

```dart
FutCardFull(
  /* ... */
  imagePath: 'assets/images/gold_card.png',  // Default
  // or 'assets/images/rare_card.png'
  // or 'assets/images/icon_card.png'
)
```

### Animation Durations

```dart
// Goal animation
GoalMicroAnimation(
  duration: const Duration(milliseconds: 800),  // Default: 600ms
)

// Card flip
FlippableCard(
  duration: const Duration(milliseconds: 800),  // Default: 600ms
)
```

---

## 🔥 Best Practices

### ✅ DO

- Use `PlayerAttributesStore` for all attribute data
- Display match stats **outside** the card
- Trigger goal animation on **first goal only**
- Let animations complete before user interaction
- Use `Consumer` widgets for real-time updates

### ❌ DON'T

- Pass attributes as widget parameters
- Put goals/assists inside the card
- Show goal animation for every goal
- Use `FutureBuilder` inside card widgets
- Fetch data directly from Firestore in widgets

---

## 📱 Integration with Existing Pages

### Players Screen

```dart
// lib/pages/players.dart
import 'package:letsplay/widgets/FutCardFull.dart';
import 'package:letsplay/widgets/match_stats_display.dart';

// In your player list/grid:
Column(
  children: [
    FutCardFull(
      playerId: player.id,
      playerName: player.name,
      position: player.position,
      rating: player.overallRating,
      countryIcon: player.countryFlag,
      avatarUrl: player.photoUrl,
    ),
    MatchStatsDisplay(playerId: player.id),
  ],
)
```

### Profile Page

```dart
// lib/pages/Profile.dart
import 'package:letsplay/widgets/animations/card_flip_animation.dart';

Consumer<PlayerAttributesStore>(
  builder: (context, store, child) {
    final attrs = store.getPlayerAttributes(currentUserId);
    
    return FlippableCard(
      frontSide: FutCardFull(/* ... */),
      backSide: EnlargedMetricsBack(
        pace: attrs?.pace ?? 50,
        shooting: attrs?.shooting ?? 50,
        // ...
      ),
    );
  },
)
```

### Match Details

```dart
// lib/pages/MatchDetails.dart
import 'package:letsplay/widgets/animations/goal_micro_animation.dart';

void _handleGoalScored(String playerId) {
  final statsStore = context.read<PlayerStatsStore>();
  final goals = statsStore.getStat(playerId, PlayerStatsStore.statGoals);
  
  if (goals == 0) {
    showDialog(
      context: context,
      builder: (_) => const GoalAnimationOverlay(),
    );
    
    Future.delayed(const Duration(milliseconds: 650), () {
      Navigator.pop(context);
    });
  }
  
  statsStore.incrementStat(matchId, playerId, PlayerStatsStore.statGoals);
}
```

---

## 🧪 Testing

### Test Attribute Updates

```dart
void testAttributeUpdate() {
  final store = PlayerAttributesStore();
  
  store.updateFromCoachEvaluation(
    playerId: 'test123',
    position: 'ST',
    coachRatings: {'pace': 90, 'shooting': 95, /* ... */},
  );
  
  final attrs = store.getPlayerAttributes('test123');
  expect(attrs?.pace, greaterThan(85));
  expect(attrs?.shooting, greaterThan(90));
}
```

### Test Stats Recording

```dart
void testStatsRecording() async {
  final store = PlayerStatsStore();
  await store.initializeForMatch('match123');
  
  store.incrementStat('match123', 'player123', PlayerStatsStore.statGoals);
  
  final goals = store.getStat('player123', PlayerStatsStore.statGoals);
  expect(goals, equals(1));
}
```

---

## 📚 Documentation References

- **[COACH_DRIVEN_FUT_SYSTEM.md](../COACH_DRIVEN_FUT_SYSTEM.md)** - Detailed architecture
- **[ARCHITECTURE.md](../ARCHITECTURE.md)** - Overall system design
- **[coach_evaluation_examples.dart](../lib/examples/coach_evaluation_examples.dart)** - 10 working examples

---

## 🎯 Summary

### What You've Built

✅ Professional FIFA-style FUT card  
✅ Coach-driven dynamic attributes  
✅ Real-time animations (goal, attributes, flip, splash)  
✅ Clean Provider architecture  
✅ Match stats display system  
✅ Complete examples and documentation  

### Next Steps

1. Integrate into existing screens (Players, Profile, Match Details)
2. Add more card styles (rare, icon, special editions)
3. Implement card collections UI
4. Add player comparison features
5. Create leaderboard based on ratings

---

## 🤝 Support

For questions or issues:
1. Check [examples](../lib/examples/fut_system_examples.dart)
2. Review [architecture docs](../COACH_DRIVEN_FUT_SYSTEM.md)
3. Run the complete example screens

**Built with ❤️ for PlayFootball.me**
