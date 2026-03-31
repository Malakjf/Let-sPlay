import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:letsplay/services/player_attributes_store.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Add this import
import 'services/firebase_service.dart';
import 'services/firebase_options.dart';
import 'services/notification_service.dart' show NotificationService;
import 'services/language.dart';
import 'services/theme_controller.dart';
import 'services/firestore_readiness_guard.dart';
import 'utils/permissions.dart';
import 'package:letsplay/services/player_stats_store.dart';
import 'package:letsplay/services/player_metrics_store.dart';
import 'theme/theme.dart';
import 'models/player.dart';
import 'models/user_permission.dart';
import 'pages/Splash.dart';
import 'pages/Welcome.dart';
import 'pages/Login.dart';
import 'pages/SignUp.dart';
import 'pages/ForgotPassword.dart';
import 'pages/DebugFirebase.dart';
import 'pages/Fields.dart';
import 'pages/Store.dart';
import 'pages/ProfileDetails.dart';
import 'pages/Profile.dart';
import 'pages/Settings.dart';
import 'pages/players.dart';
import 'pages/MainLayout.dart';
import 'pages/Organization.dart';
import 'pages/Management.dart';
import 'pages/Notifications.dart';
import 'pages/MatchDetails.dart';
import 'pages/FAQPage.dart';
import 'pages/PrivacyPolicyPage.dart';
import 'pages/TermsConditionsPage.dart';
import 'pages/RulesBookPage.dart';
import 'pages/FutCardDemo.dart';
import 'pages/MatchesPageEnhanced.dart';
import 'pages/EditMatch.dart';

Future<T?> safeFirestore<T>(
  Future<T> Function() action, {
  int retries = 3,
}) async {
  for (int i = 0; i < retries; i++) {
    try {
      // Add timeout to prevent hanging
      return await action().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Firestore operation timed out');
        },
      );
    } on FirebaseException catch (e) {
      debugPrint('⚠️ Firestore error (attempt ${i + 1}/$retries): ${e.code}');

      // Don't retry permission errors
      if (e.code == 'permission-denied') {
        debugPrint('❌ Permission denied - check Firestore rules');
        return null;
      }

      // For network errors, wait longer between retries
      if (e.code == 'unavailable') {
        await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
      }
    } on TimeoutException catch (e) {
      debugPrint('⚠️ Timeout (attempt ${i + 1}/$retries): $e');
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
    } catch (e) {
      debugPrint('⚠️ Firestore retry ${i + 1}: $e');
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 Firebase Init
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔧 Connect to Firebase Emulators (for development)
    const useEmulators = false; // Disabled - using production Firebase
    if (kDebugMode && useEmulators) {
      debugPrint('🔧 Connecting to Firebase Emulators...');
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      debugPrint('✅ Connected to Firebase Emulators');
    }

    // Configure Firestore settings based on platform
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // Disabled for Web stability
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } else {
      // Enable persistence on mobile for offline support
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    // Explicitly enable network
    await FirebaseFirestore.instance.enableNetwork();

    debugPrint('✅ Firebase initialized');

    // Wait for Firestore handshake (non-blocking - app continues even if fails)
    FirestoreReadinessGuard.instance
        .ensureReady(timeout: const Duration(seconds: 30))
        .then((_) {
          debugPrint('✅ Firestore ready');
        })
        .catchError((e) {
          debugPrint('⚠️ Firestore handshake delayed: $e');
        });

    // Small delay to let handshake start
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('✅ App starting...');
  } catch (e) {
    debugPrint('❌ Firebase init failed: $e');
    runApp(ErrorApp(message: 'Firebase init failed:\n$e'));
    return;
  }

  /// 🔔 Notifications (optional)
  try {
    // Initialize notification service (permissions, channels)
    await NotificationService().initialize();
    // Set up listeners for FCM token changes based on auth state
    NotificationService().setupTokenListeners();
  } catch (_) {}

  final localeController = LocaleController();
  final themeController = ThemeController();

  // Initialize controllers
  await Future.wait([
    localeController.initialize(),
    themeController.initialize(),
  ]);

  runApp(
    // ✅ CORRECT: Providers are at the root, above MaterialApp.
    // This ensures they are available to ALL routes.
    MultiProvider(
      providers: [
        // Register all app-wide stores here.
        ChangeNotifierProvider(create: (_) => PlayerStatsStore()),
        ChangeNotifierProvider(create: (_) => PlayerMetricsStore()),
        ChangeNotifierProvider(create: (_) => PlayerAttributesStore()),
      ],
      child: MultiProvider(
        providers: [
          Provider<FirebaseService>(create: (_) => FirebaseService.instance),
          ChangeNotifierProvider<LocaleController>(
            create: (_) => localeController,
          ),
          ChangeNotifierProvider<ThemeController>(
            create: (_) => themeController,
          ),
        ],
        child: const LetsPlayApp(),
      ),
    ),
  );
}

/* ================= ERROR APP ================= */

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    );
  }
}

/* ================= ROOT APP ================= */

class LetsPlayApp extends StatelessWidget {
  const LetsPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LetsPlay',

      locale: localeCtrl.locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: createThemeData(AppTheme.light, isDark: false),
      darkTheme: createThemeData(AppTheme.dark, isDark: true),
      themeMode: themeCtrl.themeMode,

      ///  Always start with the Splash Page.
      home: const SplashPage(),

      /// 🧭 Routes
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
          case '/home':
            return MaterialPageRoute(
              builder: (_) => MainLayout(ctrl: localeCtrl),
            );
          case '/splash':
            return MaterialPageRoute(
              builder: (_) => FootballSplashAnimation(
                onComplete: () {},
                appName: 'LetsPlay',
              ),
            );
          case '/welcome':
            return MaterialPageRoute(
              builder: (_) => WelcomePage(ctrl: localeCtrl),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(ctrl: localeCtrl),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (_) => SignUpPage(ctrl: localeCtrl),
            );
          case '/forgotPassword':
            return MaterialPageRoute(
              builder: (_) => ForgotPasswordPage(ctrl: localeCtrl),
            );
          case '/debug':
            return MaterialPageRoute(
              builder: (_) => DebugFirebasePage(ctrl: localeCtrl),
            );
          case '/fields':
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return MaterialPageRoute(
                builder: (_) => LoginScreen(ctrl: localeCtrl),
              );
            }
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<Map<String, dynamic>>(
                future: loadProfileSafe(context, user.uid),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return FieldsScreen(
                    ctrl: localeCtrl,
                    userPermission: permissionFromRole(
                      snap.data!['permissionLevel'] ?? snap.data!['role'],
                    ),
                  );
                },
              ),
            );
          case '/store':
            return MaterialPageRoute(
              builder: (_) => StorePage(ctrl: localeCtrl),
            );
          case '/profile':
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              return MaterialPageRoute(
                builder: (_) => LoginScreen(ctrl: localeCtrl),
              );
            }
            // Use a custom PageRoute to handle the async loading and provider wrapping.
            return MaterialPageRoute(
              builder: (context) {
                // This `context` has access to the root providers.
                return FutureBuilder<Map<String, dynamic>>(
                  future: loadProfileSafe(context, user.uid),
                  builder: (futureBuilderContext, snap) {
                    if (!snap.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ProfileScreen(
                      ctrl: localeCtrl,
                      player: snap.data!['player'],
                      userPermission: permissionFromRole(
                        snap.data!['permissionLevel'] ?? snap.data!['role'],
                      ),
                    );
                  },
                );
              },
            );
          case '/profileDetails':
            final args = settings.arguments as Map<String, dynamic>?;
            final userId = args?['userId'] as String?;
            return MaterialPageRoute(
              builder: (_) =>
                  ProfileDetailsScreen(ctrl: localeCtrl, userId: userId),
            );
          case '/settings':
            return MaterialPageRoute(
              builder: (_) => SettingsScreen(ctrl: localeCtrl),
            );
          case '/players':
            String? matchId;
            if (settings.arguments != null) {
              if (settings.arguments is String) {
                matchId = settings.arguments as String;
              } else if (settings.arguments is int) {
                matchId = (settings.arguments as int).toString();
              }
            }

            if (matchId == null || matchId.isEmpty) {
              // Show matches page when no matchId provided
              return MaterialPageRoute(
                builder: (_) => MatchesPageEnhanced(
                  ctrl: localeCtrl,
                  userPermission: UserPermission.player,
                ),
              );
            }

            final nonNullMatchId = matchId;
            return MaterialPageRoute(
              builder: (_) =>
                  PlayersScreen(ctrl: localeCtrl, matchId: nonNullMatchId),
            );

          case '/fut-card-demo':
            return MaterialPageRoute(builder: (_) => const FutCardDemoPage());

          case '/organization':
            return MaterialPageRoute(
              builder: (_) => OrganizationPage(ctrl: localeCtrl),
            );
          case '/management':
            return MaterialPageRoute(
              builder: (_) => ManagementScreen(ctrl: localeCtrl),
            );
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          case '/matchDetails':
            return MaterialPageRoute(
              builder: (_) =>
                  MatchDetailsScreen(ctrl: localeCtrl, matchId: null),
              settings:
                  settings, // Pass through route settings to preserve arguments
            );
          case '/faq':
            return MaterialPageRoute(builder: (_) => FAQPage(ctrl: localeCtrl));
          case '/privacy':
            return MaterialPageRoute(
              builder: (_) => PrivacyPolicyPage(ctrl: localeCtrl),
            );
          case '/terms':
            return MaterialPageRoute(
              builder: (_) => TermsConditionsPage(ctrl: localeCtrl),
            );
          case '/rules':
            return MaterialPageRoute(
              builder: (_) => RulesBookPage(ctrl: localeCtrl),
            );
          case '/editMatch':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => EditMatchPage(ctrl: localeCtrl, match: args),
            );
        }
        return null;
      },
    );
  }
}

/* ================= PROFILE SAFE LOADER ================= */

Future<Map<String, dynamic>> loadProfileSafe(
  BuildContext context,
  String userId,
) async {
  try {
    debugPrint('📥 Loading profile for user: $userId');

    final firebaseService = context.read<FirebaseService>();

    // Try to ensure user has fields (non-critical)
    try {
      await firebaseService.ensureUserHasPlayerFields(userId);
    } catch (e) {
      debugPrint('⚠️ Could not ensure user fields: $e');
    }

    // Get user data
    final data = await firebaseService.getUserData(userId);

    if (data.isEmpty) {
      debugPrint('⚠️ No user data found, using defaults');
      return {'player': _defaultPlayer(), 'role': 'Player'};
    }

    debugPrint('✅ User data loaded: ${data.keys.join(", ")}');

    // Get role - Fix the role detection
    String role = data['role']?.toString() ?? 'Player';
    final permissionLevel = data['permissionLevel']?.toString();
    debugPrint('👤 Raw role from Firestore: "$role"');

    // Normalize role casing
    role = role.trim(); // Remove any whitespace
    if (role.toLowerCase() == 'admin') role = 'Admin';
    if (role.toLowerCase() == 'organizer') role = 'Organizer';
    if (role.toLowerCase() == 'coach') role = 'Coach';
    if (role.toLowerCase() == 'academy_player' ||
        role.toLowerCase() == 'academy player') {
      role = 'Academy Player';
    }

    debugPrint('👤 Normalized role: "$role"');

    final permission = permissionFromRole(permissionLevel ?? role);
    debugPrint('🔑 Permission granted: $permission');

    return {
      'player': Player(
        id: userId,
        name: data['name'] ?? data['username'] ?? 'Player',
        goals: FirebaseService.safeInt(data['goals']),
        assists: FirebaseService.safeInt(data['assists']),
        motm: FirebaseService.safeInt(data['motm']),
        matches: FirebaseService.safeInt(data['matches']),
        level: FirebaseService.safeInt(data['level'], 1),
        metrics: _getMetrics(data),
        imageUrl: data['avatarUrl'] ?? '',
        countryFlagUrl: data['countryFlagUrl'] ?? '',
        position: data['position'] ?? '',
        club: data['club'] ?? '',
        nationality: data['nationality'] ?? '',
        rating: FirebaseService.safeInt(data['rating']),
        badges: (data['badges'] is List)
            ? List<String>.from(data['badges'])
            : [],
        yellowCards: FirebaseService.safeInt(data['yellowCards']),
        redCards: FirebaseService.safeInt(data['redCards']),
      ),
      'role': role,
    };
  } catch (e, stackTrace) {
    debugPrint('❌ Error loading profile: $e');
    debugPrint('Stack trace: $stackTrace');
    return {'player': _defaultPlayer(), 'role': 'Player'};
  }
}

/* ================= HELPERS ================= */

Map<String, int> _getMetrics(Map<String, dynamic> data) {
  if (data['metrics'] is Map) {
    final metrics = Map<String, dynamic>.from(data['metrics']);
    return metrics.map(
      (key, value) => MapEntry(key, FirebaseService.safeInt(value)),
    );
  }
  return {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0};
}

Player _defaultPlayer() => Player(
  id: '',
  name: 'Player',
  goals: 0,
  assists: 0,
  motm: 0,
  matches: 0,
  level: 1,
  metrics: {'PAC': 0, 'SHO': 0, 'PAS': 0, 'DRI': 0, 'DEF': 0, 'PHY': 0},
  imageUrl: '',
  countryFlagUrl: '',
  position: '',
  club: '',
  nationality: '',
  rating: 0,
  badges: [],
  yellowCards: 0,
  redCards: 0,
);
