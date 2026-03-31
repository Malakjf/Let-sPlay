# Organization Page Architecture - PlayFootball.me Style

## 📁 Folder Structure

```
lib/pages/
  Organization.dart (main screen)
  organization/
    models/
      match_player.dart         # Player model with stats & wallet
      players_view_mode.dart    # Enum: roster, payments
    widgets/
      players_header.dart       # Header showing Players count
      players_tabs.dart         # Roster/Payments tabs
      player_tile.dart          # Reusable player item (mode-aware)
      payment_bottom_sheet.dart # Payment method selection
      player_details_dialog.dart # Player stats & wallet details
```

## 🏗️ Architecture Principles (PlayFootball.me Style)

### 1. **Single Data Load**
- Players are loaded **once** when a match is expanded
- Data is cached in `_matchPlayersCache[matchId]`
- NO FutureBuilder in list items
- Tabs don't trigger new queries

### 2. **Mode-Based UI**
```dart
enum PlayersViewMode { roster, payments }
```
- Same players, different actions
- `PlayerTile` adapts based on mode
- Roster: Shows role badges, navigates to details
- Payments: Shows wallet balance, charge button

### 3. **Separation of Concerns**
- **Models**: Data structures (MatchPlayer)
- **Widgets**: Reusable UI components
- **Logic**: In main page (payment processing, data loading)

### 4. **Clean Data Flow**
```
Match Expanded → Load All Players Once → Cache
                      ↓
          Tab Switch (roster ↔ payments)
                      ↓
          Same Data, Different UI Actions
```

## 🎯 Key Components

### MatchPlayer Model
```dart
class MatchPlayer {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isPaid;
  final num walletCredit;
  final String role; // 'player', 'coach', 'organizer', 'admin'
  
  bool get isStaff => role == 'coach' || role == 'organizer' || role == 'admin';
}
```

### PlayerTile (Mode-Aware)
- **Roster Mode**: 
  - Shows role badge for staff
  - Shows chevron icon
  - onTap → Player details
  
- **Payments Mode**:
  - Shows wallet balance
  - Shows "Charge" button
  - onAction → Payment bottom sheet

### Payment Flow
1. User taps "Charge" button
2. Opens `PaymentBottomSheet`
3. Shows match fee and name
4. 4 payment methods:
   - Wallet (primary)
   - Cash-to-Wallet
   - Cash
   - Online
5. Processes payment
6. Refreshes cache
7. Updates UI

## 🎨 Why This Matches PlayFootball.me

### ✅ Efficient Data Loading
- No duplicate network requests
- Players loaded once per match
- Cached for instant tab switching

### ✅ Clean Tab Behavior
- Tabs are UI-only switches
- No data fetching in tabs
- Instant response

### ✅ Contextual Actions
- Same player, different context
- Roster: View details, manage roles
- Payments: Charge, track payments

### ✅ Reusable Components
- `PlayerTile` works in any mode
- `PaymentBottomSheet` is standalone
- Easy to test and maintain

### ✅ Scalable Architecture
- Add new modes without touching player loading
- Add new payment methods in one place
- Easy to extend with more features

## 🚀 Performance Benefits

1. **Single Query**: One Firestore read per match (not per tab)
2. **No FutureBuilder Overhead**: List items render immediately
3. **Cached Data**: Instant navigation between tabs
4. **Optimized Re-renders**: Only mode state changes

## 📝 Usage Example

```dart
// In Organization.dart
_matchPlayersCache[matchId] = allPlayers; // Load once

// Switch tabs (no data fetch)
setState(() {
  _viewMode = PlayersViewMode.payments;
});

// PlayerTile adapts automatically
PlayerTile(
  player: player,
  mode: _viewMode, // roster or payments
  onTap: _viewMode == PlayersViewMode.roster 
    ? () => _showDetails(player)
    : null,
  onAction: _viewMode == PlayersViewMode.payments
    ? () => _showPayment(player)
    : null,
)
```

## 🔄 Data Flow Diagram

```
User Opens Match
       ↓
Load Players Once (coaches + organizers + players)
       ↓
Cache in _matchPlayersCache[matchId]
       ↓
   ┌─────────────────────────┐
   │   Players Header (X/Y)  │
   └─────────────────────────┘
   ┌─────────────────────────┐
   │  [Roster]  [Payments]   │ ← UI-only tabs
   └─────────────────────────┘
   ┌─────────────────────────┐
   │   PlayerTile (mode)     │ ← Same data, different UI
   │   PlayerTile (mode)     │
   │   PlayerTile (mode)     │
   └─────────────────────────┘
```

## 🎓 Key Takeaways

This architecture follows **PlayFootball.me's philosophy**:
- Load data once
- Use modes to change behavior
- Keep UI responsive
- Separate concerns
- Cache intelligently
- Avoid redundant queries

Perfect for building scalable, performant Flutter apps! ⚡
