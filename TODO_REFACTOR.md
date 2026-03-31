# Refactoring Plan: Fix Apple Guideline 2.1 Rejection - COMPLETED

## Summary of Changes Made:

### 1. Fields.dart
- ✅ Added `FirebaseAuth` import
- ✅ Updated `_loadFields()` to catch permission-denied errors gracefully
- ✅ Shows empty state instead of error for guest users
- ✅ Added `GuestService.handleGuestInteraction()` to field card tap

### 2. Profile.dart
- ✅ Added `FirebaseAuth` and `GuestService` imports
- ✅ Added StreamBuilder error handling for permission-denied errors
- ✅ Added helper methods: `_buildLoadingState`, `_buildErrorState`, `_buildEmptyState`, `_buildLimitedProfile`
- ✅ Added `GuestService.handleGuestInteraction()` to all action buttons

### 3. MatchesPageEnhanced.dart
- ✅ Added `GuestService` import
- ✅ Updated `_loadMatches()` to catch permission-denied errors gracefully
- ✅ Added `GuestService.handleGuestInteraction()` to match card tap
- ✅ Added `GuestService.handleGuestInteraction()` to join button

### 4. StorePageEnhanced.dart
- ✅ Added `GuestService` import
- ✅ Updated `_loadProducts()` to catch permission-denied errors gracefully
- ✅ Added `GuestService.handleGuestInteraction()` to product card tap
- ✅ Added `GuestService.handleGuestInteraction()` to product list tile tap

## Behavior:
- Guests can VIEW all screens (fields, matches, store, profile)
- Guests see empty state if Firestore query fails (instead of infinite loading)
- When guests try to INTERACT (tap, button), they are redirected to /login
- Authenticated users have full functionality

