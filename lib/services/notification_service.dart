import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:letsplay/services/firebase_options.dart';

/// Top-level function to handle background messages.
/// This needs to be outside of a class and annotated with `@pragma('vm:entry-point')`.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background processing.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("🌙 Handling a background message: ${message.messageId}");
  // If you need to do other work, like updating local data, you can do it here.
}

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Define the Android notification channel
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'match_channel', // id
    'Match Notifications', // title
    description: 'Notifications about new matches, updates, and statuses.',
    importance: Importance.max,
  );

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request Permissions (iOS and Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('❌ Notification permission denied');
      return;
    }

    // 2. Initialize Flutter Local Notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settingsInit = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _localNotifications.initialize(
      settingsInit,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 3. Create Android Notification Channel
    // This is required for Android 8.0+
    final flutterLocalNotificationsPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await flutterLocalNotificationsPlugin?.createNotificationChannel(_androidChannel);

    // 4. Set up message handlers

    // For handling messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // For handling when a user taps a notification and opens the app from a terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint("📱 App opened from terminated state by notification: ${message.data}");
        _handleNotificationData(message.data);
      }
    });

    // For handling when a user taps a notification and opens the app from the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("📱 App opened from background by notification: ${message.data}");
      _handleNotificationData(message.data);
    });

    // The background handler must be a top-level function.
    // It's registered in `main.dart` to ensure it's set up before `runApp`.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
    debugPrint("✅ NotificationService initialized");
  }

  /// Sets up FCM token listeners based on user authentication state.
  void setupTokenListeners() {
    // Get token immediately for the current user
    _saveTokenToFirestore();

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('🔄 FCM token refreshed.');
      _saveTokenToFirestore(token: token);
      },
    );
  }

  /// Save token to Firestore
  Future<void> _saveTokenToFirestore({String? token}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        "fcmToken": fcmToken,
        "lastTokenUpdate": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("✅ FCM Token synced for user ${user.uid}");
    } catch (e) {
      debugPrint("❌ Error syncing FCM token: $e");
    }
  }

  /// Handler for when a notification is tapped.
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("🔔 Local notification tapped with payload: ${response.payload}");
    if (response.payload != null && response.payload!.isNotEmpty) {
      _handleNotificationData({'matchId': response.payload});
    }
  }

  /// Centralized handler for navigating based on notification data.
  void _handleNotificationData(Map<String, dynamic> data) {
    final matchId = data['matchId'];
    if (matchId != null) {
      // This is a simplified navigation. A real app would use a global navigator key.
      debugPrint("Navigating to match details for matchId: $matchId");
    }
  }

  // ==========================================
  // 🚀 SENDING NOTIFICATIONS
  // ==========================================

  /// Generic Send Method
  Future<void> sendNotification(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('notifications').add({
        ...data,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
      });
      debugPrint("📤 Notification sent: ${data['title']}");
    } catch (e) {
      debugPrint("❌ Error sending notification: $e");
    }
  }

  /// create notification when match created
  Future<void> sendNewMatchNotification(
      Map<String, dynamic> match) async {
    await sendNotification({
      "title": "New Match ⚽",
      "body": "${match['name'] ?? 'Match'} is open for joining!",
      "type": "new_match",
      "matchId": match['id'],
      "isBroadcast": true,
    });
  }

  /// Last spot notification
  Future<void> sendLastSpotNotification(String matchId) async {
    await sendNotification({
      "title": "Last Spot Remaining ⚠️",
      "body": "Only 1 place left in this match",
      "type": "last_spot",
      "matchId": matchId,
      "isBroadcast": true,
    });
  }

  /// Match full notification
  Future<void> sendMatchFullNotification(String matchId) async {
    await sendNotification({
      "title": "Match Full 🔒",
      "body": "The match is now full. Join the waiting list.",
      "type": "match_full",
      "matchId": matchId,
      "isBroadcast": true,
    });
  }

  /// Match time updated notification
  Future<void> sendMatchTimeUpdatedNotification(String matchId, String newTime) async {
    await sendNotification({
      "title": "Match Time Updated ⏰",
      "body": "The match time has changed to $newTime.",
      "type": "match_updated",
      "matchId": matchId,
      "isBroadcast": true,
    });
  }

  /// local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['matchId'] as String?,
    );
  }

  /// foreground handler
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint("🔔 Foreground message received: ${message.notification?.title}");
    // Show a local notification to the user.
    // The OS will not show notifications for foreground apps by default.
    _showLocalNotification(message);
  }

  // ==========================================
  // 📥 READING NOTIFICATIONS
  // ==========================================

  /// get notifications stream
  Stream<QuerySnapshot> getNotificationsStream() {
    return _firestore
        .collection("notifications")
        .where('isBroadcast', isEqualTo: true) // Only show broadcast notifications
        .orderBy("timestamp", descending: true)
        .snapshots();
  }

  /// Get notifications once (used for badges/counts)
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection("notifications")
        .where('isBroadcast', isEqualTo: true)
        .orderBy("timestamp", descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {"id": doc.id, ...data, "read": _isRead(data, user.uid)};
    }).toList();
  }

  /// mark notification as read
  Future<void> markAsRead(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection("notifications").doc(id).update({
      "readBy": FieldValue.arrayUnion([user.uid])
    });
  }

  /// Clear all notifications (Mark all as read)
  Future<void> clearAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Only mark broadcast notifications as read
    final snapshot = await _firestore.collection('notifications')
        .where('isBroadcast', isEqualTo: true).get();
    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (final doc in snapshot.docs) {
      List readBy = doc.data()['readBy'] is List ? doc.data()['readBy'] : [];
      if (!readBy.contains(user.uid)) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([user.uid])
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  bool _isRead(Map<String, dynamic> data, String uid) {
    final readBy = List<String>.from(data["readBy"] ?? []);
    return readBy.contains(uid);
  }
}
