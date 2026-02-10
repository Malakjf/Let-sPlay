// ignore_for_file: annotate_overrides

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import 'package:google_fonts/google_fonts.dart';
import 'animations/fut_card_light_sweep.dart';
import 'animations/idle_animated_fut_card.dart';

/// 🎨 Helper to resolve card asset based on level (Pure & Deterministic)
String getFutCardAssetByLevel(int level) {
  if (level < 25) return 'assets/images/bronze.png';
  if (level < 50) return 'assets/images/silver.png';
  if (level < 75) return 'assets/images/gold.png';
  return 'assets/images/diamond.png';
}

Color getFutColorByLevel(int level) {
  if (level < 25) return const Color(0xFFCD7F32); // Bronze
  if (level < 50) return const Color(0xFFC0C0C0); // Silver
  if (level < 75) return const Color(0xFFFFD700); // Gold
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

class _FutCardFullState extends State<FutCardFull> {
  PlayerAttributesStore? _attributesStore;

  @override
  void initState() {
    super.initState();
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
    _attributesStore?.unsubscribeFromPlayer(widget.playerId);
    super.dispose();
  }

  // _subscribe and _unsubscribe are no longer needed; handled by loadPlayerAttributes
  @override
  Widget build(BuildContext context) {
    // 🎯 Use Consumer to listen to PlayerAttributesStore (Single Source of Truth)
    return Consumer<PlayerAttributesStore>(
      builder: (context, attrStore, child) {
        final attributes = attrStore.getPlayerAttributes(widget.playerId);
        final isGk = widget.position.toUpperCase() == 'GK';

        // The card's content is built inside LayoutBuilder to be fully responsive.
        // It scales all its internal elements based on the width it receives from its parent.
        return LayoutBuilder(
          builder: (context, constraints) {
            // The card is designed for a base width of 480px.
            // We derive a scale factor from the actual width provided by the parent.
            final double cardWidth = constraints.maxWidth;

            // If width is not finite or zero, we cannot render the card.
            // This indicates a layout problem where FutCardFull is not given width constraints.
            // A wrapper like FutCardResponsive should be used to provide constraints.
            if (!cardWidth.isFinite || cardWidth <= 0) {
              return const SizedBox.shrink();
            }

            // The scale factor is the ratio of the actual width to the design width.
            final double scale = cardWidth / 480.0;

            // The height is determined by the aspect ratio to avoid distortion.
            final double cardHeight = cardWidth * 1.29;

            return _buildCard(
              context,
              attributes,
              isGk: isGk,
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
  ) {
    final color = getFutColorByLevel(widget.rating);
    final List<Widget> children = [];
    double gridWidth;

    if (isGk) {
      // 🧤 GK Layout: 2x2 Grid
      // PAS | SAV
      // CS  | GR

      // PAS (Passing)
      children.add(
        _buildStatBox('PAS', attributes?.passing ?? 0, scale, color),
      );
      // SAV (Defending)
      children.add(
        _buildStatBox('SAV', attributes?.defending ?? 0, scale, color),
      );
      // CS (Physical)
      children.add(
        _buildStatBox('CS', attributes?.physical ?? 0, scale, color),
      );
      // GR (Pace)
      children.add(_buildStatBox('GR', attributes?.pace ?? 0, scale, color));

      // Width for 2 items: (60 * 2) + 8 = 128.
      gridWidth = 140 * scale;
    } else {
      // 🏃 Outfield Layout: 3x2 Grid
      // PAC | SHO | PAS
      // DRI | DEF | PHY

      children.add(_buildStatBox('PAC', attributes?.pace ?? 0, scale, color));
      children.add(
        _buildStatBox('SHO', attributes?.shooting ?? 0, scale, color),
      );
      children.add(
        _buildStatBox('PAS', attributes?.passing ?? 0, scale, color),
      );
      children.add(
        _buildStatBox('DRI', attributes?.dribbling ?? 0, scale, color),
      );
      children.add(
        _buildStatBox('DEF', attributes?.defending ?? 0, scale, color),
      );
      children.add(
        _buildStatBox('PHY', attributes?.physical ?? 0, scale, color),
      );

      // Width for 3 items: (60 * 3) + (8 * 2) = 196.
      gridWidth = 210 * scale;
    }

    return SizedBox(
      width: gridWidth,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8 * scale,
        runSpacing: 6 * scale,
        children: children,
      ),
    );
  }

  Widget _buildStatBox(String label, int value, double scale, Color color) {
    if (label.isEmpty) return SizedBox(width: 60 * scale, height: 40 * scale);

    // 🎨 Color Rules: Red < 50, Orange < 75, Glass/Theme > 75
    Color fillColor;
    if (value < 50) {
      fillColor = const Color(0xFFD32F2F).withOpacity(0.85); // Red
    } else if (value <= 75) {
      fillColor = const Color(0xFFF57C00).withOpacity(0.85); // Orange
    } else {
      fillColor = color.withOpacity(0.4); // Glass / Theme Color
    }

    return Container(
      width: 60 * scale,
      height: 48 * scale, // Fixed height for fill calculation
      decoration: BoxDecoration(
        color: const Color(0xFF2A2218).withOpacity(0.85),
        border: Border.all(color: color.withOpacity(0.5), width: 1 * scale),
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 📊 Vertical Fill Animation
          LayoutBuilder(
            builder: (context, constraints) {
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: value / 100),
                duration: const Duration(milliseconds: 800),
                builder: (context, progress, child) {
                  return Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight * progress,
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(3 * scale),
                        top: Radius.circular(progress >= 0.95 ? 3 * scale : 0),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // 📝 Text Content (Centered)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 800),
                builder: (context, val, child) => Text(
                  '$val',
                  style: GoogleFonts.saira(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for contrast
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 2 * scale),
                    ],
                    height: 1,
                  ),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.saira(
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    PlayerAttributes? attributes, {
    required bool isGk,
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
    final backgroundAsset = getFutCardAssetByLevel(widget.rating);

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
                child: Image.asset(backgroundAsset, fit: BoxFit.contain),
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
                    widget.rating.toString(),
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
                              image: NetworkImage(widget.countryIcon),
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
                            image: NetworkImage(
                              // Add cache-busting timestamp to force reload
                              // 🛡️ Safe string interpolation
                              widget.avatarUrl!.contains('?')
                                  ? '${widget.avatarUrl!}&t=${DateTime.now().millisecondsSinceEpoch}'
                                  : '${widget.avatarUrl!}?t=${DateTime.now().millisecondsSinceEpoch}',
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
              top: 295 * scale,
              child: SizedBox(
                width: 280 * scale,
                child: Column(
                  children: [
                    Text(
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
                  ],
                ),
              ),
            ),

            // 🎯 Attributes Grid (Coach-Driven, Always Visible)
            // PAC, SHO, PAS, DRI, DEF, PHY - 2x3 grid
            Positioned(
              top: 345 * scale,
              child: _attributesGrid(attributes, scale, displayPosition, isGk),
            ),

            // 🔰 Level Label (Bottom of card)
            Positioned(
              bottom: 22 * scale,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 32 * scale,
                  vertical: 10 * scale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3728),
                  borderRadius: BorderRadius.circular(25 * scale),
                  border: Border.all(
                    color: const Color(0xFF8B6F47),
                    width: 2 * scale,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4 * scale,
                      offset: Offset(0, 2 * scale),
                    ),
                  ],
                ),
                child: Text(
                  'LV. ${widget.rating}',
                  style: GoogleFonts.saira(
                    color: const Color(0xFFE8D4B0),
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
