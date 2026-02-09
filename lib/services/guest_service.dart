import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuestService {
  static bool _isGuestMode = false;

  /// Set guest mode (called when user selects "View as Guest")
  static void setGuestMode(bool isGuest) {
    _isGuestMode = isGuest;
  }

  /// Check if the current user is a guest (not authenticated OR in guest mode)
  static bool isGuest() {
    return _isGuestMode || FirebaseAuth.instance.currentUser == null;
  }

  /// Show a dialog prompting the user to log in and redirect to login page
  static void promptLogin(BuildContext context, bool isArabic) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isArabic ? 'تسجيل الدخول مطلوب' : 'Login Required'),
          content: Text(
            isArabic
                ? 'يجب عليك تسجيل الدخول للوصول إلى هذه الميزة'
                : 'You need to log in to access this feature',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushNamed(context, '/login'); // Navigate to login
              },
              child: Text(
                isArabic ? 'تسجيل الدخول' : 'Login',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Handle guest interaction - shows prompt if guest, returns true if authenticated
  static bool handleGuestInteraction(BuildContext context, bool isArabic) {
    if (isGuest()) {
      // Immediately redirect guest to the login page when they interact with
      // an action that requires authentication. This enforces a consistent
      // behavior: any protected interaction sends the user to the login screen.
      Navigator.pushNamed(context, '/login');
      return false; // Guest user - action blocked until they authenticate
    }
    return true; // Authenticated user - action allowed
  }
}
