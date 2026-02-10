import 'package:flutter/material.dart';
import '../services/language.dart';
import 'management/AddFieldScreen.dart';
import 'management/AddMatchScreen.dart';
import 'management/AddItemScreen.dart';
import 'management/UserManager.dart';
import 'management/ReportsScreen.dart';
import 'management/AreasStatisticsPage.dart';
import '../widgets/GlassContainer.dart';

class ManagementScreen extends StatelessWidget {
  final LocaleController ctrl;
  const ManagementScreen({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) => Directionality(
        textDirection: ctrl.isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Localizations.override(
          context: context,
          delegates: const [DefaultMaterialLocalizations.delegate],
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor,
              title: Text(
                ctrl.isArabic ? 'إدارة' : 'Management',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
              centerTitle: true,
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ctrl.isArabic ? ' الإدارة' : 'Management Options',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.add_location_outlined,
                        color: theme.iconTheme.color,
                      ),
                      title: Text(
                        ctrl.isArabic ? 'إضافة ملعب' : 'Add Field',
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.iconTheme.color,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddFieldScreen(ctrl: ctrl),
                        ),
                      ),
                    ),
                  ),
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.person_search_outlined,
                        color: theme.iconTheme.color,
                      ),
                      title: Text(
                        ctrl.isArabic ? 'إضافة مباراة' : 'Add Match',
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.iconTheme.color,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddMatchScreen(ctrl: ctrl),
                        ),
                      ),
                    ),
                  ),
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.add_shopping_cart_outlined,
                        color: theme.iconTheme.color,
                      ),
                      title: Text(
                        ctrl.isArabic
                            ? 'إضافة منتج للمتجر'
                            : 'Add Item to Store',
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.iconTheme.color,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddItemScreen(ctrl: ctrl),
                        ),
                      ),
                    ),
                  ),
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.analytics_outlined,
                        color: theme.iconTheme.color,
                      ),
                      title: Text(
                        ctrl.isArabic
                            ? 'التقارير المالية'
                            : 'Financial Reports',
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.iconTheme.color,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportsScreen(ctrl: ctrl),
                        ),
                      ),
                    ),
                  ),
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.group_outlined,
                        color: theme.iconTheme.color,
                      ),
                      title: Text(
                        ctrl.isArabic ? 'إدارة المستخدمين' : 'USERS',
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.iconTheme.color,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserManagerScreen(ctrl: ctrl),
                        ),
                      ),
                    ),
                  ),
                  GlassCard(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        Icons.analytics_outlined,
                        color: theme.iconTheme.color,
                      ),
                      title: Text(
                        ctrl.isArabic ? 'إحصائيات المناطق' : 'Areas Statistics',
                        style: theme.textTheme.titleMedium,
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.iconTheme.color,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AreasStatisticsPage(ctrl: ctrl),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
