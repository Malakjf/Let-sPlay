import 'package:flutter/material.dart';
import '../services/language.dart';
import '../widgets/GlassContainer.dart';

class FAQPage extends StatelessWidget {
  final LocaleController ctrl;
  const FAQPage({super.key, required this.ctrl});

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
                ar ? 'الأسئلة الشائعة' : 'FAQ\'s',
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
                  _buildFAQItem(
                    context,
                    ar ? 'كيف أقوم بالتسجيل؟' : 'How do I sign up?',
                    ar
                        ? 'قم بإنشاء حساب باستخدام بريدك الإلكتروني وكلمة المرور.'
                        : 'Create an account using your email and password.',
                    theme,
                  ),
                  _buildFAQItem(
                    context,
                    ar ? 'كيف أنضم إلى مباراة؟' : 'How do I join a match?',
                    ar
                        ? 'اذهب إلى صفحة الملاعب، اختر مباراة واضغط على "انضم".'
                        : 'Go to the Fields page, select a match and tap "Join".',
                    theme,
                  ),
                  _buildFAQItem(
                    context,
                    ar
                        ? 'كيف أقوم بإضافة أموال إلى محفظتي؟'
                        : 'How do I add money to my wallet?',
                    ar
                        ? 'اذهب إلى ملفك الشخصي واضغط على "محفظتي".'
                        : 'Go to your profile and tap on "My Wallet".',
                    theme,
                  ),
                  _buildFAQItem(
                    context,
                    ar ? 'كيف أقوم بتغيير اللغة؟' : 'How do I change language?',
                    ar
                        ? 'اذهب إلى الإعدادات واضغط على "تغيير اللغة".'
                        : 'Go to Settings and tap "Change Language".',
                    theme,
                  ),
                  _buildFAQItem(
                    context,
                    ar ? 'كيف أتواصل مع الدعم؟' : 'How do I contact support?',
                    ar
                        ? 'يمكنك التواصل معنا عبر البريد الإلكتروني: support@letsplay-app.com'
                        : 'You can contact us via email: support@letsplay-app.com',
                    theme,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFAQItem(
    BuildContext context,
    String question,
    String answer,
    ThemeData theme,
  ) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: Colors.white70,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
