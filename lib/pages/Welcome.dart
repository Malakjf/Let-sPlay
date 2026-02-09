import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language.dart';
import '../services/guest_service.dart';
import '../widgets/AnimatedButton.dart';

class WelcomePage extends StatelessWidget {
  final LocaleController ctrl;
  const WelcomePage({super.key, required this.ctrl});

  String _welcome(bool ar) =>
      ar ? 'أهلاً بك في LetsPlay!' : 'Welcome to LetsPlay!';
  String _login(bool ar) => ar ? 'تسجيل الدخول' : 'Login';
  String _signUp(bool ar) => ar ? 'إنشاء حساب' : 'Sign Up';
  String _guest(bool ar) => ar ? 'المتابعة كضيف' : 'View as Guest';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, child) {
        final ar = ctrl.isArabic;
        final theme = Theme.of(context);
        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Localizations.override(
            context: context,
            delegates: const [DefaultMaterialLocalizations.delegate],
            child: Scaffold(
              body: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/bg.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/logo.png",
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _welcome(ar),
                          style: GoogleFonts.spaceGrotesk(
                            color:
                                theme.textTheme.displayLarge?.color ??
                                Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 30,
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimatedButton(
                          text: _login(ar),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          width: 280,
                          icon: Icons.login,
                        ),
                        const SizedBox(height: 20),
                        AnimatedButton(
                          text: _signUp(ar),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          width: 280,
                          icon: Icons.person_add,
                        ),
                        const SizedBox(height: 20),
                        AnimatedButton(
                          text: _guest(ar),
                          onPressed: () {
                            GuestService.setGuestMode(true);
                            Navigator.pushNamed(context, '/home');
                          },
                          width: 280,
                          icon: Icons.visibility,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
