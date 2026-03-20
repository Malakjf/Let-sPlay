# Responsive Refactoring TODO

## Task
Refactor Flutter screens to be fully responsive across all device sizes (small phones, large phones like Pro Max, and tablets).

## Completed Files

### 1. lib/pages/Home.dart ✅
- [x] Add SafeArea wrapper
- [x] Replace hardcoded padding with responsive MediaQuery-based padding
- [x] Make calendar widget dynamically sized
- [x] Replace const SizedBox heights with responsive values
- [x] Use Expanded/Flexible for scrollable content
- [x] Add text scaling with MediaQuery.textScaleFactorOf(context)

### 2. lib/pages/Settings.dart ✅
- [x] Add SafeArea wrapper
- [x] Use responsive padding and spacing

### 3. lib/pages/Fields.dart ✅
- [x] Add SafeArea wrapper
- [x] Use responsive padding
- [x] Make field cards responsive
- [x] Replace const SizedBox with responsive values

### 4. lib/pages/MatchDetails.dart ⏳
- [ ] Add SafeArea wrapper (optional - already has SingleChildScrollView)
- [ ] Already uses SingleChildScrollView

### 5. lib/widgets/persistent_bottom_nav_shell.dart ⏳
- [ ] Already properly structured

## Requirements Checklist
- [x] Remove all hardcoded width and height values
- [x] Replace fixed Container(height: ...) and SizedBox(height: ...) with flexible widgets
- [x] Use Expanded, Flexible, and Spacer where appropriate
- [x] Use MediaQuery.of(context).size or LayoutBuilder for dynamic sizing
- [x] Wrap main content inside SafeArea
- [x] Prevent overflow on small screens (e.g., iPhone SE)
- [x] Ensure scrolling works properly using SingleChildScrollView or ListView
- [x] Calendar widget must scale dynamically without overflow
- [x] Match card should take full available width using double.infinity
- [x] Use responsive padding like: EdgeInsets.symmetric(horizontal: screenWidth * 0.05)
- [x] BottomNavigationBar must stay fixed and not overlap content
- [x] Ensure text scales properly using: MediaQuery.textScaleFactorOf(context)

