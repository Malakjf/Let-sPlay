import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ParticipantsManagementPage extends StatefulWidget {
  final String matchId;
  const ParticipantsManagementPage({super.key, required this.matchId});

  @override
  State<ParticipantsManagementPage> createState() =>
      _ParticipantsManagementPageState();
}

class _ParticipantsManagementPageState
    extends State<ParticipantsManagementPage> {
  late Future<List<Map<String, dynamic>>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _participantsFuture = FirebaseService.instance.getAllParticipants(
      widget.matchId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _participantsFuture = FirebaseService.instance.getAllParticipants(
        widget.matchId,
      );
    });
  }

  Future<void> _confirm(String userId) async {
    await FirebaseService.instance.confirmParticipant(
      matchId: widget.matchId,
      userId: userId,
    );
    _refresh();
  }

  Future<void> _reject(String userId) async {
    await FirebaseService.instance.rejectParticipant(
      matchId: widget.matchId,
      userId: userId,
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participants Management')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No participants'));
          }
          final participants = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final p = participants[index];
                return ListTile(
                  title: Text(p['userId'] ?? ''),
                  subtitle: Text(
                    'Status: ${p['status']} | JoinType: ${p['joinType']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p['status'] == 'pending' || p['status'] == 'waiting')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _confirm(p['userId']),
                        ),
                      if (p['status'] != 'rejected')
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _reject(p['userId']),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
