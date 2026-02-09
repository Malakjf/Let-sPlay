import 'package:flutter/material.dart';

/// Wraps a FUT card (or any card) and makes it responsive without
/// changing the inner widget. Uses LayoutBuilder, ConstrainedBox and
/// AspectRatio to preserve the original aspect ratio and avoid overflow.
class FutCardResponsive extends StatelessWidget {
  final Widget child;
  // FUT card native aspect ratio is width:height = 1 : 1.29
  static const double _aspectRatio = 1 / 1.29;

  const FutCardResponsive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        // Determine target width using relative rules (no fixed hard widths)
        double targetWidth;

        if (maxW <= 360) {
          // Small phones: use near-full width with small horizontal padding
          targetWidth = maxW * 0.95;
        } else if (maxW <= 720) {
          // Large phones / small tablets: allow breathing room
          targetWidth = maxW * 0.80;
        } else {
          // Tablets and larger: limit to a comfortable fraction so card doesn't look tiny
          targetWidth = maxW * 0.60;
        }

        // Never exceed available width
        if (targetWidth > maxW) targetWidth = maxW;

        // Ensure we never produce zero or negative widths
        if (targetWidth <= 0) targetWidth = maxW;

        // Constrain and center horizontally. Maintain aspect ratio and add vertical spacing below.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: targetWidth),
                child: AspectRatio(aspectRatio: _aspectRatio, child: child),
              ),
            ),
            const SizedBox(height: 24), // required vertical spacing below card
          ],
        );
      },
    );
  }
}
