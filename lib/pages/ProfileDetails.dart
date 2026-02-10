import 'package:flutter/foundation.dart' show Uint8List, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../services/language.dart';
import '../services/firebase_service.dart';
import '../services/cloudinary_service.dart';
import '../widgets/LogoButton.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final LocaleController ctrl;
  final String? userId;
  const ProfileDetailsScreen({super.key, required this.ctrl, this.userId});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final FirebaseService _firebaseService = FirebaseService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _userData;
  dynamic _avatarImage; // File for mobile, Uint8List for web
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  // Text controllers for editable fields
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _dobController;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _postalCodeController;
  late TextEditingController _clubController;
  late TextEditingController _walletController;

  String? _selectedGender;
  String? _selectedPosition;
  String? _selectedCountry;

  final List<String> _genderOptions = ['Male', 'Female', 'Prefer not to say'];
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
    'Midfielder',
    'Defender',
    'Forward',
    'Striker',
    'Winger',
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
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _dobController = TextEditingController();
    _cityController = TextEditingController();
    _areaController = TextEditingController();
    _postalCodeController = TextEditingController();
    _clubController = TextEditingController();
    _walletController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _postalCodeController.dispose();
    _clubController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      final targetUserId = widget.userId ?? currentUser?.uid;

      if (targetUserId != null) {
        if (kDebugMode) {
          print('👤 Loading user data for UID: $targetUserId');
        }

        final data = await _firebaseService.getUserData(targetUserId);

        // ignore: unnecessary_null_comparison
        if (kDebugMode && data != null) {
          print('📦 User data loaded successfully');
          print('📝 Position field: ${data['position']}');
          print('📝 Club field: ${data['club']}');
        }

        if (mounted) {
          setState(() {
            _userData = data;
            _isLoading = false;

            // Initialize controllers with existing data
            _usernameController.text = data['username'] ?? data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _emergencyPhoneController.text = data['emergencyPhone'] ?? '';
            _dobController.text = data['dateOfBirth'] ?? data['dob'] ?? '';
            _cityController.text = data['city'] ?? '';
            _areaController.text = data['area'] ?? '';
            _postalCodeController.text = data['postalCode'] ?? '';
            _clubController.text = data['club'] ?? '';
            // Wallet uses walletCredit field from Firebase
            final walletValue = data['walletCredit'] ?? data['wallet'] ?? 0;
            _walletController.text = walletValue.toString();

            // Handle position (check both 'position' and 'possession' fields)
            _selectedPosition = data['position'] ?? data['possession'] ?? '';
            _selectedGender = data['gender'];
            _selectedCountry = data['nationality'] ?? data['country'];

            if (kDebugMode && data['avatarUrl'] != null) {
              print('🖼️ Avatar URL found: ${data['avatarUrl']}');
            }
          });
        }
      } else {
        if (kDebugMode) print('❌ No authenticated user found');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading user data: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) print('❌ Form validation failed');
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (kDebugMode) {
          print('💾 Starting save process for user: ${user.uid}');
          print('🖼️ Local avatar file exists: ${_avatarImage != null}');
        }

        String? avatarUrl = _userData?['avatarUrl'];

        // Step 1: Upload new avatar image to Cloudinary if exists
        if (_avatarImage != null) {
          if (mounted) setState(() => _isUploadingImage = true);

          if (kDebugMode) print('📤 Uploading new avatar to Cloudinary...');

          // Show uploading message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.ctrl.isArabic
                          ? 'جاري رفع الصورة...'
                          : 'Uploading image...',
                    ),
                  ],
                ),
                duration: const Duration(seconds: 10),
              ),
            );
          }

          try {
            final userId = user.uid;
            if (_avatarImage is Uint8List) {
              // Web: upload bytes
              avatarUrl = await CloudinaryService.instance.uploadAvatar(
                imageBytes: _avatarImage as Uint8List,
                userId: userId,
              );
            } else if (_avatarImage is File) {
              // Mobile: upload file
              final bytes = await (_avatarImage as File).readAsBytes();
              avatarUrl = await CloudinaryService.instance.uploadAvatar(
                imageBytes: bytes,
                userId: userId,
              );
            }

            if (kDebugMode) {
              print('✅ Avatar uploaded to Cloudinary: $avatarUrl');
            }
            // Hide uploading message and show success
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          } catch (uploadError) {
            if (kDebugMode) print('❌ Cloudinary upload error: $uploadError');
            if (avatarUrl != null) {
              if (kDebugMode) {
                print('✅ Avatar uploaded: $avatarUrl');
              }
            } else {
              if (kDebugMode) print('❌ Firebase Storage fallback also failed');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      widget.ctrl.isArabic
                          ? 'فشل رفع الصورة'
                          : 'Failed to upload image',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                setState(() => _isUploadingImage = false);
              }
              return;
            }
          }

          if (mounted) setState(() => _isUploadingImage = false);
        }

        // Step 2: Prepare update data with all required player fields
        final updates = {
          'username': _usernameController.text.trim(),
          'name': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'emergencyPhone': _emergencyPhoneController.text.trim(),
          'dateOfBirth': _dobController.text.trim(),
          'city': _cityController.text.trim(),
          'area': _areaController.text.trim(),
          'postalCode': _postalCodeController.text.trim(),
          'gender': _selectedGender ?? 'Not specified',
          'position': _selectedPosition ?? '', // Save position field
          'possession':
              _selectedPosition ??
              '', // Also save as possession for compatibility
          'club': _clubController.text.trim(),
          // NOTE: wallet (walletCredit) is NOT updated here - it's managed by payment system
          'nationality': _selectedCountry ?? '',
          'countryFlagUrl':
              _selectedCountry != null &&
                  _countryOptions.containsKey(_selectedCountry!)
              ? 'https://flagcdn.com/w320/${_countryOptions[_selectedCountry!]}.png'
              : '',
          'avatarUrl': avatarUrl ?? _userData?['avatarUrl'] ?? '',
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Ensure all player metrics are included
        if (_userData?['metrics'] == null) {
          updates['metrics'] = {
            'PAC': 0,
            'SHO': 0,
            'PAS': 0,
            'DRI': 0,
            'DEF': 0,
            'PHY': 0,
          };
        }

        // Ensure other required player fields
        if (_userData?['goals'] == null) updates['goals'] = 0;
        if (_userData?['assists'] == null) updates['assists'] = 0;
        if (_userData?['matches'] == null) updates['matches'] = 0;
        if (_userData?['motm'] == null) updates['motm'] = 0;
        if (_userData?['level'] == null) updates['level'] = 1;
        if (_userData?['levelProgress'] == null) updates['levelProgress'] = 0.0;
        if (_userData?['rating'] == null) updates['rating'] = 0;
        if (_userData?['yellowCards'] == null) updates['yellowCards'] = 0;
        if (_userData?['redCards'] == null) updates['redCards'] = 0;

        if (kDebugMode) {
          print('📤 Saving to Firestore:');
          updates.forEach((key, value) {
            print('  $key: $value');
          });
          print('🎯 Position being saved: ${updates['position']}');
        }

        // Step 3: Update Firestore using FirebaseService
        await _firebaseService.updateUserData(user.uid, updates);

        // Step 4: Ensure player has all required fields
        await _firebaseService.ensureUserHasPlayerFields(user.uid);

        // Step 5: Reload data to refresh UI
        await _loadUserData();

        // Step 6: Clear local file and exit edit mode
        if (mounted) {
          setState(() {
            _isEditing = false;
            _isSaving = false;
            _avatarImage = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.ctrl.isArabic
                          ? 'تم حفظ التغييرات بنجاح'
                          : 'Changes saved successfully',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('User not authenticated');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error saving changes: $e');
        print('📝 Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'حدث خطأ أثناء الحفظ'
                  : 'Error saving changes',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<DateTime?> _selectDate() async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _dobController.text.isNotEmpty
            ? _parseDateOfBirth(_dobController.text)
            : DateTime.now().subtract(const Duration(days: 365 * 16)),
        firstDate: DateTime(1950),
        lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Colors.white,
                surface: Theme.of(context).cardColor,
                onSurface:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.black,
              ),
              dialogBackgroundColor: Theme.of(context).cardColor,
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          _dobController.text = '${picked.day}/${picked.month}/${picked.year}';
        });
        return picked;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error selecting date: $e');
    }
    return null;
  }

  DateTime _parseDateOfBirth(String dob) {
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error parsing date: $e');
    }
    return DateTime.now().subtract(const Duration(days: 365 * 16));
  }

  Future<void> _deleteProfilePicture() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text(
            widget.ctrl.isArabic ? 'حذف صورة الملف' : 'Delete Profile Picture',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          content: Text(
            widget.ctrl.isArabic
                ? 'هل أنت متأكد أنك تريد حذف صورة ملفك الشخصي؟'
                : 'Are you sure you want to delete your profile picture?',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(widget.ctrl.isArabic ? 'إلغاء' : 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(widget.ctrl.isArabic ? 'حذف' : 'Delete'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final user = _auth.currentUser;
      if (user != null) {
        // Update Firestore to remove avatarUrl
        await _firebaseService.updateUserData(user.uid, {'avatarUrl': ''});

        // Update local state
        setState(() {
          _avatarImage = null;
          if (_userData != null) {
            _userData!['avatarUrl'] = '';
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.ctrl.isArabic
                          ? 'تم حذف الصورة بنجاح'
                          : 'Profile picture deleted successfully',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'فشل حذف الصورة'
                  : 'Failed to delete profile picture',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile == null) {
        if (kDebugMode) print('📸 User cancelled image picker');
        return;
      }

      if (kDebugMode) {
        print('📸 Image picked: ${pickedFile.name}');
        print('📂 Path: ${pickedFile.path}');
      }

      if (mounted) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _avatarImage = bytes;
          });
          if (kDebugMode) {
            print('🖼️ Web image bytes set (${bytes.length} bytes)');
          }
        } else {
          // For mobile, use File
          final imageFile = File(pickedFile.path);
          setState(() {
            _avatarImage = imageFile;
          });
          if (kDebugMode) {
            print('🖼️ Mobile image file set');
            print('📂 File exists: ${await imageFile.exists()}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error picking image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'خطأ في اختيار الصورة'
                  : 'Error picking image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    final hasAvatar =
        _userData?['avatarUrl'] != null &&
        _userData!['avatarUrl'].toString().isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          widget.ctrl.isArabic ? 'إدارة صورة الملف' : 'Manage Profile Picture',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ctrl.isArabic ? 'اختر خياراً:' : 'Choose an option:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.photo_library),
              title: Text(
                widget.ctrl.isArabic ? 'المعرض' : 'Gallery',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.camera_alt),
              title: Text(
                widget.ctrl.isArabic ? 'الكاميرا' : 'Camera',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            if (hasAvatar)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  widget.ctrl.isArabic ? 'حذف الصورة' : 'Delete Picture',
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteProfilePicture();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.ctrl.isArabic ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    // Priority 1: Local file or bytes (during editing before save)
    if (_avatarImage != null) {
      if (_avatarImage is Uint8List) {
        if (kDebugMode) print('🖼️ Using local avatar bytes (web)');
        return MemoryImage(_avatarImage as Uint8List);
      } else if (_avatarImage is File) {
        if (kDebugMode) print('🖼️ Using local avatar file');
        return FileImage(_avatarImage as File);
      }
    }

    // Priority 2: Network URL from Firestore
    if (_userData?['avatarUrl'] != null && _userData!['avatarUrl'].isNotEmpty) {
      if (kDebugMode) {
        print('🌐 Using network avatar URL: ${_userData!['avatarUrl']}');
      }
      // Add cache-busting timestamp to force reload when image changes
      final avatarUrl = _userData!['avatarUrl'];
      final cacheBustedUrl = avatarUrl.contains('?')
          ? '$avatarUrl&t=${DateTime.now().millisecondsSinceEpoch}'
          : '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      return NetworkImage(cacheBustedUrl);
    }

    if (kDebugMode) print('👤 No avatar found, using default icon');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);
        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Localizations.override(
            context: context,
            delegates: const [DefaultMaterialLocalizations.delegate],
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                backgroundColor: theme.appBarTheme.backgroundColor,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color:
                        theme.textTheme.bodyMedium?.color ??
                        theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    if (_isEditing) {
                      setState(() => _isEditing = false);
                      _avatarImage = null;
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(
                  ar ? 'تفاصيل الملف' : 'Profile Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        theme.textTheme.displayLarge?.color ??
                        theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                actions: [
                  if (!_isEditing &&
                      (widget.userId == null ||
                          widget.userId == _auth.currentUser?.uid))
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: ar ? 'تعديل' : 'Edit',
                      onPressed: () => setState(() => _isEditing = true),
                    ),
                  if (_isEditing)
                    IconButton(
                      icon: _isSaving || _isUploadingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save),
                      tooltip: ar ? 'حفظ' : 'Save',
                      onPressed: (_isSaving || _isUploadingImage)
                          ? null
                          : _saveChanges,
                    ),
                  const LogoButton(),
                ],
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar Section
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _isEditing
                                      ? _showImagePickerDialog
                                      : null,
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    backgroundImage: _getAvatarImage(),
                                    child: _getAvatarImage() == null
                                        ? Icon(
                                            Icons.person,
                                            size: 60,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.7),
                                          )
                                        : null,
                                  ),
                                ),
                                if (_isUploadingImage)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(60),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              ar
                                                  ? 'جاري الرفع...'
                                                  : 'Uploading...',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_isEditing && !_isUploadingImage)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_userData?['avatarUrl'] != null &&
                                            _userData!['avatarUrl']
                                                .toString()
                                                .isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              right: 4,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: GestureDetector(
                                              onTap: _deleteProfilePicture,
                                              child: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: theme.colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // User Info Form
                            if (_userData != null) ...[
                              // Username
                              _buildTextField(
                                controller: _usernameController,
                                label: ar ? 'اسم المستخدم' : 'Username',
                                enabled: _isEditing,
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? (ar ? 'مطلوب' : 'Required')
                                    : null,
                              ),

                              // Email (read-only)
                              _buildReadOnlyField(
                                label: ar ? 'البريد الإلكتروني' : 'Email',
                                value:
                                    _userData!['email'] ??
                                    _auth.currentUser?.email ??
                                    '',
                              ),

                              // Phone
                              _buildTextField(
                                controller: _phoneController,
                                label: ar ? 'رقم الهاتف' : 'Phone',
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                              ),

                              // Emergency Phone
                              _buildTextField(
                                controller: _emergencyPhoneController,
                                label: ar ? 'هاتف طوارئ' : 'Emergency Phone',
                                enabled: _isEditing,
                                keyboardType: TextInputType.phone,
                              ),

                              // Date of Birth
                              _buildTextField(
                                controller: _dobController,
                                label: ar ? 'تاريخ الميلاد' : 'Date of Birth',
                                enabled: _isEditing,
                                readOnly: true,
                                onTap: _isEditing ? _selectDate : null,
                                suffixIcon: _isEditing
                                    ? Icon(
                                        Icons.calendar_today,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      )
                                    : null,
                              ),

                              // Gender
                              if (_isEditing)
                                _buildDropdownField(
                                  label: ar ? 'الجنس' : 'Gender',
                                  value: _selectedGender,
                                  items: _genderOptions,
                                  onChanged: (v) =>
                                      setState(() => _selectedGender = v),
                                  required: false,
                                )
                              else
                                _buildReadOnlyField(
                                  label: ar ? 'الجنس' : 'Gender',
                                  value: _selectedGender ?? 'Not specified',
                                ),

                              // Position (CRITICAL FIELD)
                              if (_isEditing)
                                _buildDropdownField(
                                  label: ar ? 'المركز' : 'Position',
                                  value: _selectedPosition,
                                  items: _positionOptions,
                                  onChanged: (v) =>
                                      setState(() => _selectedPosition = v),
                                  required: true,
                                )
                              else
                                _buildReadOnlyField(
                                  label: ar ? 'المركز' : 'Position',
                                  value: _selectedPosition ?? 'Not set',
                                ),

                              // Club
                              _buildTextField(
                                controller: _clubController,
                                label: ar ? 'النادي' : 'Club',
                                enabled: _isEditing,
                              ),

                              // Wallet (read-only - managed by payment system)
                              _buildReadOnlyField(
                                label: ar ? 'المحفظة' : 'Wallet',
                                value: '${_walletController.text} PFJ',
                              ),

                              // Country
                              if (_isEditing)
                                _buildDropdownField(
                                  label: ar ? 'الدولة' : 'Country',
                                  value: _selectedCountry,
                                  items: _countryOptions.keys.toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedCountry = v),
                                  required: false,
                                )
                              else
                                _buildReadOnlyField(
                                  label: ar ? 'الدولة' : 'Country',
                                  value: _selectedCountry ?? 'Not specified',
                                ),

                              // City
                              _buildTextField(
                                controller: _cityController,
                                label: ar ? 'المدينة' : 'City',
                                enabled: _isEditing,
                              ),

                              // Area
                              _buildTextField(
                                controller: _areaController,
                                label: ar ? 'المنطقة' : 'Area',
                                enabled: _isEditing,
                              ),

                              // Postal Code
                              _buildTextField(
                                controller: _postalCodeController,
                                label: ar ? 'الرمز البريدي' : 'Postal Code',
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                              ),

                              // Role (read-only)
                              _buildReadOnlyField(
                                label: ar ? 'الدور' : 'Role',
                                value: _userData!['role'] ?? 'Player',
                              ),

                              // Player Stats (read-only)
                              if (!_isEditing && _userData!['role'] == 'Player')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Text(
                                      ar ? 'الإحصائيات' : 'Statistics',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _buildStatCard(
                                          label: ar ? 'مباريات' : 'Matches',
                                          value: _userData?['matches'] ?? 0,
                                          icon: Icons.sports_soccer,
                                        ),
                                        _buildStatCard(
                                          label: ar ? 'أهداف' : 'Goals',
                                          value: _userData?['goals'] ?? 0,
                                          icon: Icons.emoji_events,
                                        ),
                                        _buildStatCard(
                                          label: ar ? 'تمريرات' : 'Assists',
                                          value: _userData?['assists'] ?? 0,
                                          icon: Icons.share,
                                        ),
                                        _buildStatCard(
                                          label: ar ? 'المستوى' : 'Level',
                                          value: _userData?['level'] ?? 1,
                                          icon: Icons.trending_up,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ] else
                              Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    ar
                                        ? 'لم يتم العثور على بيانات المستخدم'
                                        : 'User data not found',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadUserData,
                                    child: Text(
                                      ar ? 'إعادة المحاولة' : 'Retry',
                                    ),
                                  ),
                                ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: enabled
              ? theme.textTheme.bodyMedium?.color
              : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: enabled
              ? theme.cardColor
              : theme.cardColor.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;
    final validValue = (value != null && items.contains(value)) ? value : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
          ),
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        dropdownColor: theme.cardColor,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color,
          fontSize: 15,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: theme.textTheme.bodyMedium?.color,
        ),
        borderRadius: BorderRadius.circular(16),
        items: [
          if (!required)
            DropdownMenuItem(
              value: '',
              child: Text(ar ? 'غير محدد' : 'Not specified'),
            ),
          ...items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }),
        ],
        onChanged: onChanged,
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return ar ? 'مطلوب' : 'Required';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required dynamic value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
