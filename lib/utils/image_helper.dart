import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart'; // For PaintingBinding
import 'package:flutter/foundation.dart'; // For debugPrint

/// Standardized utility for handling image URL refreshing and cache eviction
class ImageHelper {
  /// Add timestamp to force refresh
  static String refreshImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    final separator = url.contains('?') ? '&' : '?';
    final refreshedUrl =
        '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
    debugPrint("✅ Fresh image URL generated: $refreshedUrl");
    return refreshedUrl;
  }

  /// Completely clears an image from both CachedNetworkImage and Flutter's ImageCache
  static Future<void> evictImage(String? url) async {
    if (url == null || url.isEmpty) return;

    try {
      // Evict from CachedNetworkImage
      await CachedNetworkImage.evictFromCache(url);

      // Clear Flutter's general image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      debugPrint("🧹 Image cache cleared for old URL: $url");
    } catch (e) {
      debugPrint('⚠️ Error evicting cache: $e');
    }
  }
}
