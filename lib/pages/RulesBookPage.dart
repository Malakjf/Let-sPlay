import 'package:flutter/material.dart';
import 'package:letsplay/widgets/App_Bottom_Nav.dart';
import '../services/language.dart';
import '../widgets/GlassContainer.dart';

class RulesBookPage extends StatelessWidget {
  final LocaleController ctrl;
  const RulesBookPage({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) {
        final ar = ctrl.isArabic;
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
                ar ? 'كتاب القواعد' : 'Rules Book',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildRuleCard(
                    Icons.sports_soccer,
                    ar ? 'قواعد اللعب' : 'Playing Rules',
                    [
                      ar
                          ? 'الوصول قبل 15 دقيقة من موعد المباراة'
                          : 'Arrive 15 minutes before match time',
                      ar
                          ? 'احترم الحكم وقراراته'
                          : 'Respect the referee and their decisions',
                      ar ? 'اللعب النظيف إلزامي' : 'Fair play is mandatory',
                      ar
                          ? 'لا عنف أو سلوك عدواني'
                          : 'No violence or aggressive behavior',
                    ],
                    theme,
                  ),
                  _buildRuleCard(
                    Icons.payment,
                    ar ? 'قواعد الدفع' : 'Payment Rules',
                    [
                      ar
                          ? 'الدفع مطلوب قبل بداية المباراة'
                          : 'Payment required before match starts',
                      ar
                          ? 'الإلغاء قبل 24 ساعة للحصول على استرداد كامل'
                          : 'Cancel 24 hours before for full refund',
                      ar
                          ? 'عدم الحضور يعني خسارة الرسوم'
                          : 'No-show means loss of fees',
                      ar
                          ? 'استخدم المحفظة للدفع السريع'
                          : 'Use wallet for quick payments',
                    ],
                    theme,
                  ),
                  _buildRuleCard(
                    Icons.person_outline,
                    ar ? 'سلوك اللاعب' : 'Player Conduct',
                    [
                      ar ? 'احترم جميع اللاعبين' : 'Respect all players',
                      ar ? 'لا تمييز بأي شكل' : 'No discrimination of any kind',
                      ar
                          ? 'اللغة المسيئة ممنوعة'
                          : 'Abusive language is prohibited',
                      ar
                          ? 'ساعد في الحفاظ على الملعب نظيفاً'
                          : 'Help keep the field clean',
                    ],
                    theme,
                  ),
                  _buildRuleCard(
                    Icons.warning_amber,
                    ar ? 'البطاقات والعقوبات' : 'Cards & Penalties',
                    [
                      ar ? 'البطاقة الصفراء: تحذير' : 'Yellow Card: Warning',
                      ar
                          ? 'بطاقتان صفراوان = بطاقة حمراء'
                          : 'Two Yellow Cards = Red Card',
                      ar
                          ? 'البطاقة الحمراء: طرد من المباراة'
                          : 'Red Card: Ejection from match',
                      ar
                          ? '3 بطاقات حمراء = إيقاف شهر'
                          : '3 Red Cards = 1 month suspension',
                    ],
                    theme,
                  ),
                  _buildRuleCard(
                    Icons.health_and_safety,
                    ar ? 'السلامة' : 'Safety',
                    [
                      ar
                          ? 'ارتدِ المعدات المناسبة'
                          : 'Wear appropriate equipment',
                      ar
                          ? 'أبلغ عن أي إصابات فوراً'
                          : 'Report any injuries immediately',
                      ar ? 'لا تلعب إذا كنت مصاباً' : 'Don\'t play if injured',
                      ar ? 'حافظ على رطوبة جسمك' : 'Stay hydrated',
                    ],
                    theme,
                  ),
                  _buildRuleCard(
                    Icons.emoji_events,
                    ar ? 'الروح الرياضية' : 'Sportsmanship',
                    [
                      ar
                          ? 'صافح الفريق الآخر قبل وبعد المباراة'
                          : 'Shake hands before and after the match',
                      ar
                          ? 'تقبل النتيجة بكرامة'
                          : 'Accept results with dignity',
                      ar ? 'شجع زملاءك في الفريق' : 'Encourage your teammates',
                      ar ? 'احتفل بطريقة محترمة' : 'Celebrate respectfully',
                    ],
                    theme,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: const AppBottomNav(index: 3),
          ),
        );
      },
    );
  }

  Widget _buildRuleCard(
    IconData icon,
    String title,
    List<String> rules,
    ThemeData theme,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...rules.map(
              (rule) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rule,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
