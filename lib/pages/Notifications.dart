import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/language.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  final LocaleController ctrl; // Passed for language settings

  const NotificationsPage({super.key, required this.ctrl});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  String _formatTime(DateTime time, bool ar) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return ar ? "الآن" : "Now";
    }
    if (diff.inMinutes < 60) {
      return ar ? "${diff.inMinutes} دقيقة" : "${diff.inMinutes} min";
    }
    if (diff.inHours < 24) {
      return ar ? "${diff.inHours} ساعة" : "${diff.inHours} h";
    }
    if (diff.inDays < 7) {
      return ar ? "${diff.inDays} يوم" : "${diff.inDays} d";
    }
    return DateFormat('dd/MM/yyyy').format(time);
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'new_match':
        return Icons.sports_soccer;
      case 'last_spot':
        return Icons.warning_amber_rounded;
      case 'match_full':
        return Icons.lock_outline;
      case 'match_updated':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type, bool isRead) {
    if (isRead) return Colors.grey;
    switch (type) {
      case 'last_spot':
        return Colors.orange;
      case 'match_full':
        return Colors.red;
      case 'new_match':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, String id) {
    final ar = widget.ctrl.isArabic;
    final readBy = List<String>.from(notification['readBy'] ?? []);
    final isRead = currentUserId != null && readBy.contains(currentUserId);

    final dynamic rawTs = notification['timestamp']; // Can be Timestamp or null
    DateTime timestamp = DateTime.now();
    if (rawTs is Timestamp) {
      timestamp = rawTs.toDate();
    } else if (rawTs is DateTime) {
      timestamp = rawTs;
    }

    final timeString = _formatTime(timestamp, ar);
    final type = notification['type'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: isRead ? 0 : 2,
      color: isRead ? Theme.of(context).cardColor : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead ? BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)) : BorderSide(color: Colors.blue.shade200),
      ),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            await _notificationService.markAsRead(id);
          }
          final matchId = notification['matchId'];
          if (matchId != null) {
            Navigator.pushNamed(context, '/matchDetails', arguments: matchId);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getColorForType(type, isRead).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForType(type),
                  color: _getColorForType(type, isRead),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                              color: isRead ? Colors.black87 : Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          timeString,
                          style: TextStyle(
                            fontSize: 11,
                            color: isRead ? Colors.grey : Colors.blueGrey,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(ar ? "الإشعارات" : "Notifications"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: ar ? 'تحديد الكل كمقروء' : 'Mark all as read',
            onPressed: () async {
              await _notificationService.clearAllNotifications();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        ar ? 'تم تحديد الكل كمقروء' : 'All marked as read'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    ar ? "حدث خطأ" : "Something went wrong",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    ar ? "لا توجد إشعارات" : "No notifications yet",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;
              return _buildNotificationCard(data, id);
            },
          );
        },
      ),
    );
  }
}
