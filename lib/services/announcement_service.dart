import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';
import '../widgets/AcademyAnnouncementPopup.dart';

class AnnouncementService {
  static Future<void> checkAndShowAnnouncements(
    BuildContext context,
    String userRole,
    bool isArabic,
  ) async {
    try {
      // 1. Fetch valid announcements from Firestore
      final announcements = await FirebaseService.instance
          .getValidAnnouncements(userRole);
      if (announcements.isEmpty) return;

      // 2. Check if we've already shown an announcement in this session/day
      final prefs = await SharedPreferences.getInstance();
      final lastShownId = prefs.getString('last_shown_announcement_id');
      final lastShownTimeStr = prefs.getString('last_shown_announcement_time');

      final currentAnnouncement = announcements.first;
      final announcementId = currentAnnouncement['id'];

      // Simple logic: Show only once per ID unless 24 hours passed
      if (lastShownId == announcementId && lastShownTimeStr != null) {
        final lastShownTime = DateTime.parse(lastShownTimeStr);
        if (DateTime.now().difference(lastShownTime).inHours < 24) {
          return; // Already shown recently
        }
      }

      // 3. Show the popup
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.85),
          builder: (ctx) => AcademyAnnouncementPopup(
            announcement: currentAnnouncement,
            isArabic: isArabic,
          ),
        );

        // 4. Save shown state
        await prefs.setString('last_shown_announcement_id', announcementId);
        await prefs.setString(
          'last_shown_announcement_time',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking announcements: $e');
    }
  }
}
