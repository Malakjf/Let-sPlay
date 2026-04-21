import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/firestore_helper.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/guest_service.dart';

class MatchesService extends ChangeNotifier {
  // ... existing members (matches list, loadMatchesFromFirestore, etc.)

  /// Unified logic to join a match or the waiting list.
  /// Handles validations, transactions, and UI feedback.
  Future<void> joinMatch({
    required BuildContext context,
    required Map<String, dynamic> match,
    required bool ar,
  }) async {
    // 1. Guest Check
    if (!GuestService.handleGuestInteraction(context, ar)) {
      return;
    }

    // 2. Auth Check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(
        context,
        ar ? 'يجب تسجيل الدخول أولاً' : 'Please login first',
        isError: true,
      );
      return;
    }

    // 3. Match ID Validation
    final matchId = (match['id'] ?? match['matchId'])?.toString();
    if (matchId == null || matchId.isEmpty) {
      _showSnackBar(
        context,
        ar ? 'معرف المباراة غير صالح' : 'Invalid Match ID',
        isError: true,
      );
      return;
    }

    try {
      // 4. Fetch Fresh Data (Ensure we aren't joining an ended/full match based on stale cache)
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .get();
      if (!matchDoc.exists) {
        _showSnackBar(
          context,
          ar ? 'المباراة لم تعد موجودة' : 'Match no longer exists',
          isError: true,
        );
        return;
      }
      final data = matchDoc.data()!;

      // 5. Match Ended Validation
      final matchDate = parseFirestoreDate(data['date']);
      int durationMin = 90;
      if (data['duration'] is num) {
        durationMin = (data['duration'] as num).toInt();
      } else if (data['duration'] is String) {
        durationMin = int.tryParse(data['duration']) ?? 90;
      }

      final matchEnd = matchDate.add(Duration(minutes: durationMin));
      final now = DateTime.now();

      if (now.isAfter(matchEnd)) {
        _showSnackBar(
          context,
          ar ? 'هذه المباراة انتهت بالفعل' : 'This match has already ended.',
          isError: true,
        );
        return;
      }

      // 6. Registration Open Validation
      final openRegistry = data['openRegistryDate'];
      final registrationStartTime = openRegistry != null
          ? parseFirestoreDate(openRegistry)
          : matchDate;

      if (now.isBefore(registrationStartTime)) {
        _showRegistrationClosedDialog(context, ar, registrationStartTime);
        return;
      }

      // 7. Execute Transaction (Players vs Waiting List)
      final maxPlayers = data['maxPlayers'] ?? 10;
      final currentCount = data['playersCount'] ?? 0;
      final isFull = currentCount >= maxPlayers;

      await FirebaseService.instance.joinMatchTransaction(
        matchId: matchId,
        userId: user.uid,
      );

      // 8. Notifications Logic
      if (maxPlayers > 0) {
        if (currentCount == maxPlayers - 1) {
          NotificationService().sendLastSpotNotification(matchId);
        } else if (currentCount >= maxPlayers) {
          NotificationService().sendMatchFullNotification(matchId);
        }
      }

      // 9. Success Feedback
      if (context.mounted) {
        _showSnackBar(
          context,
          ar
              ? (isFull
                    ? 'تمت الإضافة إلى قائمة الانتظار'
                    : 'تم الانضمام بنجاح')
              : (isFull ? 'Added to Waiting List' : 'Successfully joined'),
          isError: false,
        );

        // Refresh local cache
        loadMatchesFromFirestore();
      }
    } catch (e) {
      debugPrint('❌ Error in joinMatch: $e');
      String errorMsg = ar ? 'حدث خطأ أثناء الانضمام' : 'Error joining match';
      if (e.toString().contains('already requested')) {
        errorMsg = ar ? 'لقد انضممت بالفعل' : 'You have already joined';
      }
      _showSnackBar(context, errorMsg, isError: true);
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showRegistrationClosedDialog(
    BuildContext context,
    bool ar,
    DateTime openTime,
  ) {
    // Formatting helper (replicated from source of truth)
    final hour = openTime.hour.toString().padLeft(2, '0');
    final minute = openTime.minute.toString().padLeft(2, '0');
    final timeStr = '${openTime.day}/${openTime.month} • $hour:$minute';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(ar ? 'التسجيل مغلق' : 'Registration Closed'),
        content: Text(
          ar
              ? 'سيفتح باب التسجيل لهذه المباراة في: $timeStr'
              : 'Registration for this match will open at: $timeStr',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ar ? 'حسناً' : 'OK'),
          ),
        ],
      ),
    );
  }

  // Placeholder for existing loadMatchesFromFirestore method
  void loadMatchesFromFirestore() {}
}
