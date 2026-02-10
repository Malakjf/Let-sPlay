import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission for notifications
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Get FCM token
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  Future<void> sendNewMatchNotification(Map<String, dynamic> match) async {
    try {
      debugPrint('🔔 Sending new match notification...');

      final matchName = match['name'] ?? match['title'] ?? 'New Match';
      final fieldName = match['fieldName'] ?? match['field'] ?? 'Unknown Field';
      final date = match['date'] ?? 'TBD';

      debugPrint('Match: $matchName at $fieldName on $date');

      // Create notification data
      final notificationData = {
        'title': 'New Match Available!',
        'body': '$matchName at $fieldName on $date',
        'matchId': match['id'],
        'type': 'match',
        'isBroadcast': true,
        'readBy': <String>[], // Initialize empty array for tracking who read it
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save notification to Firestore for all users (broadcast)
      debugPrint('💾 Saving notification to Firestore...');
      final docRef = await _firestore
          .collection('notifications')
          .add(notificationData);
      debugPrint('✅ Notification saved with ID: ${docRef.id}');

      // Show local notification immediately
      debugPrint('📱 Showing local notification...');
      await _showLocalNotification(notificationData);
      debugPrint('✅ Local notification shown');

      // Send push notification to all users (requires Firebase Cloud Functions for server-side sending)
      await _sendPushNotification(notificationData);
    } catch (e) {
      debugPrint('❌ Error sending new match notification: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _sendPushNotification(
    Map<String, dynamic> notificationData,
  ) async {
    // This would typically be done via Firebase Cloud Functions
    // For now, we'll just log it
    print('Sending push notification: ${notificationData['title']}');
  }

  Future<void> _showLocalNotification(
    Map<String, dynamic> notificationData,
  ) async {
    try {
      debugPrint('Creating local notification with data: $notificationData');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'match_channel',
            'Match Notifications',
            channelDescription: 'Notifications for new matches',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final title = notificationData['title'];
      final body = notificationData['body'];
      final payload = notificationData['matchId'];

      debugPrint('Showing notification #$notificationId: $title - $body');

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

      debugPrint('✅ Local notification shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing local notification: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    if (message.notification != null) {
      _showLocalNotification({
        'title': message.notification!.title,
        'body': message.notification!.body,
        'matchId': message.data['matchId'],
      });
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      // Fetch user-specific notifications
      final userNotificationsQuery = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .get();

      // Fetch broadcast notifications (new matches, etc.)
      final broadcastNotificationsQuery = _firestore
          .collection('notifications')
          .where('isBroadcast', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .get();

      // Wait for both queries to complete
      final results = await Future.wait([
        userNotificationsQuery,
        broadcastNotificationsQuery,
      ]);
      final userNotifications = results[0];
      final broadcastNotifications = results[1];

      // Combine and sort by timestamp (most recent first)
      final allNotifications =
          [...userNotifications.docs, ...broadcastNotifications.docs]
            ..sort((a, b) {
              final aTime =
                  (a.data()['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              final bTime =
                  (b.data()['timestamp'] as Timestamp?)?.toDate() ??
                  DateTime.now();
              return bTime.compareTo(aTime);
            });

      return allNotifications
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
              'read': _isNotificationRead(doc.data(), user.uid),
            },
          )
          .toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Clear user-specific notifications
      final userNotificationsQuery = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Clear broadcast notifications
      final broadcastNotificationsQuery = _firestore
          .collection('notifications')
          .where('isBroadcast', isEqualTo: true)
          .get();

      final results = await Future.wait([
        userNotificationsQuery,
        broadcastNotificationsQuery,
      ]);
      final userNotifications = results[0];
      final broadcastNotifications = results[1];

      final batch = _firestore.batch();

      // Mark user-specific notifications as read
      for (final doc in userNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Mark broadcast notifications as read by this user
      for (final doc in broadcastNotifications.docs) {
        final data = doc.data();
        final readBy = List<String>.from(data['readBy'] ?? []);
        if (!readBy.contains(user.uid)) {
          readBy.add(user.uid);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }

  bool _isNotificationRead(
    Map<String, dynamic> notificationData,
    String userId,
  ) {
    if (notificationData['isBroadcast'] == true) {
      // For broadcast notifications, check if user has read it
      final readBy = List<String>.from(notificationData['readBy'] ?? []);
      return readBy.contains(userId);
    } else {
      // For user-specific notifications, use the 'read' field
      return notificationData['read'] ?? false;
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
