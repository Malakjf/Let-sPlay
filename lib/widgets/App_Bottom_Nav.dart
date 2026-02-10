import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:letsplay/theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int index;
  final Function(int)? onTap;
  const AppBottomNav({super.key, required this.index, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return CurvedNavigationBar(
      index: index,
      height: 60,
      backgroundColor: theme.backgroundColor,
      color: theme.surfaceColor,
      buttonBackgroundColor: theme.primaryColor,
      onTap: onTap,
      items: [
        Icon(
          Icons.home_outlined,
          color: index == 0 ? Colors.white : theme.textPrimaryColor,
        ),
        Icon(
          Icons.sports_soccer_outlined,
          color: index == 1 ? Colors.white : theme.textPrimaryColor,
        ),
        Icon(
          Icons.storefront_outlined,
          color: index == 2 ? Colors.white : theme.textPrimaryColor,
        ),
        Icon(
          Icons.person_outline,
          color: index == 3 ? Colors.white : theme.textPrimaryColor,
        ),
      ],
    );
  }
}
