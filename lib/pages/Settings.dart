// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/language.dart';
import '../services/theme_controller.dart';
import '../widgets/permission_widgets.dart';
import '../models/role_request.dart';
import '../services/firebase_service.dart';
import 'FAQPage.dart';
import 'PrivacyPolicyPage.dart';
import 'TermsConditionsPage.dart';
import 'RulesBookPage.dart';

class SettingsScreen extends StatefulWidget {
  final LocaleController ctrl;
  const SettingsScreen({super.key, required this.ctrl});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _matchNotificationsEnabled = true;
  bool _appUpdatesEnabled = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, child) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);

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
                ar ? 'الإعدادات' : 'Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    context,
                    ar ? 'الإشعارات' : 'Notifications',
                  ),
                  _buildNotificationTile(
                    context,
                    ar ? 'إشعارات المباريات' : 'Match Notifications',
                    _matchNotificationsEnabled,
                    (value) =>
                        setState(() => _matchNotificationsEnabled = value),
                  ),
                  _buildNotificationTile(
                    context,
                    ar ? 'تحديثات التطبيق' : 'App Updates',
                    _appUpdatesEnabled,
                    (value) => setState(() => _appUpdatesEnabled = value),
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildSectionTitle(context, ar ? 'الأذونات' : 'PERMISSIONS'),
                  const PermissionsSection(),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildSectionTitle(context, ar ? 'الدعم' : 'SUPPORT'),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'الأسئلة الشائعة' : 'FAQ\'s',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FAQPage(ctrl: widget.ctrl),
                      ),
                    ),
                    ar: ar,
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildSectionTitle(context, ar ? 'القانونية' : 'LEGAL'),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'سياسة الخصوصية' : 'Privacy Policy',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PrivacyPolicyPage(ctrl: widget.ctrl),
                      ),
                    ),
                    ar: ar,
                  ),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'الشروط والأحكام' : 'Terms & Conditions',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TermsConditionsPage(ctrl: widget.ctrl),
                      ),
                    ),
                    ar: ar,
                  ),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'كتاب القواعد' : 'Rules Book',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RulesBookPage(ctrl: widget.ctrl),
                      ),
                    ),
                    ar: ar,
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildSectionTitle(context, ar ? 'فريقنا' : 'OUR TEAM'),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'انضم إلينا' : 'Join Us',
                    onTap: () => _showJoinUsDialog(context, ar),
                    ar: ar,
                  ),
                  Divider(color: theme.dividerColor, height: 1),
                  _buildSectionTitle(context, ar ? 'الحساب' : 'Account'),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'تغيير اللغة' : 'Change Language',
                    onTap: () => widget.ctrl.toggle(),
                    ar: ar,
                  ),
                  _buildThemeToggleTile(context, ar),
                  _buildSettingsTile(
                    context: context,
                    title: ar ? 'تسجيل الخروج' : 'Logout',
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false),
                    ar: ar,
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required String title,
    String? value,
    bool isDestructive = false,
    required VoidCallback onTap,
    required bool ar,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.textTheme.bodyMedium?.color ?? Colors.white,
              fontSize: 16,
            ),
          ),
          trailing: value != null
              ? Text(
                  value,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                  ),
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  color:
                      theme.iconTheme.color ??
                      theme.textTheme.bodyMedium?.color?.withOpacity(0.9) ??
                      Colors.white70,
                  size: 16,
                ),
          onTap: onTap,
        ),
        Divider(color: theme.dividerColor, height: 1),
      ],
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color ?? Colors.white,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
        ),
        Divider(color: theme.dividerColor, height: 1),
      ],
    );
  }

  Widget _buildThemeToggleTile(BuildContext context, bool ar) {
    final theme = Theme.of(context);
    final themeController = context.watch<ThemeController>();

    return Column(
      children: [
        SwitchListTile(
          title: Text(
            ar ? 'الوضع الداكن' : 'Dark Mode',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color ?? Colors.white,
            ),
          ),
          subtitle: Text(
            ar
                ? (themeController.isDark ? 'مُفعَّل' : 'غير مُفعَّل')
                : (themeController.isDark ? 'Enabled' : 'Disabled'),
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          value: themeController.isDark,
          onChanged: (value) => themeController.toggle(),
          activeColor: theme.colorScheme.primary,
        ),
        Divider(color: theme.dividerColor, height: 1),
      ],
    );
  }

  void _showJoinUsDialog(BuildContext context, bool ar) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(
            ar ? 'انضم إلينا' : 'Join Us',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ar
                    ? 'اختر الدور الذي تريد التقدم له:'
                    : 'Choose the role you want to apply for:',
                style: TextStyle(
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildRoleButton(
                context,
                ar ? 'مدرب' : 'Coach',
                Icons.sports_soccer,
                () {
                  _submitRoleRequest('Coach', context, ar);
                },
              ),
              const SizedBox(height: 8),
              _buildRoleButton(
                context,
                ar ? 'منظم' : 'Organizer',
                Icons.business,
                () {
                  _submitRoleRequest('Organizer', context, ar);
                },
              ),
              const SizedBox(height: 8),
              _buildRoleButton(
                context,
                ar ? 'لاعب أكاديمية' : 'Academy Player',
                Icons.school,
                () {
                  _submitRoleRequest('academy_player', context, ar);
                },
              ),
              const SizedBox(height: 8),
              _buildRoleButton(
                context,
                ar ? 'مشرف' : 'Admin',
                Icons.admin_panel_settings,
                () {
                  _submitRoleRequest('Admin', context, ar);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                ar ? 'إلغاء' : 'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
      ),
    );
  }

  void _submitRoleRequest(String role, BuildContext context, bool ar) async {
    // Get current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'يجب تسجيل الدخول أولاً' : 'You must be logged in',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Get user data from Firestore
    final userData = await FirebaseService.instance.getUserData(user.uid);
    final userName = userData['name'] ?? user.displayName ?? 'User';
    final userEmail = user.email ?? '';

    final roleRequest = RoleRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      userName: userName,
      userEmail: userEmail,
      requestedRole: role,
      requestDate: DateTime.now(),
    );

    try {
      // Save the role request to Firebase
      await FirebaseService.instance.saveRoleRequest(roleRequest.toMap());
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar
                ? 'تم إرسال طلبك بنجاح. سيتم مراجعته من قبل المشرف.'
                : 'Your request has been submitted successfully. It will be reviewed by an admin.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'حدث خطأ أثناء إرسال الطلب' : 'Error submitting request',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
