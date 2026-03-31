import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

/// 🎮 FIFA-Style Bottom Navigation Bar
///
/// Features:
/// - Glow highlight on active item
/// - Scale animation on selection
/// - Premium dark theme styling

class FifaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FifaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.sports_soccer_rounded,
                label: 'Fields',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.storefront_rounded,
                label: 'Store',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      pressScale: 0.9,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    if (widget.isActive)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: DesignSystem.primaryCyan.withOpacity(
                                0.4 * _glowAnimation.value,
                              ),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    // Icon
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Icon(
                        widget.icon,
                        size: 26,
                        color: widget.isActive
                            ? DesignSystem.primaryCyan
                            : DesignSystem.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  widget.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: widget.isActive
                        ? DesignSystem.primaryCyan
                        : DesignSystem.textMuted,
                    fontWeight: widget.isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                // Active indicator
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.isActive ? 20 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: DesignSystem.primaryCyan,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: DesignSystem.primaryCyan.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 📱 App Bar with premium styling
class FifaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const FifaAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Leading
              if (showBack)
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: DesignSystem.textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              else if (leading != null)
                leading!
              else
                const SizedBox(width: 48),

              // Title
              Expanded(
                child: centerTitle
                    ? Center(
                        child: Text(title, style: AppTypography.headlineMedium),
                      )
                    : Text(title, style: AppTypography.headlineMedium),
              ),

              // Actions
              if (actions != null)
                Row(mainAxisSize: MainAxisSize.min, children: actions!)
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

/// 🔔 Notification Badge
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: DesignSystem.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.error.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 🏷️ Status Chip
class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? DesignSystem.primaryCyan;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing12,
        vertical: DesignSystem.spacing4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// 📅 Compact Calendar Header
class CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  const CalendarHeader({
    super.key,
    required this.focusedDay,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing16,
        vertical: DesignSystem.spacing8,
      ),
      child: Row(
        children: [
          PressableScale(
            onTap: onPrevious,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: DesignSystem.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: DesignSystem.spacing12),
          Expanded(
            child: Text(
              '${monthNames[focusedDay.month - 1]} ${focusedDay.year}',
              style: AppTypography.headlineSmall,
            ),
          ),
          if (onToday != null) ...[
            PressableScale(
              onTap: onToday,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DesignSystem.primaryCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Today',
                  style: AppTypography.labelSmall.copyWith(
                    color: DesignSystem.primaryCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignSystem.spacing12),
          ],
          PressableScale(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignSystem.bgCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: DesignSystem.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
