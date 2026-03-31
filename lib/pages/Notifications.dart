import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// عدّل المسار لو NotificationService عندك في مكان آخر
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // تأكد أن السرفيس مبادر (يطابق ما عندك). هذا آمن لأن initialize() داخليًا يحمي من النداءات المتكررة.
    _notificationService.initialize();
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.tryParse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String _formatTimestamp(dynamic ts) {
    final dt = _toDateTime(ts);
    if (dt == null) return '';
    // صيغة عرض قابلة للتعديل
    return DateFormat.yMMMd().add_jm().format(dt.toLocal());
  }

  Widget _buildErrorCard(Object? error) {
    final msg = error?.toString() ?? 'Unknown error';
    // Try to extract a Firebase console index creation URL, if present
    final match = RegExp(r'https?://\S+').firstMatch(msg);
    final url = match?.group(0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: TextStyle(color: Colors.grey[300], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              // show short message preview
              msg.split('\n').take(2).join(' '),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (url != null) ...[
              const SizedBox(height: 12),
              SelectableText(
                url,
                style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy index URL'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Index URL copied to clipboard'),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('No notifications yet', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _onMarkAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      // لا حاجة لـ setState لأن الستريم سيعيد البناء عند تغيّر المستندات.
    } catch (e) {
      debugPrint('Error markAsRead: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
      }
    }
  }

  Future<void> _onClearAll() async {
    try {
      await _notificationService.clearAllNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Error clearAllNotifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear notifications: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _onClearAll,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // show error card but avoid crashing; user can still copy index link if present
            return _buildErrorCard(snapshot.error);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data ?? [];

          if (docs.isEmpty) return _buildEmpty();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(
                docs[index],
              );

              final id = data['id']?.toString() ?? '';
              final title = (data['title'] ?? 'Notification').toString();
              final body = (data['body'] ?? '').toString();
              final ts = data['timestamp'];
              final isBroadcast = data['isBroadcast'] == true;
              final isRead = data['read'] == true;

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isRead ? Colors.grey[850] : Colors.grey[900],
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  child: Icon(
                    isBroadcast ? Icons.sports_soccer : Icons.notifications,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimestamp(ts),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: isRead
                    ? const Icon(Icons.check, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.mark_email_read),
                        tooltip: 'Mark as read',
                        onPressed: () => _onMarkAsRead(id),
                      ),
                onTap: () {
                  if (!isRead) _onMarkAsRead(id);
                  final matchId = data['matchId'];
                  if (matchId != null && matchId.toString().isNotEmpty) {
                    // Navigator.pushNamed(context, '/matchDetails', arguments: matchId);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
