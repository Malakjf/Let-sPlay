import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:letsplay/services/firebase_options.dart';
import '../services/language.dart';

class DebugFirebasePage extends StatelessWidget {
  final LocaleController ctrl;
  const DebugFirebasePage({super.key, required this.ctrl});

  Future<Map<String, dynamic>> _gatherInfo() async {
    final info = <String, dynamic>{};
    try {
      info['defaultOptions_projectId'] =
          DefaultFirebaseOptions.currentPlatform.projectId;
    } catch (e) {
      info['defaultOptions_projectId'] = 'unavailable: $e';
    }

    try {
      info['apps_count'] = Firebase.apps.length;
      final app = Firebase.apps.isNotEmpty ? Firebase.app() : null;
      if (app != null) {
        info['app_name'] = app.name;
        info['app_projectId'] = app.options.projectId;
        info['app_apiKey'] = app.options.apiKey;
        info['app_appId'] = app.options.appId;
      }
    } catch (e) {
      info['apps_error'] = e.toString();
    }

    return info;
  }

  @override
  Widget build(BuildContext context) {
    final ar = ctrl.isArabic;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('Firebase Debug')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _gatherInfo(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final info = snap.data ?? {};
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎯 FUT Card Demo Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF64B5F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF64B5F6),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.sports_soccer,
                            size: 48,
                            color: Color(0xFF64B5F6),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '🏆 FUT Card System Demo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Test all FIFA-style animations & features',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/fut-card-demo'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Open Demo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Firebase Configuration:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...info.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: SelectableText('${e.key}: ${e.value}'),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
