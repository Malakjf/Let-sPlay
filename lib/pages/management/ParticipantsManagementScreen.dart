import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/language.dart';

class ParticipantsManagementScreen extends StatefulWidget {
  final LocaleController ctrl;
  final String matchId;

  const ParticipantsManagementScreen({
    super.key,
    required this.ctrl,
    required this.matchId,
  });

  @override
  State<ParticipantsManagementScreen> createState() =>
      _ParticipantsManagementScreenState();
}

class _ParticipantsManagementScreenState
    extends State<ParticipantsManagementScreen> {
  final FirebaseService _service = FirebaseService.instance;

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);

    final mid = widget.matchId.trim();
    if (mid.isEmpty) {
      return Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(ar ? 'إدارة المشاركين' : 'Manage Participants'),
            backgroundColor: theme.appBarTheme.backgroundColor,
          ),
          body: Center(
            child: Text(ar ? 'معرّف المباراة غير صالح' : 'Invalid match id'),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(ar ? 'إدارة المشاركين' : 'Manage Participants'),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .doc(widget.matchId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final matchData = snapshot.data!.data() as Map<String, dynamic>;
            final players = List<String>.from(matchData['players'] ?? []);
            final waiting = List<Map<String, dynamic>>.from(
              matchData['waitingList'] ?? [],
            );

            // If nothing to show
            if (players.isEmpty && waiting.isEmpty) {
              return Center(
                child: Text(
                  ar ? 'لا يوجد مشاركين بعد' : 'No participants yet',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (players.isNotEmpty) ...[
                  Text(
                    ar ? 'المؤكدين' : 'Confirmed Players',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...players.map(
                    (uid) => _buildPlayerTile(uid, false, ar, theme),
                  ),
                  const SizedBox(height: 16),
                ],

                if (waiting.isNotEmpty) ...[
                  Text(
                    ar ? 'قائمة الانتظار' : 'Waiting List',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...waiting.map((entry) {
                    final uid = entry['userId'] ?? '';
                    return _buildWaitingTile(entry, uid, ar, theme);
                  }),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmUser(String userId) async {
    // Approve from waiting list into players
    await _service.approveWaitingParticipant(
      matchId: widget.matchId,
      userId: userId,
    );
  }

  Future<void> _rejectUser(String userId) async {
    // Remove from waiting list (or players) depending on where they are
    try {
      await _service.rejectWaitingParticipant(
        matchId: widget.matchId,
        userId: userId,
      );
    } catch (e) {
      // Fallback: try removing from players
      await _service.removePlayer(matchId: widget.matchId, userId: userId);
    }
  }

  Widget _buildPlayerTile(
    String userId,
    bool isWaiting,
    bool ar,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _service.getUserData(userId),
          builder: (context, snapshot) {
            final user = snapshot.data ?? {};
            final name = user['name'] ?? user['username'] ?? 'Unknown';
            final email = user['email'] ?? '';

            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        ar ? 'انضم' : 'Joined',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _rejectUser(userId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: Text(
                    ar ? 'إزالة' : 'Remove',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingTile(
    Map<String, dynamic> entry,
    String userId,
    bool ar,
    ThemeData theme,
  ) {
    final joinedAt = entry['joinedAt'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _service.getUserData(userId),
          builder: (context, snapshot) {
            final user = snapshot.data ?? {};
            final name = user['name'] ?? user['username'] ?? 'Unknown';
            final email = user['email'] ?? '';

            String subtitle = '';
            if (joinedAt is Timestamp) {
              subtitle = DateTime.fromMillisecondsSinceEpoch(
                joinedAt.millisecondsSinceEpoch,
              ).toLocal().toString();
            }

            return Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (subtitle.isNotEmpty)
                            Text(subtitle, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.hourglass_empty,
                            size: 14,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ar ? 'قائمة الانتظار' : 'Waiting',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _confirmUser(userId),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: Text(
                        ar ? 'قبول' : 'Approve',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _rejectUser(userId),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: Text(
                        ar ? 'رفض' : 'Reject',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
