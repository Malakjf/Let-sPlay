import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import '../services/language.dart';
import '../widgets/AnimatedButton.dart';

class SignUpPage extends StatefulWidget {
  final LocaleController ctrl;
  const SignUpPage({super.key, required this.ctrl});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  final TextEditingController _dob = TextEditingController();
  final _emerg = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _postalCode = TextEditingController();
  PhoneNumber? _regularPhone; // Store regular phone number
  final FirebaseService _firebaseService = FirebaseService.instance;
  bool _isLoading = false;
  bool _acceptedTerms = false; // Terms and conditions acceptance
  bool _isAcademyPlayer = false; // Academy player flag
  bool _obscurePassword = true; // Password visibility toggle
  bool _obscureConfirmPassword = true; // Confirm password visibility toggle
  String? _selectedGender;
  String? _selectedPosition;
  String? _selectedCountry;

  String _title(bool ar) => ar ? 'إنشاء حساب' : 'SIGN UP';
  String _sub(bool ar) => ar ? 'قم بإنشاء حسابك' : 'CREATE YOUR ACCOUNT';
  String _line(bool ar) => ar
      ? 'انضم إلى الشبكة لتتواصل مع  لاعبين آخرين.'
      : 'Join the network to connect with fellow Players.';
  String _emailL(bool ar) => ar ? 'البريد الإلكتروني' : 'Email';
  String _emailH(bool ar) => ar ? 'بريدك@example.com' : 'youremail@example.com';
  String _emailE(bool ar) => ar ? 'أدخل بريداً صحيحاً' : 'Enter a valid email';
  String _userL(bool ar) => ar ? 'اسم المستخدم' : 'Username';
  String _userH(bool ar) => ar ? 'اختر اسم مستخدم' : 'Choose a username';
  String _userE(bool ar) =>
      ar ? 'أدخل اسم المستخدم' : 'Please enter a username';
  String _phoneL(bool ar) => ar ? 'رقم الهاتف' : 'Phone Number';
  String _phoneH(bool ar) =>
      ar ? 'مثلاً +962 7XXXXXXXX' : 'e.g. +962 7XXXXXXXXX';
  String _phoneE(bool ar) => ar ? 'أدخل رقم الهاتف' : 'Please enter your phone';
  String _emergL(bool ar) => ar ? 'هاتف طوارئ' : 'Emergency Phone';
  String _emergE(bool ar) =>
      ar ? 'أدخل هاتف طوارئ' : 'Please enter emergency phone';
  String _passL(bool ar) => ar ? 'كلمة المرور' : 'Password';
  String _passH(bool ar) =>
      ar ? 'اختر كلمة مرور قوية' : 'Choose a strong password';
  String _passE(bool ar) => ar ? 'أدخل كلمة مرور' : 'Please enter a password';
  String _confirmL(bool ar) => ar ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String _confirmH(bool ar) =>
      ar ? 'أعد كتابة كلمة المرور' : 'Re-enter password';
  String _confirmE(bool ar) =>
      ar ? 'كلمة المرور غير متطابقة' : 'Passwords do not match';
  String _genderL(bool ar) => ar ? 'الجنس' : 'Gender';
  String _genderH(bool ar) => ar ? 'اختر جنسك' : 'Choose your gender';
  String _genderE(bool ar) => ar ? 'اختر جنساً' : 'Please select gender';
  String _positionL(bool ar) => ar ? 'المركز' : 'Position';
  String _positionH(bool ar) => ar ? 'اختر مركزك' : 'Choose your position';
  String _positionE(bool ar) => ar ? 'اختر مركزاً' : 'Please select position';
  String _countryL(bool ar) => ar ? 'الدولة' : 'Country';
  String _countryH(bool ar) => ar ? 'اختر دولتك' : 'Choose your country';
  String _countryE(bool ar) => ar ? 'اختر دولة' : 'Please select country';
  String _dobL(bool ar) => ar ? 'تاريخ الميلاد' : 'Date of Birth';
  String _dobH(bool ar) => ar ? 'يوم/شهر/سنة' : 'DD/MM/YYYY';
  String _dobE(bool ar) =>
      ar ? 'أدخل تاريخ ميلاد صحيح' : 'Enter a valid date of birth';
  String _cityL(bool ar) => ar ? 'المدينة' : 'City';
  String _cityH(bool ar) => ar ? 'أدخل مدينتك' : 'Enter your city';
  String _cityE(bool ar) => ar ? 'أدخل المدينة' : 'Please enter your city';
  String _areaL(bool ar) => ar ? 'المنطقة' : 'Area';
  String _areaH(bool ar) => ar ? 'أدخل منطقتك' : 'Enter your area';
  String _areaE(bool ar) => ar ? 'أدخل المنطقة' : 'Please enter your area';
  String _postalL(bool ar) => ar ? 'الرمز البريدي' : 'Postal Code';
  String _postalH(bool ar) =>
      ar ? 'أدخل رمزك البريدي' : 'Enter your postal code';
  String _postalE(bool ar) =>
      ar ? 'أدخل الرمز البريدي' : 'Please enter postal code';
  String _signup(bool ar) => ar ? 'إنشاء حساب' : 'SIGN UP';
  String _login(bool ar) => ar ? 'تسجيل الدخول' : 'LOGIN';

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _positionOptions = [
    'GK',
    'RB',
    'LB',
    'CB',
    'RCB',
    'LCB',
    'RWB',
    'LWB',
    'CDM',
    'CM',
    'CAM',
    'RM',
    'LM',
    'RW',
    'LW',
    'CF',
    'ST',
  ];

  final Map<String, String> _countryOptions = {
    'Jordan': 'jo',
    'Saudi Arabia': 'sa',
    'UAE': 'ae',
    'Egypt': 'eg',
    'Palestine': 'ps',
    'Lebanon': 'lb',
    'Iraq': 'iq',
    'Syria': 'sy',
    'Morocco': 'ma',
    'Tunisia': 'tn',
    'Algeria': 'dz',
    'Qatar': 'qa',
    'Kuwait': 'kw',
    'Bahrain': 'bh',
    'Oman': 'om',
    'Yemen': 'ye',
    'United States': 'us',
    'United Kingdom': 'gb',
    'Germany': 'de',
    'France': 'fr',
    'Spain': 'es',
    'Italy': 'it',
    'Brazil': 'br',
    'Argentina': 'ar',
  };

  @override
  void dispose() {
    _email.dispose();
    _user.dispose();
    _pass.dispose();
    _confirm.dispose();
    _dob.dispose();
    _emerg.dispose();
    _city.dispose();
    _area.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 16),
      ), // 16 years old by default
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 13),
      ), // minimum 13 years old
    );
    if (picked != null) {
      setState(() {
        _dob.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if terms are accepted
    if (!_acceptedTerms) {
      final ar = widget.ctrl.isArabic;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'يرجى قبول الشروط والأحكام للمتابعة'
                  : 'Please accept the Terms and Conditions to continue',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final ar = widget.ctrl.isArabic;
      final email = _email.text.trim();
      final username = _user.text.trim();
      final password = _pass.text.trim();

      // Validate password length (Firebase requires 6+ characters)
      if (password.length < 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar
                    ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                    : 'Password must be at least 6 characters',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Create user - Firebase will handle duplicate email errors
      debugPrint('📝 [SIGNUP UI] Starting signup process...');
      debugPrint('📝 [SIGNUP UI] Email: $email');
      debugPrint('📝 [SIGNUP UI] Username: $username');
      debugPrint('📝 [SIGNUP UI] Password length: ${password.length}');

      final userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email, password);

      debugPrint('📝 [SIGNUP UI] User credential received');

      // ✅ Check if user exists before accessing properties
      if (userCredential.user == null) {
        debugPrint('❌ [SIGNUP UI] User is null after creation');
        throw Exception('Failed to create user account');
      }

      final userId = userCredential.user?.uid;
      debugPrint('📝 [SIGNUP UI] User ID: $userId');

      if (userId == null) {
        throw Exception('User ID is null after account creation');
      }

      // Save user profile data to Firestore (username uniqueness will be handled by Firestore or app logic)
      final userData = {
        'uid': userId,
        'email': email,
        'username': username,
        'isAcademyPlayer': _isAcademyPlayer,
        'phone': _regularPhone?.number ?? '',
        'emergencyPhone': _emerg.text.trim(),
        'city': _city.text.trim(),
        'area': _area.text.trim(),
        'postalCode': _postalCode.text.trim(),
        'dateOfBirth': _dob.text,
        'gender': _selectedGender ?? 'Not specified',
        'role': _isAcademyPlayer ? 'academy_player' : 'Player',
        'metrics': _selectedPosition?.toUpperCase() == 'GK'
            ? {
                'PAS': 0, // Pass Accuracy
                'CS': 0, // Clean Sheet
                'GR': 0, // Goals Received
                'SAV': 0, // Saves
              }
            : {
                'PAC': 0, // Pace
                'SHO': 0, // Shooting
                'PAS': 0, // Passing
                'DRI': 0, // Dribbling
                'DEF': 0, // Defense
                'PHY': 0, // Physical
              },
        // Player stats - initialize with defaults
        'name': username,
        'goals': 0,
        'assists': 0,
        'motm': 0,
        'matches': 0,
        'level': 1,
        'imageUrl': '',
        'avatarUrl': '',
        'countryFlagUrl': _selectedCountry != null
            ? 'https://flagcdn.com/w320/${_countryOptions[_selectedCountry]}.png'
            : '',
        'position': _selectedPosition ?? '',
        'club': '',
        'nationality': _selectedCountry ?? '',
        'rating': 0,
        'badges': [],
        'yellowCards': 0,
        'redCards': 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await _firebaseService.saveUserData(userId, userData);

      // Show success message - app will automatically switch to authenticated state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'تم إنشاء الحساب بنجاح!' : 'Account created successfully!',
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
        // Don't navigate - let the auth state change handle it
        // The StreamBuilder in main.dart will automatically show the home page
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [SIGNUP UI] FirebaseAuthException: ${e.code}');
      debugPrint('   Message: ${e.message}');
      String message;
      switch (e.code) {
        case 'weak-password':
          message = widget.ctrl.isArabic
              ? 'كلمة المرور ضعيفة جداً'
              : 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = widget.ctrl.isArabic
              ? 'البريد الإلكتروني مستخدم بالفعل'
              : 'The account already exists for that email.';
          break;
        case 'invalid-email':
          message = widget.ctrl.isArabic
              ? 'البريد الإلكتروني غير صحيح'
              : 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = widget.ctrl.isArabic
              ? 'عملية التسجيل غير مسموحة. تأكد من تفعيل Email/Password في Firebase Console'
              : 'Email/Password sign-up is not enabled. Please enable it in Firebase Console.';
          break;
        case 'admin-restricted-operation':
          message = widget.ctrl.isArabic
              ? 'هذه العملية مقيدة. تحقق من إعدادات Firebase'
              : 'This operation is restricted. Check your Firebase settings.';
          break;
        default:
          message = widget.ctrl.isArabic
              ? 'حدث خطأ (${e.code}): ${e.message}'
              : 'Error (${e.code}): ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [SIGNUP UI] Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'حدث خطأ غير متوقع: $e'
                  : 'An unexpected error occurred: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      _title(ar),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sub(ar),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _line(ar),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Email
                    _buildTextFormField(
                      controller: _email,
                      label: _emailL(ar),
                      hint: _emailH(ar),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _emailE(ar);
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return _emailE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Username
                    _buildTextFormField(
                      controller: _user,
                      label: _userL(ar),
                      hint: _userH(ar),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _userE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: _phoneL(ar),
                        hintText: _phoneH(ar),
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        filled: true,
                        fillColor: theme.appBarTheme.backgroundColor
                            ?.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      initialCountryCode: 'JO',
                      onChanged: (phone) {
                        _regularPhone = phone;
                      },
                      validator: (v) {
                        if (v?.number.isEmpty ?? true) {
                          return _phoneE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Emergency Phone
                    IntlPhoneField(
                      decoration: InputDecoration(
                        labelText: _emergL(ar),
                        hintText: _phoneH(ar),
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        filled: true,
                        fillColor: theme.appBarTheme.backgroundColor
                            ?.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 2,
                          ),
                        ),
                      ),
                      initialCountryCode: 'JO',
                      onChanged: (phone) {
                        _emerg.text = phone.completeNumber;
                      },
                      validator: (v) {
                        if (v?.number.isEmpty ?? true) {
                          return _emergE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildTextFormField(
                      controller: _pass,
                      label: _passL(ar),
                      hint: _passH(ar),
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _passE(ar);
                        }
                        if (value.length < 6) {
                          return widget.ctrl.isArabic
                              ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
                              : 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    _buildTextFormField(
                      controller: _confirm,
                      label: _confirmL(ar),
                      hint: _confirmH(ar),
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _confirmE(ar);
                        }
                        if (value != _pass.text) {
                          return _confirmE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Selection
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: _genderL(ar),
                        hintText: _genderH(ar),
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        filled: true,
                        fillColor: theme.appBarTheme.backgroundColor
                            ?.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _genderOptions
                          .map(
                            (gender) => DropdownMenuItem(
                              value: gender,
                              child: Text(
                                gender,
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _genderE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Position Selection
                    DropdownButtonFormField<String>(
                      value: _selectedPosition,
                      decoration: InputDecoration(
                        labelText: _positionL(ar),
                        hintText: _positionH(ar),
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        filled: true,
                        fillColor: theme.appBarTheme.backgroundColor
                            ?.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _positionOptions
                          .map(
                            (position) => DropdownMenuItem(
                              value: position,
                              child: Text(
                                position,
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPosition = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _positionE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Country Selection
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: InputDecoration(
                        labelText: _countryL(ar),
                        hintText: _countryH(ar),
                        hintStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.6,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        filled: true,
                        fillColor: theme.appBarTheme.backgroundColor
                            ?.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      items: _countryOptions.keys
                          .map(
                            (country) => DropdownMenuItem(
                              value: country,
                              child: Row(
                                children: [
                                  Image.network(
                                    'https://flagcdn.com/w40/${_countryOptions[country]}.png',
                                    width: 24,
                                    height: 16,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.flag, size: 16),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    country,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _countryE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // City
                    _buildTextFormField(
                      controller: _city,
                      label: _cityL(ar),
                      hint: _cityH(ar),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _cityE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Area
                    _buildTextFormField(
                      controller: _area,
                      label: _areaL(ar),
                      hint: _areaH(ar),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _areaE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Postal Code
                    _buildTextFormField(
                      controller: _postalCode,
                      label: _postalL(ar),
                      hint: _postalH(ar),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _postalE(ar);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    InkWell(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dob,
                          readOnly: true,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          decoration: InputDecoration(
                            labelText: _dobL(ar),
                            hintText: _dobH(ar),
                            hintStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.6),
                            ),
                            labelStyle: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            prefixIcon: Icon(
                              Icons.calendar_today_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            suffixIcon: Icon(
                              Icons.arrow_drop_down,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.6),
                            ),
                            filled: true,
                            fillColor: theme.appBarTheme.backgroundColor
                                ?.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _dobE(ar);
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Academy Player Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isAcademyPlayer,
                          onChanged: (value) {
                            setState(() {
                              _isAcademyPlayer = value ?? false;
                            });
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                        Expanded(
                          child: Text(
                            ar
                                ? 'هل أنت لاعب في أكاديمية Lets Play؟'
                                : 'Are you a Lets Play Academy player?',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Terms and Conditions Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptedTerms = !_acceptedTerms;
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.8),
                                ),
                                children: [
                                  TextSpan(
                                    text: ar ? 'أوافق على ' : 'I agree to the ',
                                  ),
                                  TextSpan(
                                    text: ar
                                        ? 'الشروط والأحكام'
                                        : 'Terms and Conditions',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushNamed(context, '/terms');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    AnimatedButton(
                      text: _signup(ar),
                      onPressed: _signUp,
                      isLoading: _isLoading,
                      width: double.infinity,
                      height: 56,
                      icon: Icons.person_add,
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.ctrl.isArabic
                              ? 'لديك حساب بالفعل؟ '
                              : 'Already have an account? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.8),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (route) => false,
                            );
                          },
                          child: Text(
                            _login(ar),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
    bool isReadOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
  }) {
    final theme = Theme.of(context);
    final shouldObscure = obscureText ?? isPassword;

    return TextFormField(
      controller: controller,
      obscureText: shouldObscure,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.textTheme.bodyMedium?.color),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
        ),
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        filled: true,
        fillColor: theme.appBarTheme.backgroundColor?.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: isPassword && onToggleVisibility != null
            ? IconButton(
                icon: Icon(
                  shouldObscure ? Icons.visibility_off : Icons.visibility,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
      validator: validator,
    );
  }
}
