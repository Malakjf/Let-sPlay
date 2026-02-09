import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language.dart';
import '../services/notification_service.dart';
import '../widgets/GlassContainer.dart';

class NotificationsPage extends StatefulWidget {
  final LocaleController ctrl;
  const NotificationsPage({super.key, required this.ctrl});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await NotificationService().getNotifications();
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text(
            ar ? 'الإشعارات' : 'Notifications',
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.displayLarge?.color ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.clear_all,
                color: theme.textTheme.bodyMedium?.color,
              ),
              onPressed: _clearAllNotifications,
            ),
          ],
        ),
        body: _notifications.isEmpty
            ? _buildEmptyState(context, ar, theme)
            : _buildNotificationsList(context, ar, theme),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool ar, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            ar ? 'لا توجد إشعارات' : 'No notifications',
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.displayLarge?.color ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ar ? 'ستظهر إشعاراتك هنا' : 'Your notifications will appear here',
            style: GoogleFonts.spaceGrotesk(
              color: theme.textTheme.bodyMedium?.color ?? Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    bool ar,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(context, ar, theme, notification);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    bool ar,
    ThemeData theme,
    Map<String, dynamic> notification,
  ) {
    final isRead = notification['read'] ?? false;
    final timestamp = notification['timestamp'] as DateTime?;
    final timeString = timestamp != null ? _formatTime(timestamp, ar) : '';

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      opacity: isRead ? 0.05 : 0.15,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: !isRead
              ? Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getNotificationIcon(notification['type']),
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? '',
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.textTheme.displayLarge?.color ?? Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['body'] ?? '',
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.textTheme.bodyMedium?.color ?? Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeString,
                    style: GoogleFonts.spaceGrotesk(
                      color: theme.textTheme.bodySmall?.color ?? Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'match':
        return Icons.sports_soccer;
      case 'reminder':
        return Icons.schedule;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime timestamp, bool ar) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return ar
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return ar
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return ar
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes} minutes ago';
    } else {
      return ar ? 'الآن' : 'Now';
    }
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          widget.ctrl.isArabic
              ? 'مسح جميع الإشعارات'
              : 'Clear All Notifications',
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        content: Text(
          widget.ctrl.isArabic
              ? 'هل أنت متأكد من مسح جميع الإشعارات؟'
              : 'Are you sure you want to clear all notifications?',
          style: GoogleFonts.spaceGrotesk(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.ctrl.isArabic ? 'إلغاء' : 'Cancel',
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await NotificationService().clearAllNotifications();
              setState(() {
                _notifications.clear();
              });
            },
            child: Text(
              widget.ctrl.isArabic ? 'مسح' : 'Clear',
              style: GoogleFonts.spaceGrotesk(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
