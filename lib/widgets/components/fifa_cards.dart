import 'package:flutter/material.dart';
import '../../theme/design_system.dart';

/// 🎮 FIFA-Style Hero Card
///
/// Premium elevated card with glow effect
/// Used as the main focal point on each screen

class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? glowColor;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool showGlow;

  const HeroCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.glowColor,
    this.onTap,
    this.borderRadius = 20,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin ?? const EdgeInsets.all(DesignSystem.spacing16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: DesignSystem.cardGradient,
        boxShadow: [
          ...DesignSystem.cardShadow,
          if (showGlow)
            BoxShadow(
              color: (glowColor ?? DesignSystem.primaryCyan).withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 10),
            ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(DesignSystem.spacing20),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return PressableScale(onTap: onTap, child: card);
    }

    return card;
  }
}

/// 🃏 Standard Card with elevation
class ElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;

  const ElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius = 16,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing16,
            vertical: DesignSystem.spacing8,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignSystem.bgCard,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(DesignSystem.spacing16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return PressableScale(onTap: onTap, pressScale: 0.98, child: card);
    }

    return card;
  }
}

/// 🖼️ Image Card (for Fields, Store items)
class ImageCard extends StatelessWidget {
  final String? imageUrl;
  final Widget? placeholder;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;

  const ImageCard({
    super.key,
    this.imageUrl,
    this.placeholder,
    required this.title,
    this.subtitle,
    this.badge,
    this.onTap,
    this.height = 200,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressScale: 0.98,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              if (imageUrl != null && imageUrl!.isNotEmpty)
                Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      placeholder ?? _defaultPlaceholder(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return _defaultPlaceholder();
                  },
                )
              else
                placeholder ?? _defaultPlaceholder(),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: DesignSystem.spacing16,
                right: DesignSystem.spacing16,
                bottom: DesignSystem.spacing16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: DesignSystem.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Badge
              if (badge != null)
                Positioned(
                  top: DesignSystem.spacing12,
                  right: DesignSystem.spacing12,
                  child: badge!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: DesignSystem.bgCard,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: DesignSystem.textMuted,
          size: 48,
        ),
      ),
    );
  }
}

/// 💰 Price Badge
class PriceBadge extends StatelessWidget {
  final String price;
  final String? currency;
  final Color? backgroundColor;
  final Color? textColor;

  const PriceBadge({
    super.key,
    required this.price,
    this.currency = 'PFJ',
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignSystem.spacing12,
        vertical: DesignSystem.spacing8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? DesignSystem.primaryCyan,
        borderRadius: BorderRadius.circular(DesignSystem.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? DesignSystem.primaryCyan).withOpacity(
              0.4,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$price ${currency ?? ''}',
        style: AppTypography.labelLarge.copyWith(
          color: textColor ?? DesignSystem.textOnPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 📊 Stat Card (for Goals, Assists, etc.)
class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? color;
  final bool animate;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignSystem.spacing16),
      decoration: BoxDecoration(
        color: DesignSystem.bgCard,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        border: Border.all(
          color: (color ?? DesignSystem.primaryCyan).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color ?? DesignSystem.primaryCyan, size: 24),
          const SizedBox(height: DesignSystem.spacing8),
          animate
              ? TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, animatedValue, child) {
                    return Text(
                      animatedValue.toString(),
                      style: AppTypography.statNumber.copyWith(
                        color: color ?? DesignSystem.primaryCyan,
                      ),
                    );
                  },
                )
              : Text(
                  value.toString(),
                  style: AppTypography.statNumber.copyWith(
                    color: color ?? DesignSystem.primaryCyan,
                  ),
                ),
          const SizedBox(height: DesignSystem.spacing4),
          Text(label.toUpperCase(), style: AppTypography.statLabel),
        ],
      ),
    );
  }
}

/// 🏆 Match Card (Hero style for today's match)
class MatchHeroCard extends StatelessWidget {
  final String title;
  final String location;
  final String time;
  final String date;
  final int currentPlayers;
  final int maxPlayers;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool isJoined;

  const MatchHeroCard({
    super.key,
    required this.title,
    required this.location,
    required this.time,
    required this.date,
    required this.currentPlayers,
    required this.maxPlayers,
    this.imageUrl,
    this.onTap,
    this.onJoin,
    this.isJoined = false,
  });

  @override
  Widget build(BuildContext context) {
    return HeroCard(
      onTap: onTap,
      glowColor: isJoined ? DesignSystem.success : DesignSystem.primaryCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isJoined
                      ? DesignSystem.success.withOpacity(0.2)
                      : DesignSystem.primaryCyan.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isJoined ? 'JOINED' : 'TODAY',
                  style: AppTypography.labelSmall.copyWith(
                    color: isJoined
                        ? DesignSystem.success
                        : DesignSystem.primaryCyan,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: AppTypography.headlineMedium.copyWith(
                  color: DesignSystem.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacing16),

          // Title
          Text(
            title,
            style: AppTypography.headlineLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignSystem.spacing8),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: DesignSystem.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignSystem.spacing16),

          // Players count
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAYERS', style: AppTypography.labelSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$currentPlayers',
                          style: AppTypography.headlineLarge.copyWith(
                            color: DesignSystem.primaryCyan,
                          ),
                        ),
                        Text(
                          ' / $maxPlayers',
                          style: AppTypography.headlineSmall.copyWith(
                            color: DesignSystem.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onJoin != null)
                PrimaryButton(
                  text: isJoined ? 'View' : 'Join',
                  onPressed: onJoin!,
                  icon: isJoined ? Icons.visibility : Icons.add,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 🔘 Primary Button (Hero CTA)
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool compact;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.compact = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: width ?? (compact ? null : double.infinity),
        height: compact ? 44 : 56,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? DesignSystem.spacing20 : DesignSystem.spacing24,
        ),
        decoration: BoxDecoration(
          gradient: DesignSystem.primaryGradient,
          borderRadius: BorderRadius.circular(compact ? 22 : 28),
          boxShadow: DesignSystem.glowShadow(DesignSystem.primaryCyan),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: AppTypography.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 🔳 Secondary Button (Outline style)
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool compact;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onPressed,
      child: Container(
        width: compact ? null : double.infinity,
        height: compact ? 44 : 52,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? DesignSystem.spacing20 : DesignSystem.spacing24,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 22 : 26),
          border: Border.all(
            color: DesignSystem.primaryCyan.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: DesignSystem.primaryCyan, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTypography.button.copyWith(
                  color: DesignSystem.primaryCyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📝 Glass Input Field
class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        style: AppTypography.bodyLarge,
        cursorColor: DesignSystem.primaryCyan,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: DesignSystem.textMuted,
          ),
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: DesignSystem.textSecondary,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: DesignSystem.textSecondary, size: 22)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignSystem.spacing16,
            vertical: DesignSystem.spacing16,
          ),
          floatingLabelStyle: AppTypography.labelMedium.copyWith(
            color: DesignSystem.primaryCyan,
          ),
        ),
      ),
    );
  }
}

/// 🎭 Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignSystem.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.primaryCyan.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                size: 48,
                color: DesignSystem.primaryCyan.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: DesignSystem.spacing24),
            Text(
              title,
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DesignSystem.spacing8),
              Text(
                subtitle!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: DesignSystem.spacing24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
