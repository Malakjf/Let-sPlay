// ignore_for_file: annotate_overrides

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animations/fut_card_light_sweep.dart';
import 'animations/idle_animated_fut_card.dart';
import '../utils/image_helper.dart';

/// 🎨 Helper to resolve card asset based on level (Pure & Deterministic)
String getFutCardAssetByLevel(int level) {
  if (level <= 25) return 'assets/images/bronze.png'; // Level 1-25
  if (level <= 50) {
    return 'assets/images/selver.png'; // Level 26-50 (Corrected filename)
  }
  if (level <= 75) return 'assets/images/gold.png'; // Level 51-75
  return 'assets/images/diamond.png';
}

Color getFutColorByLevel(int level) {
  if (level <= 25) return const Color(0xFFCD7F32); // Bronze
  if (level <= 50) return const Color(0xFFC0C0C0); // Silver
  if (level <= 75) return const Color(0xFFFFD700); // Gold
  return const Color(0xFFB9F2FF);
}

///  FIFA / PlayFootball.me Architecture: FUT Card (Attributes Only)
///
/// CORE PRINCIPLE:
/// - Attributes are dynamic (coach-driven)
/// - NO static data for PAC/SHO/PAS/DRI/DEF/PHY
/// - Reads from PlayerAttributesStore only
/// - Updates live when coach changes evaluation
///
/// Card shows ONLY: PAC, SHO, PAS, DRI, DEF, PHY (2x3 grid)
class FutCardFull extends StatefulWidget {
  final String playerId; // ✅ Only need ID
  final String playerName;
  final String position;
  final int rating;
  final String countryIcon;
  final PlayerAttributes? overrideAttributes;
  final int? overrideRating;
  final String? avatarUrl;
  final Color? ratingColor;
  final Color? textColor;
  final Color? avatarBackgroundColor;
  final Color? levelBackgroundColor;
  final Color? levelBorderColor;
  final Color? levelTextColor;

  const FutCardFull({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.rating,
    required this.countryIcon,
    this.overrideAttributes,
    this.overrideRating,
    this.avatarUrl,
    this.ratingColor,
    this.textColor,
    this.avatarBackgroundColor,
    this.levelBackgroundColor,
    this.levelBorderColor,
    this.levelTextColor,
  });

  /// 🛡️ Helper to validate image URLs safely
  static bool _isValidUrl(String? url) {
    return url != null &&
        url.trim().isNotEmpty &&
        (url.startsWith('http://') || url.startsWith('https://'));
  }

  @override
  State<FutCardFull> createState() => _FutCardFullState();
}

class _FutCardFullState extends State<FutCardFull>
    with SingleTickerProviderStateMixin {
  PlayerAttributesStore? _attributesStore;
  late AnimationController _levelUpController;
  late Animation<double> _celebrationScale;
  late Animation<double> _celebrationOpacity;
  int? _prevLevel;

  @override
  void initState() {
    super.initState();
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _celebrationScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: CurveTween(curve: Curves.easeOutBack),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.2), weight: 40),
      TweenSequenceItem(tween: CurveTween(curve: Curves.easeIn), weight: 20),
    ]).animate(_levelUpController);

    _celebrationOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_levelUpController);

    // Always load and subscribe to player attributes on mount
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = context.read<PlayerAttributesStore>();
      await store.loadPlayerAttributes(widget.playerId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache the store reference to use in dispose
    _attributesStore = context.read<PlayerAttributesStore>();
  }

  @override
  void didUpdateWidget(FutCardFull oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerId != widget.playerId) {
      final store = context.read<PlayerAttributesStore>();
      store.unsubscribeFromPlayer(oldWidget.playerId);
      store.loadPlayerAttributes(widget.playerId);
    }
  }

  @override
  void dispose() {
    // 4️⃣ Navigation Stability: Unsubscribe per-player
    _levelUpController.dispose();
    _attributesStore?.unsubscribeFromPlayer(widget.playerId);
    super.dispose();
  }

  // _subscribe and _unsubscribe are no longer needed; handled by loadPlayerAttributes
  @override
  Widget build(BuildContext context) {
    // 🎯 Use Consumer to listen to PlayerAttributesStore (Single Source of Truth)
    return Consumer<PlayerAttributesStore>(
      builder: (context, attrStore, child) {
        final attributes = widget.overrideAttributes ??
            attrStore.getPlayerAttributes(widget.playerId);
        final effectiveRating = widget.overrideRating ?? widget.rating;

        // 🛠️ Asset Debug Logging
        final assetPath = getFutCardAssetByLevel(effectiveRating);
        final tierName = effectiveRating <= 25
            ? 'Bronze'
            : effectiveRating <= 50
                ? 'Selver'
                : effectiveRating <= 75
                    ? 'Gold'
                    : 'Diamond';

        debugPrint('FUT Card: Level=$effectiveRating');
        debugPrint('FUT Card: Asset=$assetPath');
        debugPrint('FUT Card: Tier=$tierName');

        // � Detect Level Up
        if (_prevLevel != null && effectiveRating > _prevLevel!) {
          _levelUpController.forward(from: 0.0);
        }
        _prevLevel = effectiveRating;

        final isGk = widget.position.toUpperCase() == 'GK';

        // The card's content is built inside LayoutBuilder to be fully responsive.
        // It scales all its internal elements based on the width it receives from its parent.
        return LayoutBuilder(
          builder: (context, constraints) {
            // The card is designed for a base width of 480px.
            // We derive a scale factor from the actual width provided by the parent.
            final double cardWidth = constraints.maxWidth;

            // iPad FIX: Handle infinite or zero constraints gracefully to avoid blank screens
            if (!cardWidth.isFinite || cardWidth <= 0) {
              final screenWidth = MediaQuery.of(context).size.width;
              final fallbackWidth =
                  screenWidth > 600 ? 400.0 : screenWidth * 0.85;
              return Center(
                child: SizedBox(
                  width: fallbackWidth,
                  height: fallbackWidth * 1.29,
                  child: _buildCard(
                    context,
                    attributes,
                    isGk: isGk,
                    effectiveRating: effectiveRating,
                    scale: fallbackWidth / 480.0,
                    cardWidth: fallbackWidth,
                    cardHeight: fallbackWidth * 1.29,
                  ),
                ),
              );
            }

            // The scale factor is the ratio of the actual width to the design width.
            final double scale = cardWidth / 480.0;

            // The height is determined by the aspect ratio to avoid distortion.
            final double cardHeight = cardWidth * 1.29;

            return _buildCard(
              context,
              attributes,
              isGk: isGk,
              effectiveRating: effectiveRating,
              scale: scale,
              cardWidth: cardWidth,
              cardHeight: cardHeight,
            );
          },
        );
      },
    );
  }

  /// 🎯 Attributes Grid (2x3 FIFA-style layout)
  /// Shows PAC, SHO, PAS, DRI, DEF, PHY with animations
  Widget _attributesGrid(
    PlayerAttributes? attributes,
    double scale,
    String displayPosition,
    bool isGk,
    int effectiveRating,
  ) {
    final themeColor = getFutColorByLevel(effectiveRating);
    final List<Widget> stats = [];

    if (isGk) {
      stats.addAll([
        _buildStatBox('PAS', attributes?.passing ?? 0, scale, themeColor),
        _buildStatBox('SAV', attributes?.defending ?? 0, scale, themeColor),
        _buildStatBox('CS', attributes?.physical ?? 0, scale, themeColor),
        _buildStatBox('GR', attributes?.pace ?? 0, scale, themeColor),
      ]);
    } else {
      stats.addAll([
        _buildStatBox('PAC', attributes?.pace ?? 0, scale, themeColor),
        _buildStatBox('SHO', attributes?.shooting ?? 0, scale, themeColor),
        _buildStatBox('PAS', attributes?.passing ?? 0, scale, themeColor),
        _buildStatBox('DRI', attributes?.dribbling ?? 0, scale, themeColor),
        _buildStatBox('DEF', attributes?.defending ?? 0, scale, themeColor),
        _buildStatBox('PHY', attributes?.physical ?? 0, scale, themeColor),
      ]);
    }

    return Container(
      width: 210 * scale,
      alignment: Alignment.center,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8 * scale, // Tightened horizontal spacing
        runSpacing:
            14 * scale, // Slightly reduced row spacing for a compact look
        children: stats,
      ),
    );
  }

  Widget _buildStatBox(
    String label,
    int value,
    double scale,
    Color themeColor,
  ) {
    if (label.isEmpty) return const SizedBox.shrink();

    // 🎨 Dynamic color system
    final bool isLow = value < 50;

    final Color baseColor = isLow
        ? const Color(0xFFFF3B30) // Red
        : const Color(0xFFFF9F1C); // Orange / Gold

    final List<Color> gradientColors = isLow
        ? [const Color(0xFFFF6B6B), const Color(0xFFFF3B30)]
        : [const Color(0xFFFFC75F), const Color(0xFFFF9F1C)];

    final List<Shadow> statGlow = [
      Shadow(
        color: baseColor.withOpacity(0.7),
        blurRadius: 12 * scale,
        offset: const Offset(0, 0),
      ),
      Shadow(
        color: baseColor.withOpacity(0.35),
        blurRadius: 24 * scale,
        offset: const Offset(0, 0),
      ),
    ];

    return SizedBox(
      width: 64 * scale, // Narrower container for compact typography
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //  Animated Stat Number
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            builder: (context, val, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ).createShader(bounds),
                child: Text(
                  '$val',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.saira(
                    fontSize: 24 * scale, // Refined, slightly smaller size
                    fontWeight: FontWeight
                        .w600, // Semi-bold for a premium, cleaner look
                    letterSpacing: -0.8 * scale, // Subtle negative tracking
                    color: Colors.white,
                    height: 1,
                    shadows: statGlow,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 4 * scale),

          // 🏷️ Label
          Text(
            label,
            style: GoogleFonts.saira(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5 * scale,
              color: Colors.white.withOpacity(0.6),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    PlayerAttributes? attributes, {
    required bool isGk,
    required int effectiveRating,
    required double scale,
    required double cardWidth,
    required double cardHeight,
  }) {
    // Sizing logic is now handled by the LayoutBuilder in the build method.
    // We receive scale, cardWidth, and cardHeight as parameters.

    // 🎯 Resolve position: Use widget param to ensure immediate UI updates (e.g. when editing profile)
    // We prioritize the parameter because if the parent rebuilds with a new position (e.g. dropdown),
    // we must reflect that change immediately, even if the store hasn't synced yet.
    final displayPosition = widget.position;

    // 🎨 Resolve background asset based on level (Strict Mapping)
    final backgroundAsset = getFutCardAssetByLevel(effectiveRating);

    // 🛡️ Defensive URL Validation
    final bool hasValidUrl = FutCardFull._isValidUrl(widget.avatarUrl);
    final bool hasValidCountry = FutCardFull._isValidUrl(widget.countryIcon);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: cardWidth, maxHeight: cardHeight),
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Animated Background Layer (Breathes)
            Positioned.fill(
              child: IdleAnimatedFutCard(
                child: Image.asset(
                  backgroundAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/bronze.png',
                      fit: BoxFit.contain,
                    ); // Fallback to bronze as safest base
                  },
                ),
              ),
            ),
            // ✨ Premium Light Sweep Overlay (Background Effect)
            const Positioned.fill(child: FutCardLightSweep()),

            // 🏅 Rating + Position + Flag (Left Side)
            Positioned(
              top: 150 * scale,
              left: 135 * scale,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    effectiveRating.toString(),
                    style: GoogleFonts.saira(
                      fontSize: 36 * scale,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4A3728),
                      shadows: [
                        Shadow(color: Colors.black12, blurRadius: 1 * scale),
                      ],
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    displayPosition.toUpperCase(),
                    style: GoogleFonts.saira(
                      color: const Color(0xFF4A3728),
                      fontSize: 36 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Container(
                    width: 46 * scale,
                    height: 30 * scale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2 * scale),
                      border: Border.all(
                        color: Colors.black12,
                        width: 0.5 * scale,
                      ),
                      image: hasValidCountry
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(
                                ImageHelper.refreshImageUrl(widget.countryIcon),
                                cacheKey: widget.countryIcon,
                              ),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            // 👤 Player avatar circle (Right Side)
            Positioned(
              top: 150 * scale,
              right: 120 * scale,
              child: Container(
                width: 130 * scale,
                height: 130 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8B6F47),
                    width: 3.5 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4 * scale,
                      offset: Offset(0, 2 * scale),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: hasValidUrl ? null : const Color(0xFFB8956A),
                    shape: BoxShape.circle,
                    image: hasValidUrl
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              ImageHelper.refreshImageUrl(
                                  widget.avatarUrl ?? ''),
                              cacheKey: widget.avatarUrl,
                            ),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              debugPrint('❌ Error loading avatar: $exception');
                            },
                          )
                        : null,
                  ),
                  child: !hasValidUrl
                      ? Center(
                          child: Text(
                            (widget.playerName.isNotEmpty)
                                ? widget.playerName
                                    .split(' ')
                                    .where((e) => e.isNotEmpty)
                                    .map((e) => e[0])
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                                : '??',
                            style: GoogleFonts.saira(
                              fontSize: 38 * scale,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 2 * scale,
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),

            // 🏷️ Player Name (Centered)
            Positioned(
              top: 290 * scale, // Slightly adjusted vertical position
              width: cardWidth * 0.8, // Constrain width to 80% of card width
              child: Text(
                widget.playerName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.saira(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A3728),
                  shadows: [
                    Shadow(color: Colors.black54, blurRadius: 3 * scale),
                  ],
                ),
              ),
            ),

            // 🎯 Attributes Grid (Coach-Driven, Always Visible)
            // PAC, SHO, PAS, DRI, DEF, PHY - 2x3 grid
            Positioned(
              top: 340 * scale, // Slightly adjusted vertical position
              width: cardWidth * 0.9, // Give it more horizontal space
              child: FittedBox(
                // Ensure the grid scales to fit
                fit: BoxFit.scaleDown,
                child: _attributesGrid(
                  attributes,
                  scale,
                  displayPosition,
                  isGk,
                  effectiveRating,
                ),
              ),
            ),

            // 🔰 Level Label (Bottom of card)
            Positioned(
              bottom: 22 * scale,
              child: AnimatedBuilder(
                animation: _levelUpController,
                builder: (context, child) {
                  // Badge glows during level up
                  final double glow = _levelUpController.value > 0 &&
                          _levelUpController.value < 0.8
                      ? (1.0 - (_levelUpController.value - 0.5).abs() * 2)
                      : 0.0;

                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32 * scale,
                      vertical: 10 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3728),
                      borderRadius: BorderRadius.circular(25 * scale),
                      border: Border.all(
                        color: Color.lerp(
                          const Color(0xFF8B6F47),
                          const Color(0xFFFFD700),
                          glow,
                        )!,
                        width: (2 + (glow * 2)) * scale,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFFD700,
                          ).withOpacity(glow * 0.6),
                          blurRadius: 15 * scale * glow,
                          spreadRadius: 5 * scale * glow,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4 * scale,
                          offset: Offset(0, 2 * scale),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Text(
                        'LV. $effectiveRating',
                        key: ValueKey(effectiveRating),
                        style: GoogleFonts.saira(
                          color: Color.lerp(
                            const Color(0xFFE8D4B0),
                            Colors.white,
                            glow,
                          ),
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ✨ Level Up Celebration Overlay
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _levelUpController,
                  builder: (context, child) {
                    if (_levelUpController.value <= 0) {
                      return const SizedBox.shrink();
                    }
                    return Center(
                      child: Opacity(
                        opacity: _celebrationOpacity.value,
                        child: Transform.scale(
                          scale: _celebrationScale.value * scale,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'LEVEL UP!',
                                style: GoogleFonts.saira(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFFFD700),
                                  fontStyle: FontStyle.italic,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10 * scale,
                                    ),
                                    Shadow(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withOpacity(0.5),
                                      blurRadius: 20 * scale,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
