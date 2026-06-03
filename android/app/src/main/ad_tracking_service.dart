import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'dart:io';

class AdTrackingService {
  static final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  /// Initializes tracking permissions for iOS and sets Meta tracking status.
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      final isAuthorized = status == TrackingStatus.authorized;
      
      // On iOS 14+, Meta requires setting advertiser tracking enabled 
      // based on the user's consent for ATT.
      await _facebookAppEvents.setAdvertiserTracking(enabled: isAuthorized);
    }
  }

  /// Logs when a player successfully signs up.
  static Future<void> logPlayerSignup({required String registrationMethod}) async {
    await _facebookAppEvents.logEvent(
      name: 'player_signup',
      parameters: {
        'registration_method': registrationMethod,
      },
    );
  }

  /// Logs when a booking is made for the academy.
  static Future<void> logAcademyBooking({
    required String academyName,
    required double totalPrice,
    required String currency,
    String? bookingId,
  }) async {
    await _facebookAppEvents.logEvent(
      name: 'academy_booking',
      parameters: {
        'academy_name': academyName,
        'value': totalPrice,
        'currency': currency,
        'content_id': bookingId ?? '',
        'content_type': 'product',
      },
    );
  }
}