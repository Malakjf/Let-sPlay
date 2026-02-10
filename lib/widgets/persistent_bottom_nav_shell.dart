import 'package:flutter/material.dart';

class PersistentBottomNavShell extends StatefulWidget {
  final List<Widget> tabs;
  final List<GlobalKey<NavigatorState>> navigatorKeys;
  final int homeTabIndex;
  final List<BottomNavigationBarItem> items;
  final void Function(int tabIndex)? onTabSwitch;

  const PersistentBottomNavShell({
    super.key,
    required this.tabs,
    required this.navigatorKeys,
    required this.items,
    this.homeTabIndex = 0,
    this.onTabSwitch,
  });

  @override
  State<PersistentBottomNavShell> createState() =>
      _PersistentBottomNavShellState();
}

class _PersistentBottomNavShellState extends State<PersistentBottomNavShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    widget.onTabSwitch?.call(index);
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = widget.navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    } else if (_currentIndex != widget.homeTabIndex) {
      setState(() {
        _currentIndex = widget.homeTabIndex;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            widget.tabs.length,
            (i) => Navigator(
              key: widget.navigatorKeys[i],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => widget.tabs[i],
                settings: settings,
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          items: widget.items,
          onTap: (index) {
            if (_currentIndex == index) {
              final nav = widget.navigatorKeys[index].currentState;
              if (nav != null && nav.canPop()) {
                while (nav.canPop()) {
                  nav.pop();
                }
              }
            } else {
              _switchTab(index);
            }
          },
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
