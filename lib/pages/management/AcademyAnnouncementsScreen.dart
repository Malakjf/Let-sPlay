import 'package:flutter/material.dart';
import '../../services/language.dart';
import '../../services/firebase_service.dart';
import 'AddAnnouncementScreen.dart';

class AcademyAnnouncementsScreen extends StatefulWidget {
  final LocaleController ctrl;
  const AcademyAnnouncementsScreen({super.key, required this.ctrl});

  @override
  State<AcademyAnnouncementsScreen> createState() =>
      _AcademyAnnouncementsScreenState();
}

class _AcademyAnnouncementsScreenState
    extends State<AcademyAnnouncementsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _announcements = [];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final data = await FirebaseService.instance.getAnnouncements();
      setState(() {
        _announcements = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(ar ? 'الإعلانات والأخبار' : 'Academy Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnnouncements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
          ? Center(child: Text(ar ? 'لا توجد إعلانات' : 'No announcements'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final ad = _announcements[index];
                final isActive = ad['isActive'] ?? false;

                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ad['imageUrl'] != null && ad['imageUrl'].isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              ad['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.campaign),
                    title: Text(ad['title'] ?? ''),
                    subtitle: Text(
                      isActive
                          ? (ar ? 'نشط' : 'Active')
                          : (ar ? 'غير نشط' : 'Inactive'),
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddAnnouncementScreen(
                            ctrl: widget.ctrl,
                            announcement: ad,
                          ),
                        ),
                      );
                      _loadAnnouncements();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddAnnouncementScreen(ctrl: widget.ctrl),
            ),
          );
          _loadAnnouncements();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
