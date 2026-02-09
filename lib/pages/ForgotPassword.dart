import 'package:flutter/material.dart';
import '../services/language.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  final LocaleController ctrl;
  const ForgotPasswordPage({super.key, required this.ctrl});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  String _title(bool ar) => ar ? 'استرجاع كلمة المرور' : 'FORGOT PASSWORD';
  String _sub(bool ar) =>
      ar ? 'أعد تعيين كلمة المرور الخاصة بك' : 'RESET YOUR PASSWORD';
  String _line(bool ar) => ar
      ? 'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور.'
      : 'Enter your email address and we will send you a link to reset your password.';
  String _emailL(bool ar) => ar ? 'البريد الإلكتروني' : 'Email';
  String _emailH(bool ar) => ar ? 'بريدك@example.com' : 'youremail@example.com';
  String _emailE(bool ar) =>
      ar ? 'يرجى إدخال بريد إلكتروني صحيح' : 'Please enter a valid email';
  String _btn(bool ar) => ar ? 'إرسال رابط المساعدة' : 'SEND RESET LINK';
  String _back(bool ar) => ar ? 'العودة إلى تسجيل الدخول' : 'BACK TO LOGIN';
  String _success(bool ar) => ar
      ? 'تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني'
      : 'Password reset link sent to your email!';
  String _checkEmail(bool ar) => ar
      ? 'يرجى التحقق من بريدك الإلكتروني واتبع التعليمات لإعادة تعيين كلمة المرور.'
      : 'Please check your email and follow the instructions to reset your password.';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email.text.trim(),
      );

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_success(widget.ctrl.isArabic)),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = widget.ctrl.isArabic
              ? 'لا يوجد حساب بهذا البريد الإلكتروني'
              : 'No account found with this email.';
          break;
        case 'invalid-email':
          message = widget.ctrl.isArabic
              ? 'البريد الإلكتروني غير صحيح'
              : 'Invalid email address.';
          break;
        case 'too-many-requests':
          message = widget.ctrl.isArabic
              ? 'حاولت عدة مرات. يرجى المحاولة لاحقاً'
              : 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'An error occurred. Please try again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() => _isLoading = false);
    }
  }

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
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.textTheme.bodyMedium?.color ?? Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Language toggle
                      Align(
                        alignment: Alignment.topCenter,
                        child: InkWell(
                          onTap: widget.ctrl.toggle,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              ar ? 'EN' : 'عربي',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Image.asset(
                        "assets/images/logo.png",
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _title(ar),
                        style: const TextStyle(
                          fontFamily: 'Robuck',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _sub(ar),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _line(ar),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      if (_emailSent)
                        // Success state
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 48,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _success(ar),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _checkEmail(ar),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                ),
                                child: Text(_back(ar)),
                              ),
                            ),
                          ],
                        )
                      else
                        // Form state
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _email,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.email,
                                    color: Colors.white70,
                                  ),
                                  labelText: _emailL(ar),
                                  hintText: _emailH(ar),
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: const BorderSide(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return _emailE(ar);
                                  }
                                  final emailRegex = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(v.trim())) {
                                    return _emailE(ar);
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 25),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _sendResetEmail,
                                  child: _isLoading
                                      ? const CircularProgressIndicator()
                                      : Text(_btn(ar)),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                ),
                                child: Text(
                                  _back(ar),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
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
}
