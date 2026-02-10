import 'package:flutter/material.dart';
import '../services/language.dart';
import '../widgets/App_Bottom_Nav.dart' show AppBottomNav;
import '../widgets/GlassContainer.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final LocaleController ctrl;
  const PrivacyPolicyPage({super.key, required this.ctrl});

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
                ar ? 'سياسة الخصوصية' : 'Privacy Policy',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: GlassContainer(
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
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        ar ? '1. جمع المعلومات' : '1. Information Collection',
                        ar
                            ? 'نقوم بجمع المعلومات الشخصية التي تقدمها عند التسجيل، بما في ذلك الاسم والبريد الإلكتروني ورقم الهاتف.'
                            : 'We collect personal information you provide during registration, including name, email, and phone number.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '2. استخدام المعلومات' : '2. Use of Information',
                        ar
                            ? 'نستخدم معلوماتك لتوفير خدماتنا، تحسين تجربتك، والتواصل معك بخصوص المباريات والأحداث.'
                            : 'We use your information to provide our services, improve your experience, and communicate with you about matches and events.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '3. حماية البيانات' : '3. Data Protection',
                        ar
                            ? 'نحن ملتزمون بحماية بياناتك الشخصية باستخدام تدابير أمنية متقدمة.'
                            : 'We are committed to protecting your personal data using advanced security measures.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '4. مشاركة المعلومات' : '4. Information Sharing',
                        ar
                            ? 'لن نشارك معلوماتك الشخصية مع أطراف ثالثة دون موافقتك الصريحة.'
                            : 'We will not share your personal information with third parties without your explicit consent.',
                        theme,
                      ),
                      _buildSection(
                        ar ? '5. حقوقك' : '5. Your Rights',
                        ar
                            ? 'لديك الحق في الوصول إلى بياناتك الشخصية، تصحيحها، أو حذفها في أي وقت.'
                            : 'You have the right to access, correct, or delete your personal data at any time.',
                        theme,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        ar
                            ? 'للأسئلة أو الاستفسارات، يرجى التواصل معنا على: privacy@letsplay-app.com'
                            : 'For questions or inquiries, please contact us at: privacy@letsplay-app.com',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: const AppBottomNav(index: 3),
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
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
