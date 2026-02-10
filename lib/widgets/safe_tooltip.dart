import 'dart:async';
import 'package:flutter/material.dart';

/// 🛡️ SafeTooltip
///
/// A lightweight, Ticker-free tooltip implementation using Overlay.
/// Replaces Flutter's native Tooltip to avoid "SingleTickerProviderStateMixin"
/// conflicts in complex animated widgets (like FutCardFull).
///
/// Features:
/// - No AnimationController (Zero Ticker conflict risk)
/// - Overlay-based (Renders on top of everything)
/// - Auto-dismiss
/// - Production-safe for Lists and StreamBuilders
class SafeTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration duration;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double verticalOffset;

  const SafeTooltip({
    super.key,
    required this.child,
    required this.message,
    this.duration = const Duration(seconds: 2),
    this.textStyle,
    this.backgroundColor,
    this.verticalOffset = 48.0,
  });

  @override
  State<SafeTooltip> createState() => _SafeTooltipState();
}

class _SafeTooltipState extends State<SafeTooltip> {
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  final LayerLink _layerLink = LayerLink();

  void _showTooltip() {
    // Prevent duplicate entries
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200, // Fixed width container for centering
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          // Center the 200px container relative to the target widget
          offset: Offset(size.width / 2 - 100, -widget.verticalOffset),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style:
                        widget.textStyle ??
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    _dismissTimer = Timer(widget.duration, _removeTooltip);
  }

  void _removeTooltip() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onLongPress: _showTooltip,
        onTap: _showTooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => _showTooltip(),
          onExit: (_) => _removeTooltip(),
          child: widget.child,
        ),
      ),
    );
  }
}
