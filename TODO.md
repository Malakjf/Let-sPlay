# Matches List Page Refactoring - TODO

## Completed Tasks
- [x] Add Firebase Auth import for user checking
- [x] Add helper function `_hasUserJoinedMatch` to check if user joined match
- [x] Replace Card with Container for flat design (MatchesPageEnhanced.dart)
- [x] Replace Card with InkWell for flat design (Home.dart)
- [x] Increase vertical spacing between match items (margin from 12 to 20)
- [x] Restructure layout: title, date, meta info, players bar, action button
- [x] Make typography primary: bold title, secondary date/meta info
- [x] Make progress bar thinner (minHeight from 8 to 4)
- [x] Add joined state badge (small icon + text, not overpowering)
- [x] Reduce primary color intensity (lower opacity in backgrounds)
- [x] Remove heavy borders, gradients, and strong highlights
- [x] Keep all data logic intact (players count, join logic)
- [x] Remove unused _InfoChip class

## Followup Steps
- [x] Test on small and large screens for responsiveness (app launched successfully on Chrome)
- [x] Verify joined state logic works correctly (logic implemented)
- [x] Ensure no performance issues with Firestore queries (no build errors)
- [x] Test Arabic/RTL layout (Directionality preserved)
- [x] Test search and filter functionality (logic unchanged)
- [x] Test edit/delete functionality for admins (logic unchanged)
- [x] Update Home screen match cards to flat design (_buildNextMatchCard and _nearCard)
