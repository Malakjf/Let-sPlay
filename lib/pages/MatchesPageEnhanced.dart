import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/language.dart';
import '../models/user_permission.dart';
import 'MatchEditPage.dart';
import 'MatchDetails.dart';

/// FIX: Helper to safely parse dates from Firestore (Timestamp or String)
DateTime? _parseMatchDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Helper to check if current user has joined the match
bool _hasUserJoinedMatch(Map<String, dynamic> match) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  // Check participants array (new logic)
  final participants = List<Map<String, dynamic>>.from(
    match['participants'] ?? [],
  );
  final participant = participants.firstWhere(
    (p) => p['userId'] == user.uid,
    orElse: () => {},
  );
  if (participant.isNotEmpty && participant['status'] == 'confirmed') {
    return true;
  }

  // Fallback to players array (legacy)
  final players = List<String>.from(match['players'] ?? []);
  return players.contains(user.uid);
}

/// Enhanced Matches Page with add/edit functionality
class MatchesPageEnhanced extends StatefulWidget {
  final LocaleController ctrl;
  final UserPermission userPermission;

  const MatchesPageEnhanced({
    super.key,
    required this.ctrl,
    required this.userPermission,
  });

  @override
  State<MatchesPageEnhanced> createState() => _MatchesPageEnhancedState();
}

class _MatchesPageEnhancedState extends State<MatchesPageEnhanced> {
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _filteredMatches = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterType = 'all'; // all, upcoming, past

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
    _searchCtrl.addListener(_filterMatches);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('matches')
          .orderBy('date', descending: true)
          .get();

      final matches = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _matches = matches;
          _filteredMatches = matches;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      debugPrint('❌ Error loading matches: $e');
      if (e.toString().contains('failed-precondition')) {
        debugPrint(
          '⚠️ Missing Index on matches collection. Showing empty/cached list.',
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterMatches() {
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    final now = DateTime.now();

    setState(() {
      _filteredMatches = _matches.where((match) {
        // Search filter
        final matchesSearch =
            query.isEmpty ||
            (match['name']?.toString().toLowerCase().contains(query) ??
                false) ||
            (match['fieldName']?.toString().toLowerCase().contains(query) ??
                false);

        if (!matchesSearch) return false;

        // Time filter
        if (_filterType == 'all') return true;

        try {
          // FIX: Use safe parser instead of direct cast
          final matchDate = _parseMatchDate(match['date']);
          if (matchDate == null) return _filterType == 'all';

          if (_filterType == 'upcoming') {
            return matchDate.isAfter(now);
          } else if (_filterType == 'past') {
            return matchDate.isBefore(now);
          }
        } catch (e) {
          return _filterType == 'all';
        }

        return true;
      }).toList();
    });
  }

  Future<void> _deleteMatch(Map<String, dynamic> match) async {
    final ar = widget.ctrl.isArabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'حذف المباراة' : 'Delete Match'),
        content: Text(
          ar
              ? 'هل أنت متأكد من حذف "${match['name']}"؟'
              : 'Are you sure you want to delete "${match['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(match['id'])
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ar ? 'تم حذف المباراة' : 'Match deleted'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMatches();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ar ? 'فشل الحذف' : 'Failed to delete'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);
    final canManage = widget.userPermission == UserPermission.admin;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(ar ? 'المباريات' : 'Matches'),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: Column(
          children: [
            // Search and Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: ar ? 'البحث...' : 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterChip(
                          label: ar ? 'الكل' : 'All',
                          selected: _filterType == 'all',
                          onTap: () {
                            setState(() {
                              _filterType = 'all';
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChip(
                          label: ar ? 'القادمة' : 'Upcoming',
                          selected: _filterType == 'upcoming',
                          onTap: () {
                            setState(() {
                              _filterType = 'upcoming';
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FilterChip(
                          label: ar ? 'الماضية' : 'Past',
                          selected: _filterType == 'past',
                          onTap: () {
                            setState(() {
                              _filterType = 'past';
                            });
                            _applyFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Matches List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 64,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ar ? 'لا توجد مباريات' : 'No matches found',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMatches,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMatches.length,
                        itemBuilder: (context, index) {
                          final match = _filteredMatches[index];
                          return _MatchCard(
                            match: match,
                            ctrl: widget.ctrl,
                            canManage: canManage,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MatchDetailsScreen(
                                    ctrl: widget.ctrl,
                                    matchId: match['id'],
                                  ),
                                  settings: RouteSettings(
                                    arguments: match['id'],
                                  ),
                                ),
                              );
                            },
                            onEdit: canManage
                                ? () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MatchEditPage(
                                          ctrl: widget.ctrl,
                                          match: match,
                                        ),
                                      ),
                                    );
                                    if (result == true) {
                                      _loadMatches();
                                    }
                                  }
                                : null,
                            onDelete: canManage
                                ? () => _deleteMatch(match)
                                : null,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        floatingActionButton: canManage
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchEditPage(ctrl: widget.ctrl),
                    ),
                  );
                  if (result == true) {
                    _loadMatches();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(ar ? 'إضافة مباراة' : 'Add Match'),
              )
            : null,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : theme.textTheme.bodyMedium?.color,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final LocaleController ctrl;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MatchCard({
    required this.match,
    required this.ctrl,
    required this.canManage,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ar = ctrl.isArabic;
    final theme = Theme.of(context);
    final matchDate = _parseMatchDate(match['date']);
    final _ = matchDate != null && matchDate.isBefore(DateTime.now());
    final hasJoined = _hasUserJoinedMatch(match);
    final visibility = match['visibility'] as String?;
    final isAcademy = visibility == 'academy';
    final isPrivate = visibility == 'private';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Joined Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match['name'] ?? (ar ? 'مباراة' : 'Match'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isAcademy) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        ar ? 'أكاديمية' : 'Academy',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (isPrivate) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        ar ? 'خاص' : 'Private',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if (hasJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ar ? 'انضممت' : 'Joined',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (canManage) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: ar ? 'تعديل' : 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: onDelete,
                      tooltip: ar ? 'حذف' : 'Delete',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              // Date
              if (matchDate != null)
                Text(
                  '${matchDate.day}/${matchDate.month}/${matchDate.year}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              const SizedBox(height: 4),
              // Meta info row
              Row(
                children: [
                  if (match['fieldName'] != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        match['fieldName'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                  if (match['time'] != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      match['time'].toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Players bar and action button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${match['playersCount'] ?? 0}/${match['maxPlayers'] ?? 10}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (match['maxPlayers'] ?? 10) > 0
                              ? (match['playersCount'] ?? 0) /
                                    (match['maxPlayers'] ?? 10)
                              : 0,
                          backgroundColor: theme.dividerColor.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary.withOpacity(0.6),
                          ),
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: hasJoined
                        ? onTap
                        : () {
                            onTap();
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary.withOpacity(
                        0.8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      hasJoined
                          ? (ar ? 'عرض التفاصيل' : 'View Details')
                          : ((match['playersCount'] ?? 0) >=
                                    (match['maxPlayers'] ?? 10)
                                ? (ar ? 'قائمة الانتظار' : 'Waiting List')
                                : (ar ? 'انضم' : 'Join')),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
