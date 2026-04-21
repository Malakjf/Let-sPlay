import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:letsplay/widgets/LogoButton.dart';
import 'package:letsplay/services/language.dart';

class PlayersAcademyScreen extends StatelessWidget {
  final LocaleController ctrl;
  const PlayersAcademyScreen({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final ar = ctrl.isArabic;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ar ? 'لاعبو الأكاديمية' : 'Academy Players'),
          centerTitle: true,
          actions: const [LogoButton()],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          // Prefer users collection with isAcademy flag (matches Management users view).
          // Fallback to academy_players only if users query yields no docs.
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('isAcademy', isEqualTo: true)
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final userDocs = snapshot.data?.docs ?? [];

            if (userDocs.isNotEmpty) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: userDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final d = userDocs[index];
                  final data = d.data();

                  final name =
                      (data['name'] ?? data['username'] ?? 'Unknown') as String;
                  final avatar =
                      (data['avatarUrl'] ?? data['photoUrl'] ?? '') as String;
                  final number = data['number']?.toString() ?? '';
                  final teamColorVal = data['teamColor'];
                  final Color teamColor = (teamColorVal is int)
                      ? Color(teamColorVal)
                      : Theme.of(context).primaryColor;

                  final initials = name
                      .split(' ')
                      .where((s) => s.isNotEmpty)
                      .map((s) => s[0])
                      .take(2)
                      .join()
                      .toUpperCase();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: teamColor,
                      backgroundImage:
                          (avatar.isNotEmpty &&
                              (avatar.startsWith('http') ||
                                  avatar.startsWith('https')))
                          ? NetworkImage(avatar) as ImageProvider
                          : null,
                      child: (avatar.isEmpty) ? Text(initials) : null,
                    ),
                    title: Text(name),
                    subtitle: number.isNotEmpty
                        ? Text(ar ? 'رقم $number' : 'No. $number')
                        : null,
                    onTap: () {},
                  );
                },
              );
            }

            // Fallback to academy_players collection if users query returns no docs
            return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('academy_players')
                  .orderBy('name')
                  .get(),
              builder: (context, fb) {
                if (fb.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = fb.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(ar ? 'لا يوجد لاعبون' : 'No academy players'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data();
                    final name = (data['name'] ?? 'Unknown') as String;
                    final avatar =
                        (data['photoUrl'] ?? data['avatarUrl'] ?? '') as String;
                    final number = data['number']?.toString() ?? '';
                    final teamColorVal = data['teamColor'];
                    final Color teamColor = (teamColorVal is int)
                        ? Color(teamColorVal)
                        : Theme.of(context).primaryColor;

                    final initials = name
                        .split(' ')
                        .where((s) => s.isNotEmpty)
                        .map((s) => s[0])
                        .take(2)
                        .join()
                        .toUpperCase();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: teamColor,
                        backgroundImage:
                            (avatar.isNotEmpty &&
                                (avatar.startsWith('http') ||
                                    avatar.startsWith('https')))
                            ? NetworkImage(avatar) as ImageProvider
                            : null,
                        child: (avatar.isEmpty) ? Text(initials) : null,
                      ),
                      title: Text(name),
                      subtitle: number.isNotEmpty
                          ? Text(ar ? 'رقم $number' : 'No. $number')
                          : null,
                      onTap: () {},
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
