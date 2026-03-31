import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A widget that checks if user is logged in before executing Firestore queries.
/// This prevents permission-denied errors and indefinite loading when user is null.
class AuthRequiredScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const AuthRequiredScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  /// Check if user is authenticated
  static bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Build the login-required message with login button
  static Widget buildLoginRequired({
    required bool isArabic,
    required ThemeData theme,
    VoidCallback? onLoginPressed,
  }) {
    return Center(
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
              isArabic ? 'تسجيل الدخول مطلوب' : 'Login Required',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'يرجى تسجيل الدخول للوصول إلى هذه الميزة'
                  : 'Please login to access this feature',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onLoginPressed ?? () {
                // Navigation will be handled by the calling context
              },
              icon: const Icon(Icons.login),
              label: Text(isArabic ? 'تسجيل الدخول' : 'Login'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    
    // Get LocaleController if available (for RTL support)
    bool isArabic = false;
    try {
      // Try to get the controller from context
      // This is a fallback - most screens will pass this directly
      isArabic = Localizations.localeOf(context).languageCode == 'ar';
    } catch (_) {
      // Use default if can't determine
    }

    if (user == null) {
      // User is not authenticated - show login prompt
      return Scaffold(
        appBar: appBar,
        body: buildLoginRequired(
          isArabic: isArabic,
          theme: theme,
          onLoginPressed: () {
            Navigator.pushNamed(context, '/login');
          },
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      );
    }

    // User is authenticated - show the actual content
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// A mixin that provides auth checking functionality for screens
mixin AuthGuardMixin<T extends StatefulWidget> on State<T> {
  /// Check if current user is authenticated
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Build login required scaffold (for use in build method)
  Widget buildAuthRequired({
    required bool isArabic,
    required ThemeData theme,
  }) {
    return Scaffold(
      body: AuthRequiredScaffold.buildLoginRequired(
        isArabic: isArabic,
        theme: theme,
        onLoginPressed: () {
          if (mounted) {
            Navigator.pushNamed(context, '/login');
          }
        },
      ),
    );
  }
}

