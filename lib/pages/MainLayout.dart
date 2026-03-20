import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:letsplay/utils/permissions.dart';
import '../main.dart';
import '../services/store_store.dart';
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
      _StoreTab(ctrl: widget.ctrl),
      _ProfileTab(ctrl: widget.ctrl),
    ];
  }

  @override
  void dispose() {
    StoreStore.instance.stopListening();
    super.dispose();
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

class _StoreTab extends StatefulWidget {
  final LocaleController ctrl;
  const _StoreTab({required this.ctrl});

  @override
  State<_StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<_StoreTab> {
  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      StoreStore.instance.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;

    // 🔒 If user is null (guest mode), show login required
    if (user == null) {
      return Scaffold(
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
                  ar ? 'تسجيل الدخول مطلوب' : 'Login Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  ar ? 'يرجى تسجيل الدخول للوصول إلى المتجر' : 'Please login to access the store',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: Text(ar ? 'تسجيل الدخول' : 'Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StorePage(ctrl: widget.ctrl);
  }
}

class _FieldsTab extends StatelessWidget {
  final LocaleController ctrl;
  const _FieldsTab({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final ar = ctrl.isArabic;
    
    // 🔒 If user is null (guest mode), show login required
    if (user == null) {
      return Scaffold(
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
                  ar ? 'تسجيل الدخول مطلوب' : 'Login Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  ar
                      ? 'يرجى تسجيل الدخول للوصول إلى الملاعب'
                      : 'Please login to access the fields',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: Text(ar ? 'تسجيل الدخول' : 'Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
    final theme = Theme.of(context);
    final ar = ctrl.isArabic;
    
    // 🔒 If user is null (guest mode), show login required
    if (user == null) {
      return Scaffold(
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
                  ar ? 'تسجيل الدخول مطلوب' : 'Login Required',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  ar
                      ? 'يرجى تسجيل الدخول للوصول إلى الملف الشخصي'
                      : 'Please login to access your profile',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: Text(ar ? 'تسجيل الدخول' : 'Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
