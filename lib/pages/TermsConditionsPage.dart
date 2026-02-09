import 'package:flutter/material.dart';
import '../services/language.dart';

class TermsConditionsPage extends StatelessWidget {
  final LocaleController ctrl;
  const TermsConditionsPage({super.key, required this.ctrl});

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
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                ar ? 'الشروط والأحكام' : 'Terms & Conditions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar
                            ? 'آخر تحديث: ديسمبر 2025'
                            : 'Last Updated: December 2025',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        ar ? '1. قبول الشروط' : '1. Acceptance of Terms',
                        ar
                            ? 'باستخدامك لتطبيق LetsPlay، فإنك توافق على الالتزام بهذه الشروط والأحكام.'
                            : 'By using the LetsPlay app, you agree to be bound by these Terms and Conditions.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '2. استخدام الخدمة' : '2. Use of Service',
                        ar
                            ? 'يجب عليك استخدام الخدمة بطريقة قانونية ومسؤولة. يُحظر أي سلوك مسيء أو احتيالي.'
                            : 'You must use the service in a legal and responsible manner. Any abusive or fraudulent behavior is prohibited.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '3. حساب المستخدم' : '3. User Account',
                        ar
                            ? 'أنت مسؤول عن الحفاظ على سرية حسابك وكلمة المرور الخاصة بك.'
                            : 'You are responsible for maintaining the confidentiality of your account and password.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '4. الدفع والمحفظة' : '4. Payment and Wallet',
                        ar
                            ? 'جميع المدفوعات نهائية وغير قابلة للاسترداد ما لم ينص على خلاف ذلك.'
                            : 'All payments are final and non-refundable unless otherwise stated.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '5. سلوك اللاعب' : '5. Player Conduct',
                        ar
                            ? 'يُتوقع من جميع اللاعبين إظهار الاحترام والروح الرياضية أثناء المباريات.'
                            : 'All players are expected to demonstrate respect and sportsmanship during matches.',
                        theme,
                      ),
                      _buildSection(
                        ar
                            ? '6. الإلغاء والاستردادات'
                            : '6. Cancellations and Refunds',
                        ar
                            ? 'يمكن إلغاء المباريات من قبل المنظمين. سيتم إرجاع الأموال إلى محفظتك في حالة الإلغاء.'
                            : 'Matches may be cancelled by organizers. Refunds will be credited to your wallet in case of cancellation.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '7. المسؤولية' : '7. Liability',
                        ar
                            ? 'LetsPlay ليست مسؤولة عن أي إصابات أو أضرار تحدث أثناء المباريات.'
                            : 'LetsPlay is not responsible for any injuries or damages that occur during matches.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '8. التعديلات' : '8. Modifications',
                        ar
                            ? 'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات.'
                            : 'We reserve the right to modify these terms at any time. You will be notified of any changes.',
                        theme,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        ar
                            ? 'للأسئلة، يرجى التواصل معنا على: legal@letsplay-app.com'
                            : 'For questions, please contact us at: legal@letsplay-app.com',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String content, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
