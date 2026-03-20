import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AccountService {
  /// Permanently deletes the user account and all associated data.
  ///
  /// Includes:
  /// - Firestore: users/{uid}
  /// - Firestore: matches (if organizer) + subcollections
  /// - Firestore: notifications
  /// - Storage: users/{uid}
  /// - Auth: User account
  static Future<void> deleteAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Confirmation Dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure? This action is irreversible. All your data, including matches you organized, will be permanently removed.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Show loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      await _performDeletion(user);

      // Success
      if (context.mounted) {
        Navigator.of(context).pop(); // Pop loading
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Pop loading
      }

      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          await _handleReauthAndDelete(context, user);
        }
      } else {
        _showError(context, "Security Error: ${e.message}");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Pop loading
        _showError(context, "Deletion failed: $e");
      }
    }
  }

  static Future<void> _performDeletion(User user) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    debugPrint('🗑️ Starting account deletion for ${user.uid}...');

    // 1. Delete Matches Created by User (Organizer)
    // We assume 'organizerId' tracks ownership.
    final matchesQuery = await firestore
        .collection('matches')
        .where('organizerId', isEqualTo: user.uid)
        .get();

    for (final doc in matchesQuery.docs) {
      debugPrint('🗑️ Deleting match ${doc.id}...');
      // Delete subcollections manually
      await _deleteSubcollection(doc.reference, 'player_stats');
      await _deleteSubcollection(doc.reference, 'player_metrics');
      await _deleteSubcollection(doc.reference, 'participants');

      await doc.reference.delete();
    }

    // 2. Delete User Notifications
    final notificationsQuery = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .get();

    await _batchDelete(notificationsQuery.docs);

    // 3. Delete User Document and Subcollections
    final userRef = firestore.collection('users').doc(user.uid);
    await _deleteSubcollection(userRef, 'participants');
    await userRef.delete();

    // 4. Delete Storage Files
    try {
      final storageRef = storage.ref().child('users/${user.uid}');
      final listResult = await storageRef.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
      debugPrint('🗑️ Deleted storage files.');
    } catch (e) {
      debugPrint("⚠️ Storage deletion warning: $e");
    }

    // 5. Delete Auth Account
    await user.delete();
    debugPrint('✅ Account deleted successfully.');
  }

  static Future<void> _deleteSubcollection(DocumentReference parent, String collectionName) async {
    final collection = parent.collection(collectionName);
    final snapshot = await collection.get();
    await _batchDelete(snapshot.docs);
  }

  static Future<void> _batchDelete(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    const batchSize = 500;
    final chunks = (docs.length / batchSize).ceil();

    for (var i = 0; i < chunks; i++) {
      final batch = FirebaseFirestore.instance.batch();
      final start = i * batchSize;
      final end = (start + batchSize < docs.length) ? start + batchSize : docs.length;

      for (var j = start; j < end; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
  }

  static Future<void> _handleReauthAndDelete(BuildContext context, User user) async {
    final passwordController = TextEditingController();

    final bool? reauthConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Security Check"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("For security, please enter your password to confirm deletion."),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (reauthConfirmed == true && passwordController.text.isNotEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordController.text,
        );

        await user.reauthenticateWithCredential(credential);
        await _performDeletion(user);

        if (context.mounted) {
          Navigator.of(context).pop(); // Pop loading
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop(); // Pop loading
          _showError(context, "Re-authentication failed: $e");
        }
      }
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}