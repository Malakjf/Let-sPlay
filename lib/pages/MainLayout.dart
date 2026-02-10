import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letsplay/utils/permissions.dart';
import '../main.dart';
import '../services/language.dart';
import '../widgets/App_Bottom_Nav.dart';
import 'Home.dart';
import 'Fields.dart';
import 'Store.dart';
import 'Profile.dart';

class MainLayout extends StatefulWidget {
  final LocaleController ctrl;
  const MainLayout({super.key, required this.ctrl});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(ctrl: widget.ctrl),
      _FieldsTab(ctrl: widget.ctrl),
      StorePage(ctrl: widget.ctrl),
      _ProfileTab(ctrl: widget.ctrl),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        index: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class _FieldsTab extends StatelessWidget {
  final LocaleController ctrl;
  const _FieldsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return FutureBuilder<Map<String, dynamic>>(
      future: loadProfileSafe(context, user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Error: ${snapshot.error ?? "Unknown"}'));
        }

        final data = snapshot.data!;
        return FieldsScreen(
          ctrl: ctrl,
          userPermission: permissionFromRole(data['role']),
        );
      },
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final LocaleController ctrl;
  const _ProfileTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: CircularProgressIndicator());

    return FutureBuilder<Map<String, dynamic>>(
      future: loadProfileSafe(context, user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Error: ${snapshot.error ?? "Unknown"}'));
        }

        final data = snapshot.data!;
        return ProfileScreen(
          ctrl: ctrl,
          player: data['player'],
          userPermission: permissionFromRole(data['role']),
        );
      },
    );
  }
}
