import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _loadParticipants();
  }

  void _loadParticipants() {
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
    // ✅ Check if user is authenticated before building FutureBuilder
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // If user is null (guest mode), show login required message
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Participants Management')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  'Login Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please login to access participants management',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Participants Management')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          // Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle error state - prevents indefinite loading
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading participants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Handle empty data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No participants'),
                ],
              ),
            );
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
