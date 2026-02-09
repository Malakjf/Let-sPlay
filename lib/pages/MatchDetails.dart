import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/language.dart';
import '../services/matches_service.dart';
import '../utils/route_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'FieldDetails.dart';
import '../services/firebase_service.dart';
import 'players.dart';
import 'management/AddMatchScreen.dart';
import '../utils/firestore_helper.dart';
import 'management/ParticipantsManagementScreen.dart';

class MatchDetailsScreen extends StatelessWidget {
  final LocaleController ctrl;
  final String? screenSource;

  const MatchDetailsScreen({
    super.key,
    required this.ctrl,
    this.screenSource,
    required matchId,
  });

  String? get matchSubtitle => null;

  /// Get the current user's role from Firestore
  Future<String?> _getUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return null;

      final role = userDoc.data()?['role'] as String?;
      return role;
    } catch (e) {
      debugPrint('❌ Error fetching user role: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) {
        final ar = ctrl.isArabic;
        final theme = Theme.of(context);
        return _buildMatchDetailsLoader(context, ar, theme);
      },
    );
  }

  Widget _buildMatchDetailsLoader(
    BuildContext context,
    bool ar,
    ThemeData theme,
  ) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;

    if (kDebugMode) {
      _logScreenAnalytics(routeArgs);
    }

    if (routeArgs == null) {
      if (kDebugMode) {
        print('⚠️ No route arguments provided');
      }
      return _buildNoDataError(context, ar, theme, null);
    }

    if (routeArgs is Map<String, dynamic>) {
      if (routeArgs.containsKey('match') &&
          routeArgs['match'] is Map<String, dynamic>) {
        final matchData = routeArgs['match'] as Map<String, dynamic>;
        if (kDebugMode) {
          print('✅ Found match data in "match" key');
        }
        return _buildMatchDetailsWithData(
          context,
          ar,
          theme,
          matchData,
          routeArgs,
        );
      } else if (_looksLikeMatchData(routeArgs)) {
        if (kDebugMode) {
          print('✅ Arguments appear to be match data directly');
        }
        return _buildMatchDetailsWithData(
          context,
          ar,
          theme,
          routeArgs,
          routeArgs,
        );
      } else if (routeArgs.containsKey('matchId')) {
        final matchId = routeArgs['matchId'].toString();
        if (kDebugMode) {
          print('📡 Fetching match from database with ID: $matchId');
        }
        return _buildMatchDetailsWithId(context, ar, theme, matchId);
      }
    }

    if (routeArgs is String) {
      if (kDebugMode) {
        print('📡 Fetching match from database with ID: $routeArgs');
      }
      return _buildMatchDetailsWithId(context, ar, theme, routeArgs);
    }

    try {
      final matchData = RouteUtils.getRouteArg<Map<String, dynamic>>(
        context,
        'match',
      );
      if (matchData != null) {
        if (kDebugMode) {
          print('✅ Retrieved match data via RouteUtils');
        }
        return _buildMatchDetailsWithData(context, ar, theme, matchData, {
          'match': matchData,
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RouteUtils failed: $e');
      }
    }

    if (kDebugMode) {
      print('❌ No match data or ID found');
      print('ℹ️ Route arguments type: ${routeArgs.runtimeType}');
      print('ℹ️ Route arguments value: $routeArgs');
    }
    return _buildNoDataError(context, ar, theme, routeArgs);
  }

  void _logScreenAnalytics(dynamic routeArgs) {
    final analyticsData = {
      'timestamp': DateTime.now().toIso8601String(),
      'routeArgsType': routeArgs.runtimeType.toString(),
      'screenSource': screenSource,
      'hasRouteArgs': routeArgs != null,
    };

    if (routeArgs is Map) {
      analyticsData['argKeys'] = routeArgs.keys.toList();
    } else if (routeArgs is String) {
      analyticsData['argValue'] = routeArgs;
    }

    if (kDebugMode) {
      print('📱 MatchDetailsScreen Analytics:');
      analyticsData.forEach((key, value) {
        print('  $key: $value');
      });
      print('─' * 50);
    }
  }

  bool _looksLikeMatchData(Map<String, dynamic> data) {
    final requiredFields = [
      'title',
      'name',
      'date',
      'playersCount',
      'maxPlayers',
      'duration',
      'matchId',
      'id',
    ];

    final optionalFields = ['gender', 'price', 'fieldId', 'location', 'status'];

    final hasRequiredField = requiredFields.any(
      (field) => data.containsKey(field),
    );

    final hasDateAndTwoOptional =
        data.containsKey('date') &&
        optionalFields.where((field) => data.containsKey(field)).length >= 2;

    return hasRequiredField || hasDateAndTwoOptional;
  }

  Widget _buildMatchDetailsWithData(
    BuildContext context,
    bool ar,
    ThemeData theme,
    Map<String, dynamic> matchData,
    Map<String, dynamic> routeArgs,
  ) {
    if (kDebugMode) {
      print('🎯 Building match details with provided data:');
      print('📊 Data Type Analysis:');

      print(
        '🏆 Coaches: ${matchData['coaches']} (type: ${matchData['coaches']?.runtimeType})',
      );
      print(
        '👥 Organizers: ${matchData['organizers']} (type: ${matchData['organizers']?.runtimeType})',
      );

      matchData.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
    }

    if (matchData['coaches'] is String) {
      try {
        matchData['coaches'] = json.decode(matchData['coaches']);
      } catch (e) {
        if (kDebugMode) print('❌ Error parsing coaches: $e');
        matchData['coaches'] = [];
      }
    }

    if (matchData['organizers'] is String) {
      try {
        matchData['organizers'] = json.decode(matchData['organizers']);
      } catch (e) {
        if (kDebugMode) print('❌ Error parsing organizers: $e');
        matchData['organizers'] = [];
      }
    }

    final fieldData = _extractFieldData(matchData, routeArgs);

    return _buildMatchDetailsScaffold(
      context,
      ar,
      theme,
      matchData,
      fieldData,
      ctrl,
    );
  }

  Map<String, dynamic>? _extractFieldData(
    Map<String, dynamic> matchData,
    Map<String, dynamic> routeArgs,
  ) {
    final extractionChain = [
      {'source': matchData, 'key': 'fieldData'},
      {'source': matchData, 'key': 'field'},
      {'source': routeArgs, 'key': 'fieldData'},
      {'source': routeArgs, 'key': 'field'},
    ];

    for (var item in extractionChain) {
      final source = item['source'];
      final key = item['key'] as String;

      // Ensure source is a Map before accessing
      if (source is Map<String, dynamic> &&
          source.containsKey(key) &&
          source[key] is Map) {
        if (kDebugMode) {
          print(
            '✅ Found $key in ${source == matchData ? 'matchData' : 'routeArgs'}',
          );
        }
        return Map<String, dynamic>.from(source[key] as Map);
      }
    }

    if (kDebugMode) {
      print('⚠️ No field data found in any source');
    }

    return null;
  }

  Widget _buildMatchDetailsWithId(
    BuildContext context,
    bool ar,
    ThemeData theme,
    String matchId,
  ) {
    final matchesService = MatchesService();

    return FutureBuilder<Map<String, dynamic>?>(
      future: _safeGetMatch(matchesService, matchId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(context, ar, theme);
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            print('❌ Error fetching match: ${snapshot.error}');
          }
          return _buildErrorScreen(
            context,
            ar,
            theme,
            ar ? 'خطأ في تحميل المباراة' : 'Error loading match',
            _getFriendlyErrorMessage(snapshot.error, ar),
          );
        }

        final matchData = snapshot.data;
        if (matchData == null) {
          if (kDebugMode) {
            print('❌ No match found with ID: $matchId');
          }
          return _buildErrorScreen(
            context,
            ar,
            theme,
            ar ? 'لم يتم العثور على المباراة' : 'Match not found',
            'ID: $matchId',
          );
        }

        if (kDebugMode) {
          print('✅ Successfully fetched match from database');
        }

        // تحويل الحقول بعد الجلب من قاعدة البيانات
        if (matchData['coaches'] is String) {
          try {
            matchData['coaches'] = json.decode(matchData['coaches']);
          } catch (e) {
            if (kDebugMode) print('❌ Error parsing coaches: $e');
            matchData['coaches'] = [];
          }
        }

        if (matchData['organizers'] is String) {
          try {
            matchData['organizers'] = json.decode(matchData['organizers']);
          } catch (e) {
            if (kDebugMode) print('❌ Error parsing organizers: $e');
            matchData['organizers'] = [];
          }
        }

        final fieldData = _extractFieldData(matchData, {});

        return _buildMatchDetailsScaffold(
          context,
          ar,
          theme,
          matchData,
          fieldData,
          ctrl,
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _safeGetMatch(
    MatchesService service,
    String matchId,
  ) async {
    try {
      if (kDebugMode) {
        print('🔍 Attempting to fetch match with ID: $matchId');
      }

      try {
        final result = await service.getMatch(matchId);
        if (kDebugMode) {
          print('✅ Successfully fetched from MatchesService');
        }
        if (result is Map<String, dynamic>) {
          return result;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ MatchesService.getMatch failed: $e');
        }
      }

      if (kDebugMode) {
        print(
          '⚠️ MatchesService.getMatch not found, trying FirebaseService...',
        );
      }

      try {
        final firebaseService = FirebaseService.instance;
        final result = await firebaseService.getMatch(matchId);
        if (kDebugMode) {
          print('✅ Successfully fetched from FirebaseService');
        }
        if (result is Map<String, dynamic>) {
          return result;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ FirebaseService.getMatch failed: $e');
        }
      }

      if (kDebugMode) {
        print('🎮 Returning mock data for testing');
      }

      return _getMockMatchData(matchId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error in _safeGetMatch: $e');
        print('📝 Stack trace: $stackTrace');
      }
      return null;
    }
  }

  Map<String, dynamic> _getMockMatchData(String matchId) {
    return {
      'id': matchId,
      'title': 'Demo Match',
      'name': 'Demo Match',
      'pitchType': 'Outdoor',
      'gender': 'Mixed',
      'price': 75,
      'duration': 120,
      'ageFrom': 20,
      'ageTo': 45,
      'playersCount': 8,
      'maxPlayers': 16,
      'date': DateTime.now().add(const Duration(hours: 48)).toIso8601String(),
      'time': '20:00',
      'coaches': ['coach_001', 'coach_002'],
      'organizers': ['organizer_001'],
      'fieldName': 'National Stadium',
      'fieldLocation': 'Riyadh Sports City',
      'fieldData': {
        'name': 'National Stadium',
        'location': 'Riyadh Sports City',
        'surface': 'Natural Grass',
        'amenities': [
          'VIP Lounge',
          'Parking',
          'Restrooms',
          'Lighting',
          'Medical Center',
        ],
        'photos': [
          'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800',
        ],
      },
    };
  }

  String _getFriendlyErrorMessage(dynamic error, bool ar) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('not found') || errorStr.contains('does not exist')) {
      return ar ? 'المباراة غير موجودة' : 'Match does not exist';
    } else if (errorStr.contains('permission') ||
        errorStr.contains('unauthorized')) {
      return ar ? 'ليس لديك صلاحية للوصول' : 'Access denied';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return ar ? 'مشكلة في الاتصال بالشبكة' : 'Network connection error';
    } else if (errorStr.contains('timeout')) {
      return ar ? 'انتهت مهلة الاتصال' : 'Connection timeout';
    } else {
      return ar ? 'خطأ غير متوقع: $errorStr' : 'Unexpected error: $errorStr';
    }
  }

  Widget _buildLoadingScreen(BuildContext context, bool ar, ThemeData theme) {
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.textTheme.bodyMedium?.color ?? Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            ar ? 'تفاصيل المباراة' : 'Match Details',
            style: theme.textTheme.titleMedium,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                ar
                    ? 'جاري تحميل تفاصيل المباراة...'
                    : 'Loading match details...',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color ?? Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(
    BuildContext context,
    bool ar,
    ThemeData theme,
    String title,
    String details,
  ) {
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.textTheme.bodyMedium?.color ?? Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            ar ? 'تفاصيل المباراة' : 'Match Details',
            style: theme.textTheme.titleMedium,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  details,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(ar ? 'العودة' : 'Go Back'),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                MatchDetailsScreen(ctrl: ctrl, matchId: null),
                          ),
                        );
                      },
                      child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataError(
    BuildContext context,
    bool ar,
    ThemeData theme,
    dynamic routeArgs,
  ) {
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.textTheme.bodyMedium?.color ?? Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            ar ? 'تفاصيل المباراة' : 'Match Details',
            style: theme.textTheme.titleMedium,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 64),
                const SizedBox(height: 24),
                Text(
                  ar
                      ? 'لم يتم توفير بيانات المباراة'
                      : 'No match data provided',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  ar
                      ? 'يرجى تزويد معرف المباراة أو بيانات المباراة'
                      : 'Please provide match ID or match data',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? 'طرق الاستخدام:' : 'Usage Methods:',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ar
                            ? '1. معرف المباراة: "1766158080503"\n2. بيانات مباشرة: { "match": {...} }'
                            : '1. Match ID: "1766158080503"\n2. Direct data: { "match": {...} }',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(ar ? 'رجوع' : 'Go Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========== MAIN MATCH DETAILS SCAFFOLD ===========
  Widget _buildMatchDetailsScaffold(
    BuildContext context,
    bool ar,
    ThemeData theme,
    Map<String, dynamic>? match,
    Map<String, dynamic>? effectiveFieldData,
    LocaleController ctrl,
  ) {
    if (match == null) {
      return _buildNoDataError(context, ar, theme, null);
    }

    final String? pitchType = match['pitchType']?.toString();
    final String? gender = match['gender']?.toString();
    final String price = _formatNumber(match['price']);
    final String duration = _formatNumber(match['duration']);
    final String dateTime = _extractDateTime(match, ar);
    final String ageRange = _extractAgeRange(match, ar);

    int playersCount = 0;
    int maxPlayers = 0;

    if (match['playersCount'] is int) {
      playersCount = match['playersCount'];
    } else if (match['playersCount'] is String) {
      playersCount = int.tryParse(match['playersCount']) ?? 0;
    } else if (match['playersCount'] is num) {
      playersCount = (match['playersCount'] as num).toInt();
    }

    if (match['maxPlayers'] is int) {
      maxPlayers = match['maxPlayers'];
    } else if (match['maxPlayers'] is String) {
      maxPlayers = int.tryParse(match['maxPlayers']) ?? 0;
    } else if (match['maxPlayers'] is num) {
      maxPlayers = (match['maxPlayers'] as num).toInt();
    }

    final List<dynamic> coachIds = match['coaches'] is List
        ? match['coaches']
        : [];
    final List<dynamic> organizerIds = match['organizers'] is List
        ? match['organizers']
        : [];

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: theme.textTheme.bodyMedium?.color ?? Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            ar ? 'تفاصيل المباراة' : 'Match Details',
            style: theme.textTheme.titleMedium,
          ),
          centerTitle: true,
          actions: [
            FutureBuilder<String?>(
              future: _getUserRole(),
              builder: (context, snapshot) {
                final userRole = snapshot.data;
                // Only show edit button for Admin
                if (userRole?.toLowerCase() == 'admin') {
                  return IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                    ),
                    onPressed: () {
                      // Navigate to edit screen
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => AddMatchScreen(ctrl: ctrl),
                            ),
                          )
                          .then((updatedMatch) {
                            if (updatedMatch != null) {
                              // Refresh the screen with updated data
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          });
                    },
                    tooltip: ar ? 'تعديل' : 'Edit',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Header
              _buildEnhancedMatchHeader(
                context,
                ar,
                theme,
                match,
                effectiveFieldData,
                matchSubtitle,
              ),

              const SizedBox(height: 24),
              Divider(color: theme.dividerColor.withOpacity(0.16), height: 1),

              const SizedBox(height: 16),
              Text(
                ar ? 'تفاصيل المباراة' : 'Match Details',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Pitch Type
              if (pitchType != null && pitchType.isNotEmpty)
                _buildInfoRow(
                  context,
                  Icons.grid_view,
                  ar ? 'نوع الملعب' : 'Pitch Type',
                  pitchType,
                ),

              // Gender
              if (gender != null && gender.isNotEmpty)
                _buildInfoRow(
                  context,
                  Icons.people,
                  ar ? 'الجنس' : 'Gender',
                  gender,
                ),

              // Price
              if (price.isNotEmpty)
                _buildInfoRow(
                  context,
                  Icons.attach_money,
                  ar ? 'السعر للملعب شامل الضريبة' : 'Field Price Incl. tax',
                  '$price ${ar ? 'د.أ' : 'JOD'}',
                ),

              // Duration
              if (duration.isNotEmpty)
                _buildInfoRow(
                  context,
                  Icons.timer,
                  ar ? 'المدة' : 'Duration',
                  '$duration ${ar ? 'ساعة' : 'hours'}',
                ),

              // Date & Time
              if (dateTime.isNotEmpty)
                _buildInfoRow(
                  context,
                  Icons.schedule,
                  ar ? 'التاريخ والوقت' : 'Date & Time',
                  dateTime,
                ),

              // Age Range
              if (ageRange.isNotEmpty)
                _buildInfoRow(
                  context,
                  Icons.calendar_today,
                  ar ? 'العمر' : 'Age',
                  ageRange,
                ),

              // Capacity
              _buildInfoRow(
                context,
                Icons.group,
                ar ? 'السعة' : 'Capacity',
                '$playersCount / $maxPlayers ${ar ? 'لاعب' : 'players'}',
              ),

              const SizedBox(height: 24),

              // Coaches Section
              if (coachIds.isNotEmpty)
                _buildPersonSection(
                  context,
                  ar,
                  theme,
                  coachIds,
                  ar ? 'المدربون' : 'Coaches',
                  Icons.sports,
                ),

              const SizedBox(height: 16),

              // Organizers Section
              if (organizerIds.isNotEmpty)
                _buildPersonSection(
                  context,
                  ar,
                  theme,
                  organizerIds,
                  ar ? 'المنظمون' : 'Organizers',
                  Icons.people,
                ),

              // Manage Participants Button (Admin/Organizer only)
              FutureBuilder<String?>(
                future: _getUserRole(),
                builder: (context, snapshot) {
                  final role = snapshot.data?.toLowerCase();
                  if (role == 'admin' || role == 'organizer') {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.manage_accounts),
                          label: Text(
                            ar ? 'إدارة المشاركين' : 'Manage Participants',
                          ),
                          onPressed: () =>
                              _navigateToParticipantsManagement(context, match),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 24),

              // Field Details
              if (effectiveFieldData != null)
                _buildClickableFieldSection(
                  context,
                  ar,
                  theme,
                  ctrl,
                  match,
                  effectiveFieldData,
                ),

              const SizedBox(height: 24),

              // Players Section
              _buildPlayersSection(
                context,
                ar,
                theme,
                playersCount,
                maxPlayers,
              ),

              const SizedBox(height: 32),

              // Join/View Players Button
              FutureBuilder<Map<String, dynamic>>(
                future: () async {
                  final status = await _getUserMatchStatus(match);
                  final role = await _getUserRole();
                  return {'status': status, 'role': role};
                }(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final status = snapshot.data!['status'] as String;
                  final role = snapshot.data!['role'] as String?;
                  final isAdminOrCoach =
                      role?.toLowerCase() == 'admin' ||
                      role?.toLowerCase() == 'coach';

                  if (isAdminOrCoach) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          final matchId = match['matchId'] ?? match['id'];
                          if (matchId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayersScreen(
                                  ctrl: ctrl,
                                  matchId: matchId.toString(),
                                  title: ar ? 'اللاعبين' : 'Players',
                                ),
                                settings: RouteSettings(
                                  arguments: matchId.toString(),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ar ? 'عرض اللاعبين' : 'View Players',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (status != 'none') {
                    // User has some status (confirmed, pending, waiting, rejected)
                    String label;
                    Color color;

                    switch (status) {
                      case 'confirmed':
                        label = ar ? 'تم الانضمام' : 'Joined';
                        color = Colors.green;
                        break;
                      case 'waiting':
                        label = ar ? 'قائمة الانتظار' : 'Waiting List';
                        color = Colors.orange;
                        break;
                      case 'rejected':
                        label = ar ? 'مرفوض' : 'Rejected';
                        color = Colors.red;
                        break;
                      default: // pending
                        label = ar ? 'قيد الانتظار' : 'Request Pending';
                        color = Colors.blueGrey;
                    }

                    return Center(
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          disabledBackgroundColor: color,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // User is not in match - show "Join Match" button
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          _joinMatch(context, match, ar);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: playersCount >= maxPlayers
                              ? Colors.orange
                              : theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          playersCount >= maxPlayers
                              ? (ar
                                    ? 'انضم إلى قائمة الانتظار'
                                    : 'Join Waiting List')
                              : (ar ? 'انضم إلى المباراة' : 'Join Match'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToParticipantsManagement(
    BuildContext context,
    Map<String, dynamic> match,
  ) {
    final matchId = match['matchId'] ?? match['id'];
    if (matchId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ParticipantsManagementScreen(
            ctrl: ctrl,
            matchId: matchId.toString(),
          ),
        ),
      );
    }
  }

  // =========== HELPER FUNCTIONS ===========
  String _formatNumber(dynamic value) {
    if (value == null) return '';

    if (value is int) {
      return value.toString();
    } else if (value is double) {
      return value.toInt().toString();
    } else if (value is String) {
      final num? parsed = num.tryParse(value);
      return parsed?.toInt().toString() ?? value;
    } else if (value is num) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String _extractDateTime(Map<String, dynamic> match, bool ar) {
    try {
      final dateTime = parseFirestoreDate(match['date']);

      if (dateTime.millisecondsSinceEpoch != 0) {
        final months = ar
            ? [
                'يناير',
                'فبراير',
                'مارس',
                'أبريل',
                'مايو',
                'يونيو',
                'يوليو',
                'أغسطس',
                'سبتمبر',
                'أكتوبر',
                'نوفمبر',
                'ديسمبر',
              ]
            : [
                'Jan',
                'Feb',
                'Mar',
                'Apr',
                'May',
                'Jun',
                'Jul',
                'Aug',
                'Sep',
                'Oct',
                'Nov',
                'Dec',
              ];

        final month = months[dateTime.month - 1];
        final day = dateTime.day;
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');

        return '$day $month • $hour:$minute';
      }

      final date = match['date']?.toString() ?? '';
      final time = match['time']?.toString() ?? '';

      if (date.isNotEmpty && time.isNotEmpty) {
        return '$date • $time';
      } else if (date.isNotEmpty) {
        return date;
      } else if (time.isNotEmpty) {
        return time;
      }

      return ar ? 'غير محدد' : 'Not specified';
    } catch (e) {
      if (kDebugMode) print('❌ Error extracting date: $e');
      return ar ? 'غير محدد' : 'Not specified';
    }
  }

  String _extractAgeRange(Map<String, dynamic> match, bool ar) {
    try {
      final ageFrom = match['ageFrom'];
      final ageTo = match['ageTo'];

      int? fromNum;
      int? toNum;

      if (ageFrom is int) {
        fromNum = ageFrom;
      } else if (ageFrom is String) {
        fromNum = int.tryParse(ageFrom);
      } else if (ageFrom is num) {
        fromNum = ageFrom.toInt();
      }

      if (ageTo is int) {
        toNum = ageTo;
      } else if (ageTo is String) {
        toNum = int.tryParse(ageTo);
      } else if (ageTo is num) {
        toNum = ageTo.toInt();
      }

      if (fromNum != null && toNum != null) {
        return '$fromNum - $toNum ${ar ? 'سنة' : 'years'}';
      } else if (fromNum != null) {
        return '${ar ? 'من' : 'From'} $fromNum ${ar ? 'سنة' : 'years'}';
      } else if (toNum != null) {
        return '${ar ? 'إلى' : 'To'} $toNum ${ar ? 'سنة' : 'years'}';
      }

      return ar ? 'جميع الأعمار' : 'All ages';
    } catch (e) {
      if (kDebugMode) print('❌ Error extracting age range: $e');
      return ar ? 'جميع الأعمار' : 'All ages';
    }
  }

  // =========== PERSON DETAILS FUNCTIONS ===========
  Future<List<Map<String, dynamic>>> _fetchPersonDetails(
    List<dynamic> ids,
    String role,
  ) async {
    try {
      if (ids.isEmpty) return [];

      final stringIds = ids.map((id) => id.toString()).toList();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: stringIds)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name':
              data['name'] ??
              data['fullName'] ??
              data['displayName'] ??
              data['username'] ??
              'Unknown $role',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': role,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error fetching $role details: $e');
      return [];
    }
  }

  Widget _buildPersonSection(
    BuildContext context,
    bool ar,
    ThemeData theme,
    List<dynamic> personIds,
    String title,
    IconData icon,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPersonDetails(personIds, title.toLowerCase()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final persons = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...persons.map((person) {
                return InkWell(
                  onTap: () {
                    // Navigate to user profile with user ID
                    Navigator.of(context).pushNamed(
                      '/profileDetails',
                      arguments: {'userId': person['id']},
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.2),
                          radius: 22,
                          child: Text(
                            person['name'][0].toUpperCase(),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      person['name'],
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                              if (person['email']?.isNotEmpty == true ||
                                  person['phone']?.isNotEmpty == true)
                                const SizedBox(height: 6),
                              if (person['email']?.isNotEmpty == true)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email,
                                      color: Colors.grey,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        person['email'],
                                        style: TextStyle(
                                          color: theme
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              if (person['phone']?.isNotEmpty == true)
                                const SizedBox(height: 4),
                              if (person['phone']?.isNotEmpty == true)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: Colors.grey,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      person['phone'],
                                      style: TextStyle(
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchMaps(String location) async {
    final query = Uri.encodeComponent(location);
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $googleMapsUrl');
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
  }

  // =========== UI COMPONENTS ===========
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor: valueColor ?? theme.colorScheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.map,
            color: valueColor ?? theme.colorScheme.primary,
            size: 20,
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.transparent,
          child: content,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: content,
    );
  }

  Widget _buildPlayersSection(
    BuildContext context,
    bool ar,
    ThemeData theme,
    int playersCount,
    int maxPlayers,
  ) {
    final percentage = maxPlayers > 0 ? (playersCount / maxPlayers) : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                ar ? 'المشاركون' : 'Participants',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ar ? 'عدد اللاعبين الحاليين:' : 'Current players:',
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
              ),
              Text(
                '$playersCount / $maxPlayers',
                style: TextStyle(
                  color: percentage >= 1
                      ? Colors.red
                      : percentage >= 0.8
                      ? Colors.orange
                      : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage.toDouble(),
            backgroundColor: Colors.grey[800],
            color: percentage >= 1
                ? Colors.red
                : percentage >= 0.8
                ? Colors.orange
                : Colors.green,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            maxPlayers > 0
                ? '${(percentage * 100).toStringAsFixed(0)}% ${ar ? 'ممتلئ' : 'full'}'
                : ar
                ? 'سعة غير محددة'
                : 'Capacity not specified',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableFieldSection(
    BuildContext context,
    bool ar,
    ThemeData theme,
    LocaleController ctrl,
    Map<String, dynamic>? match,
    Map<String, dynamic>? field,
  ) {
    if (field == null && match?['fieldName'] == null) {
      return const SizedBox.shrink();
    }

    final fieldName = field?['name'] ?? match?['fieldName'] ?? '';
    final location = field?['location'] ?? match?['fieldLocation'] ?? '';
    final surface = field?['surface'] ?? '';
    final amenitiesList = field?['amenities'];
    final amenities = amenitiesList != null && amenitiesList is List
        ? List<String>.from(amenitiesList)
        : <String>[];

    return InkWell(
      onTap: () {
        if (field != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  FieldDetailsScreen(field: field, ctrl: ctrl),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
          color: theme.cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stadium,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ar ? 'تفاصيل الملعب' : 'Field Details',
                      style: TextStyle(
                        color: theme.textTheme.bodyLarge?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (field != null)
                  Icon(
                    Icons.chevron_right,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.54),
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (fieldName.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.badge,
                ar ? 'اسم الملعب' : 'Field Name',
                fieldName,
              ),

            if (location.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.location_on,
                ar ? 'الموقع' : 'Location',
                location,
                onTap: () => _launchMaps(location),
                valueColor: theme.colorScheme.primary,
              ),

            if (surface.isNotEmpty)
              _buildInfoRow(
                context,
                Icons.grass,
                ar ? 'السطح' : 'Surface',
                surface,
              ),

            if (amenities.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    ar ? 'المرافق:' : 'Amenities:',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.7,
                      ),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: amenities
                        .take(6)
                        .map(
                          (amenity) =>
                              _buildAmenityChip(context, amenity.toString()),
                        )
                        .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(BuildContext context, String amenity) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        amenity,
        style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
      ),
      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    );
  }

  // =========== MATCH HEADER ===========
  Widget _buildEnhancedMatchHeader(
    BuildContext context,
    bool ar,
    ThemeData theme,
    Map<String, dynamic>? match,
    Map<String, dynamic>? field,
    String? matchSubtitle,
  ) {
    Widget imageWidget = _buildDefaultLogo(context);

    try {
      final String? imageUrl = _extractFirstImageUrl(match, field);

      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageWidget = _buildNetworkImageWithCache(imageUrl, context);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading image: $e');
      }
    }

    List<String> amenities = [];
    if (match?['fieldAmenities'] != null) {
      amenities = List<String>.from(match?['fieldAmenities'] as List);
    } else if (field != null && field['amenities'] is List) {
      amenities = List<String>.from(field['amenities']);
    } else {
      amenities = ['Parking', 'Restrooms', 'Lighting'];
    }

    final matchTitle = match != null && match['title'] != null
        ? match['title'].toString()
        : (ar ? 'مباراة' : 'Match');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageWidget,
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matchTitle,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.textTheme.displayLarge?.color ?? Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                (matchSubtitle ?? (ar ? 'تفاصيل المباراة' : 'Match Details')),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.titleMedium?.color ?? Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (amenities.isNotEmpty)
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: amenities.take(4).map((a) {
                    return _buildAmenity(context, _amenityIcon(a), a);
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenity(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _amenityIcon(String amenity) {
    final lowerAmenity = amenity.toLowerCase();

    if (lowerAmenity.contains('parking') || lowerAmenity.contains('موقف')) {
      return Icons.local_parking;
    } else if (lowerAmenity.contains('restroom') ||
        lowerAmenity.contains('حمام')) {
      return Icons.wc;
    } else if (lowerAmenity.contains('light') ||
        lowerAmenity.contains('إضاءة')) {
      return Icons.lightbulb;
    } else if (lowerAmenity.contains('locker') ||
        lowerAmenity.contains('خزانة')) {
      return Icons.lock;
    } else if (lowerAmenity.contains('wifi')) {
      return Icons.wifi;
    } else if (lowerAmenity.contains('cafe') ||
        lowerAmenity.contains('كافيه')) {
      return Icons.local_cafe;
    }

    return Icons.check_circle;
  }

  String? _extractFirstImageUrl(
    Map<String, dynamic>? match,
    Map<String, dynamic>? field,
  ) {
    if (match?['fieldPhotos'] is List &&
        (match!['fieldPhotos'] as List).isNotEmpty) {
      final firstPhoto = match['fieldPhotos'].first;
      if (firstPhoto is String) return firstPhoto;
    }

    if (field?['photos'] is List && (field!['photos'] as List).isNotEmpty) {
      final firstPhoto = field['photos'].first;
      if (firstPhoto is String) return firstPhoto;
    }

    if (field?['image'] is String && (field!['image'] as String).isNotEmpty) {
      return field['image'];
    }

    return null;
  }

  Widget _buildNetworkImageWithCache(String url, BuildContext context) {
    if (url.isEmpty ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return _buildDefaultLogo(context);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoadingPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('❌ Image loading error: $error');
          }
          return _buildDefaultLogo(context);
        },
      ),
    );
  }

  Widget _buildImageLoadingPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildDefaultLogo(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 90,
        height: 90,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.sports_soccer,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            size: 40,
          ),
        ),
      ),
    );
  }

  // =========== JOIN MATCH FUNCTION ===========

  /// Checks the current user's status in the match
  Future<String> _getUserMatchStatus(Map<String, dynamic> match) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'none';
      }

      final matchId = match['matchId'] ?? match['id'];
      if (matchId == null) {
        return 'none';
      }

      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId.toString())
          .get();

      if (!matchDoc.exists) {
        return 'none';
      }

      final matchData = matchDoc.data()!;

      // Prefer new structure: check waitingList then players
      final waiting = List<Map<String, dynamic>>.from(
        matchData['waitingList'] ?? [],
      );
      final w = waiting.firstWhere(
        (p) => p['userId'] == user.uid,
        orElse: () => {},
      );
      if (w.isNotEmpty) return 'waiting';

      final currentPlayers = List<String>.from(matchData['players'] ?? []);
      if (currentPlayers.contains(user.uid)) return 'confirmed';

      // Legacy participants fallback
      final participants = List<Map<String, dynamic>>.from(
        matchData['participants'] ?? [],
      );
      final participant = participants.firstWhere(
        (p) => p['userId'] == user.uid,
        orElse: () => {},
      );
      if (participant.isNotEmpty) return participant['status'] ?? 'pending';

      return 'none';
    } catch (e) {
      debugPrint('❌ Error checking user match status: $e');
      return 'none';
    }
  }

  void _joinMatch(
    BuildContext context,
    Map<String, dynamic> match,
    bool ar,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'يجب تسجيل الدخول أولاً' : 'Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final matchId = match['id'];
      if (matchId == null) {
        debugPrint('❌ Match ID is null, cannot join match');
        return;
      }

      // Get current match data from Firestore
      final matchDoc = await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId.toString())
          .get();

      if (!context.mounted) return;

      if (!matchDoc.exists) {
        debugPrint('❌ Match not found in Firestore with ID: $matchId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'لم يتم العثور على المباراة' : 'Match not found',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final matchData = matchDoc.data()!;

      // Check capacity
      final maxPlayers = matchData['maxPlayers'] ?? 0;
      final currentCount = matchData['playersCount'] ?? 0;
      final isFull = maxPlayers > 0 && currentCount >= maxPlayers;

      // Use transactional join (adds to players or waitingList)
      await FirebaseService.instance.joinMatchTransaction(
        matchId: matchId.toString(),
        userId: user.uid,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? (isFull
                      ? 'تمت الإضافة إلى قائمة الانتظار'
                      : 'تم إرسال طلب الانضمام')
                : (isFull ? 'Added to Waiting List' : 'Join Request Sent'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh matches from Firestore to sync local cache
      debugPrint('🔄 Refreshing matches from Firestore...');
      await MatchesService().loadMatchesFromFirestore();

      if (!context.mounted) return;

      // Close screen to refresh state when reopening or just pop
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('❌ Error joining match: $e');

      if (!context.mounted) return;

      String errorMsg = ar ? 'حدث خطأ أثناء الانضمام' : 'Error joining match';
      if (e.toString().contains('User already requested')) {
        errorMsg = ar
            ? 'لقد طلبت الانضمام بالفعل'
            : 'You already requested to join';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
      );
    }
  }
}
