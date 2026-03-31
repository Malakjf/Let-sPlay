import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../services/language.dart';
import '../MapPickerScreen.dart';
import '../../services/field_store.dart';
import '../../services/cloudinary_service.dart';

class AddFieldScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic>? field; // null for new field, data for editing
  const AddFieldScreen({super.key, required this.ctrl, this.field});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  final _price = TextEditingController();
  final _surface = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<dynamic> _photos = [];
  final List<String> _amenities = [];
  final List<String> _amenityOptions = [
    'Parking',
    'Restrooms',
    'Lighting',
    'Locker Rooms',
    'Water',
    'Shower',
    'Cafeteria',
    'WiFi',
    'Air Conditioning',
    'First Aid',
  ];
  String? _selectedAmenity;

  final List<String> _surfaceOptions = [
    'Artificial Grass',
    'Natural Grass',
    'Concrete',
    'Asphalt',
    'Clay',
    'Turf',
  ];
  String? _selectedSurface;

  LatLng? _pickedLatLng;
  String? _pickedLocationLabel;

  bool _isUploading = false;
  bool _isProcessingImage = false;

  // Tab controller for managing tabs
  late TabController _tabController;
  List<Map<String, dynamic>> _allFields = [];
  bool _isLoadingFields = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadFieldData();
    _loadAllFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload fields when returning to this screen or after hot reload
    if (!_isEditing) {
      _loadAllFields();
    }
  }

  Future<void> _loadAllFields() async {
    setState(() {
      _isLoadingFields = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fields')
          .orderBy('created_at', descending: true)
          .get();

      final fields = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['__id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _allFields = fields;
          _isLoadingFields = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading fields: $e');
      if (mounted) {
        setState(() {
          _isLoadingFields = false;
        });
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _name.clear();
    _location.clear();
    _capacity.clear();
    _price.clear();
    _surface.clear();
    _photos.clear();
    _amenities.clear();
    _selectedSurface = null;
    _selectedAmenity = null;
    _pickedLatLng = null;
    _pickedLocationLabel = null;
    setState(() {});
  }

  void _loadFieldData() {
    if (widget.field != null) {
      // Load existing field data for editing
      final field = widget.field!;
      _name.text = field['name'] ?? '';
      _location.text = field['location'] ?? '';
      _capacity.text = field['capacity']?.toString() ?? '';
      _price.text = field['price']?.toString() ?? '';
      _selectedSurface = field['surface'];

      // Load coordinates
      if (field['coords'] != null) {
        final coords = field['coords'];
        if (coords is Map && coords['lat'] != null && coords['lng'] != null) {
          _pickedLatLng = LatLng(
            (coords['lat'] as num).toDouble(),
            (coords['lng'] as num).toDouble(),
          );
          _pickedLocationLabel = field['location'];
        }
      }

      // Load amenities
      if (field['amenities'] is List) {
        _amenities.addAll(
          (field['amenities'] as List).map((e) => e.toString()),
        );
      }

      // Load existing photos (as URLs from Cloudinary)
      if (field['photos'] is List) {
        _photos.addAll(field['photos'] as List);
      }
    }
  }

  bool get _isEditing => widget.field != null;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _capacity.dispose();
    _price.dispose();
    _surface.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          title: Text(
            _isEditing
                ? (ar ? 'تعديل الملعب' : 'Edit Field')
                : (ar ? 'إضافة ملعب جديد' : 'Add New Field'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          bottom: _isEditing
              ? null
              : TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: ar ? 'إضافة ملعب' : 'Add Field'),
                    Tab(text: ar ? 'الملاعب' : 'Fields'),
                  ],
                ),
          actions: const [],
        ),
        body: _isEditing
            ? _buildFormView(ar, theme)
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildFormView(ar, theme),
                  _buildFieldsList(ar, theme),
                ],
              ),
      ),
    );
  }

  Widget _buildFormView(bool ar, ThemeData theme) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                _buildHeaderSection(ar, theme),
                const SizedBox(height: 24),

                // Basic Information Section
                _buildBasicInfoSection(ar, theme),
                const SizedBox(height: 20),

                // Photos Section
                _buildPhotosSection(ar, theme),
                const SizedBox(height: 20),

                // Amenities Section
                _buildAmenitiesSection(ar, theme),
                const SizedBox(height: 32),

                // Save Button
                _buildSaveButton(ar, theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (_isUploading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.appBarTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ar ? 'جاري حفظ البيانات...' : 'Saving data...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        ar ? 'وجاري رفع الصور...' : 'and uploading images...',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFieldsList(bool ar, ThemeData theme) {
    if (_isLoadingFields) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    if (_allFields.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.stadium_outlined,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              ar ? 'لا توجد ملاعب' : 'No fields yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ar
                  ? 'ابدأ بإضافة ملعب من التبويب الأول'
                  : 'Add a field from the first tab',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllFields,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allFields.length,
        itemBuilder: (context, index) {
          final field = _allFields[index];
          return _FieldCard(
            field: field,
            ar: ar,
            theme: theme,
            onEdit: () => _editField(field),
            onDelete: () => _deleteField(field),
          );
        },
      ),
    );
  }

  void _editField(Map<String, dynamic> field) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => AddFieldScreen(ctrl: widget.ctrl, field: field),
      ),
    );
  }

  Future<void> _deleteField(Map<String, dynamic> field) async {
    final ar = widget.ctrl.isArabic;
    Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ar ? 'حذف الملعب' : 'Delete Field'),
        content: Text(
          ar
              ? 'هل أنت متأكد من حذف هذا الملعب؟'
              : 'Are you sure you want to delete this field?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final fid = (field['__id']?.toString().trim() ?? '');
        if (fid.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ar ? 'معرّف الملعب غير صالح' : 'Invalid field id',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await FirebaseFirestore.instance.collection('fields').doc(fid).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar ? 'تم حذف الملعب بنجاح' : 'Field deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadAllFields();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar ? 'فشل في حذف الملعب' : 'Failed to delete field',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildHeaderSection(bool ar, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.appBarTheme.backgroundColor?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.stadium, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            ar ? 'إنشاء ملعب جديد' : 'Create New Field',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'املأ المعلومات التالية لإضافة ملعب جديد إلى النظام'
                : 'Fill in the information below to add a new field to the system',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_photos.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    ar ? 'اختياري: إضافة صور' : 'Optional: Add photos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 4),
                  Text(
                    ar
                        ? 'الصور تحفظ في Cloudinary'
                        : 'Images saved to Cloudinary',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool ar, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'المعلومات الأساسية' : 'Basic Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Field Name
        _buildFormField(
          controller: _name,
          label: ar ? 'اسم الملعب' : 'Field Name',
          hint: ar ? 'أدخل اسم الملعب' : 'Enter field name',
          validator: (v) => v == null || v.trim().isEmpty
              ? (ar ? 'يرجى إدخال اسم الملعب' : 'Please enter field name')
              : null,
          icon: Icons.sports_soccer,
          theme: theme,
        ),
        const SizedBox(height: 16),

        // Surface Type
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar ? 'نوع السطح' : 'Surface Type',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSurface,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.appBarTheme.backgroundColor?.withOpacity(0.1),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: Icon(Icons.grass, color: theme.iconTheme.color),
              ),
              items: _surfaceOptions
                  .map(
                    (surface) =>
                        DropdownMenuItem(value: surface, child: Text(surface)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSurface = value;
                });
              },
              validator: (value) => value == null || value.isEmpty
                  ? (ar
                        ? 'يرجى اختيار نوع السطح'
                        : 'Please select surface type')
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Location with Map Picker
        _buildLocationField(ar, theme),
        const SizedBox(height: 16),

        // Capacity and Price Row
        Row(
          children: [
            Expanded(
              child: _buildFormField(
                controller: _capacity,
                label: ar ? 'السعة' : 'Capacity',
                hint: ar ? 'عدد الأشخاص' : 'People count',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return ar ? 'يرجى إدخال السعة' : 'Please enter capacity';
                  }
                  final number = int.tryParse(v);
                  if (number == null || number <= 0) {
                    return ar
                        ? 'يرجى إدخال رقم صحيح أكبر من الصفر'
                        : 'Please enter a valid number greater than 0';
                  }
                  return null;
                },
                icon: Icons.people,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormField(
                controller: _price,
                label: ar ? 'سعر الملعب' : 'Field Price',
                hint: ar ? 'د.أ' : 'JOD',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return ar ? 'يرجى إدخال السعر' : 'Please enter price';
                  }
                  final number = double.tryParse(v);
                  if (number == null || number < 0) {
                    return ar
                        ? 'يرجى إدخال رقم صحيح'
                        : 'Please enter a valid number';
                  }
                  return null;
                },
                icon: Icons.attach_money,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            prefixIcon: Icon(icon, color: theme.iconTheme.color),
            filled: true,
            fillColor: theme.appBarTheme.backgroundColor?.withOpacity(0.1),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(bool ar, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'الموقع' : 'Location',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.of(context)
                      .push<Map<String, dynamic>>(
                        MaterialPageRoute(
                          builder: (_) => MapPickerScreen(ctrl: widget.ctrl),
                        ),
                      );
                  if (result != null && result.containsKey('lat')) {
                    setState(() {
                      _pickedLatLng = LatLng(
                        result['lat'] as double,
                        result['lng'] as double,
                      );
                      if (result.containsKey('address') &&
                          result['address'] != null) {
                        _pickedLocationLabel = result['address'] as String;
                      } else if (_pickedLatLng != null) {
                        _pickedLocationLabel =
                            '${_pickedLatLng!.latitude.toStringAsFixed(6)}, ${_pickedLatLng!.longitude.toStringAsFixed(6)}';
                      }
                      if (_pickedLocationLabel != null) {
                        _location.text = _pickedLocationLabel!;
                      }
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.appBarTheme.backgroundColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedLocationLabel ??
                              (ar ? 'اختر من الخريطة' : 'Tap map to select'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (_pickedLatLng != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _pickedLatLng = null;
                              _pickedLocationLabel = null;
                              _location.clear();
                            });
                          },
                        )
                      else
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.iconTheme.color,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.map, size: 20),
              label: Text(ar ? 'خريطة' : 'Map'),
              onPressed: () async {
                final result = await Navigator.of(context)
                    .push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(ctrl: widget.ctrl),
                      ),
                    );
                if (result != null && result.containsKey('lat')) {
                  setState(() {
                    _pickedLatLng = LatLng(
                      result['lat'] as double,
                      result['lng'] as double,
                    );
                    if (result.containsKey('address') &&
                        result['address'] != null) {
                      _pickedLocationLabel = result['address'] as String;
                    } else if (_pickedLatLng != null) {
                      _pickedLocationLabel =
                          '${_pickedLatLng!.latitude.toStringAsFixed(6)}, ${_pickedLatLng!.longitude.toStringAsFixed(6)}';
                    }
                    if (_pickedLocationLabel != null) {
                      _location.text = _pickedLocationLabel!;
                    }
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotosSection(bool ar, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              ar ? 'صور الملعب' : 'Field Photos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (_photos.isNotEmpty)
              Text(
                '${_photos.length} ${ar ? 'صورة' : 'photos'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          ar ? '(اختياري)' : '(Optional)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              if (_photos.isEmpty) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library,
                        size: 32,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ar ? 'لا توجد صور' : 'No photos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        ar
                            ? '(اختياري) اضغط لإضافة صور'
                            : '(Optional) Tap to add photos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (_, i) {
                      final p = _photos[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: p is Uint8List
                                    ? Image.memory(p, fit: BoxFit.cover)
                                    : p is String
                                    ? (p.startsWith('http://') ||
                                              p.startsWith('https://'))
                                          ? Image.network(p, fit: BoxFit.cover)
                                          : (!kIsWeb
                                                ? Image.file(
                                                    File(p),
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.memory(Uint8List(0)))
                                    : null,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _photos.removeAt(i);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Photo Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhotoActionButton(
                    icon: Icons.camera_alt,
                    label: ar ? 'كاميرا' : 'Camera',
                    onPressed: _isProcessingImage || _isUploading
                        ? null
                        : () => _pickImageFromCamera(),
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  _buildPhotoActionButton(
                    icon: Icons.photo_library,
                    label: ar ? 'معرض' : 'Gallery',
                    onPressed: _isProcessingImage || _isUploading
                        ? null
                        : () => _pickImageFromGallery(),
                    theme: theme,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (_isProcessingImage || _isUploading) return;

    final ar = widget.ctrl.isArabic;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));

        if (_photos.length >= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar ? 'الحد الأقصى هو 10 صور' : 'Maximum 10 photos allowed',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final bytes = kIsWeb ? await file.readAsBytes() : null;
        setState(() {
          if (kIsWeb && bytes != null) {
            _photos.add(bytes);
          } else {
            _photos.add(file.path);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error picking image from camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'خطأ في التقاط الصورة' : 'Error capturing image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessingImage || _isUploading) return;
    final ar = widget.ctrl.isArabic;

    setState(() {
      _isProcessingImage = true;
    });

    try {
      final List<XFile> files = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (files.isNotEmpty && mounted) {
        if (_photos.length + files.length > 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ar ? 'الحد الأقصى هو 10 صور' : 'Maximum 10 photos allowed',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await Future.delayed(const Duration(milliseconds: 100));

        if (kIsWeb) {
          for (final file in files) {
            final bytes = await file.readAsBytes();
            setState(() {
              _photos.add(bytes);
            });
          }
        } else {
          setState(() {
            for (final file in files) {
              _photos.add(file.path);
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'خطأ في اختيار الصورة' : 'Error selecting image',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingImage = false;
        });
      }
    }
  }

  Future<List<String>> _uploadImagesToCloudinary() async {
    debugPrint('📤 Starting image upload to Cloudinary');
    debugPrint('📸 Total photos to upload: ${_photos.length}');

    final cloudinaryService = CloudinaryService.instance;
    final List<String> uploadedUrls = [];

    for (int i = 0; i < _photos.length; i++) {
      final photo = _photos[i];
      debugPrint('📤 Uploading image ${i + 1}/${_photos.length}');
      debugPrint('   Type: ${photo.runtimeType}');

      try {
        String? url;
        if (photo is Uint8List) {
          // Web: upload bytes directly
          debugPrint('   Mode: Web (Uint8List)');
          debugPrint('   Size: ${photo.length} bytes');
          url = await cloudinaryService.uploadFieldImage(imageBytes: photo);
        } else if (photo is String) {
          // Check if it's already a URL (existing image)
          if (photo.startsWith('http://') || photo.startsWith('https://')) {
            debugPrint('   Mode: Existing URL (skip upload)');
            url = photo; // Keep existing URL
          } else {
            // Mobile: upload file from path
            debugPrint('   Mode: Mobile (File path)');
            debugPrint('   Path: $photo');
            final bytes = await File(photo).readAsBytes();
            url = await cloudinaryService.uploadFieldImage(imageBytes: bytes);
          }
        } else {
          debugPrint('   ❌ Unknown photo type: ${photo.runtimeType}');
        }

        if (url!.isNotEmpty) {
          uploadedUrls.add(url);
          debugPrint('   ✅ Upload successful: $url');
        } else {
          debugPrint('   ⚠️ Upload failed: URL is null or empty');
        }
      } catch (e, stackTrace) {
        debugPrint('   ❌ Error uploading image: $e');
        debugPrint('   Stack trace: $stackTrace');
      }
    }

    debugPrint(
      '📤 Upload complete. Successful: ${uploadedUrls.length}/${_photos.length}',
    );
    return uploadedUrls;
  }

  Widget _buildPhotoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildAmenitiesSection(bool ar, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'المرافق' : 'Amenities',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ar ? '(اختياري)' : '(Optional)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedAmenity,
                      items: _amenityOptions
                          .map(
                            (a) => DropdownMenuItem(
                              value: a,
                              child: Text(_getAmenityText(ar, a)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedAmenity = v),
                      decoration: InputDecoration(
                        labelText: ar
                            ? 'اختر مرفق (اختياري)'
                            : 'Select amenity (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedAmenity == null
                        ? null
                        : () {
                            if (_selectedAmenity != null &&
                                !_amenities.contains(_selectedAmenity)) {
                              setState(() => _amenities.add(_selectedAmenity!));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),

              if (_amenities.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenities
                      .map(
                        (a) => Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Chip(
                            label: Text(_getAmenityText(ar, a)),
                            onDeleted: () =>
                                setState(() => _amenities.remove(a)),
                            deleteIconColor: theme.colorScheme.error,
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool ar, ThemeData theme) {
    return ElevatedButton(
      onPressed: _isUploading || _isProcessingImage ? null : _saveField,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isUploading || _isProcessingImage
            ? Colors.grey
            : theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isUploading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(Icons.save, size: 20),
          const SizedBox(width: 8),
          Text(
            _isUploading
                ? (ar ? 'جاري الحفظ...' : 'Saving...')
                : _isEditing
                ? (ar ? 'تحديث' : 'Update')
                : (ar ? 'حفظ الملعب' : 'Save Field'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getAmenityText(bool isArabic, String amenity) {
    switch (amenity.toLowerCase()) {
      case 'parking':
        return isArabic ? 'موقف سيارات' : 'Parking';
      case 'restrooms':
        return isArabic ? 'حمامات' : 'Restrooms';
      case 'lighting':
        return isArabic ? 'إضاءة' : 'Lighting';
      case 'locker rooms':
        return isArabic ? 'غرف تبديل الملابس' : 'Locker Rooms';
      case 'water':
        return isArabic ? 'مياه' : 'Water';
      case 'shower':
        return isArabic ? 'دش' : 'Shower';
      case 'cafeteria':
        return isArabic ? 'كافتيريا' : 'Cafeteria';
      case 'wifi':
        return isArabic ? 'واي فاي' : 'WiFi';
      case 'air conditioning':
        return isArabic ? 'تكييف' : 'Air Conditioning';
      case 'first aid':
        return isArabic ? 'إسعافات أولية' : 'First Aid';
      default:
        return amenity;
    }
  }

  // =========== MAIN SAVE FUNCTION ===========
  Future<void> _saveField() async {
    debugPrint('🚀 _saveField called');
    final ar = widget.ctrl.isArabic;

    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('✓ Form validation passed');
      if (_pickedLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar
                  ? 'يرجى اختيار الموقع من الخريطة'
                  : 'Please select location from map',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedSurface == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'يرجى اختيار نوع السطح' : 'Please select surface type',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        setState(() {
          _isUploading = true;
        });

        final stopwatch = Stopwatch()..start();
        debugPrint('⏱️ [AddField] Starting save process');

        List<String> photoUrls = [];

        // Only upload images if there are any
        if (_photos.isNotEmpty) {
          final t0 = stopwatch.elapsedMilliseconds;
          photoUrls = await _uploadImagesToCloudinary();
          debugPrint(
            '⏱️ [AddField] Image upload took: [32m${stopwatch.elapsedMilliseconds - t0}ms[0m',
          );
        }

        // 2. إعداد بيانات الملعب
        final Map<String, dynamic> fieldData = {
          'name': _name.text.trim(),
          'location': _location.text.trim(),
          'surface': _selectedSurface!,
          'coords': {
            'lat': _pickedLatLng!.latitude,
            'lng': _pickedLatLng!.longitude,
          },
          'capacity': int.tryParse(_capacity.text.trim()) ?? 0,
          'photos': photoUrls, // Empty array if no photos
          'amenities': _amenities.toList(),
          'price': double.tryParse(_price.text.trim()) ?? 0.0,
          'updated_at': DateTime.now().toIso8601String(),
          'has_images':
              photoUrls.isNotEmpty, // Flag to indicate if field has images
        };

        final t1 = stopwatch.elapsedMilliseconds;
        debugPrint('⏱️ [AddField] Data prep took: [32m${t1}ms[0m');

        // Check user role before saving
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          final userRole = userDoc.data()?['role'];
          debugPrint('👤 Current user role: $userRole');

          if (userRole != 'Admin' && userRole != 'Organizer') {
            throw Exception(
              ar
                  ? 'عذراً، فقط المنظمون والمسؤولون يمكنهم إضافة ملاعب'
                  : 'Sorry, only Organizers and Admins can add fields',
            );
          }
        }

        // 3. Save to Firestore
        if (_isEditing) {
          final fieldId =
              (widget.field!['id'] ?? widget.field!['__id'])
                  ?.toString()
                  .trim() ??
              '';
          if (fieldId.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ar ? 'معرّف الملعب غير صالح' : 'Invalid field id',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          await FirebaseFirestore.instance
              .collection('fields')
              .doc(fieldId)
              .update(fieldData);
        } else {
          // Add default fields for new items
          fieldData['rating'] = 0.0;
          fieldData['total_reviews'] = 0;
          fieldData['created_at'] = DateTime.now().toIso8601String();
          fieldData['is_active'] = true;
          fieldData['views'] = 0;
          fieldData['bookings_count'] = 0;

          await FieldStore.instance.addField(fieldData);
        }

        final t2 = stopwatch.elapsedMilliseconds;
        debugPrint('⏱️ [AddField] Firestore save took: [32m${t2 - t1}ms[0m');

        if (!mounted) return;

        // 4. عرض رسالة النجاح
        String successMessage = _isEditing
            ? (ar ? 'تم تحديث الملعب بنجاح' : 'Field updated successfully')
            : (ar ? 'تمت إضافة الملعب بنجاح' : 'Field added successfully');

        if (photoUrls.isNotEmpty) {
          successMessage += ar
              ? ' مع ${photoUrls.length} صورة'
              : ' with ${photoUrls.length} images';
        } else {
          successMessage += ar ? ' (بدون صور)' : ' (no images)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[300], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        successMessage,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          ar
                              ? 'تم رفع الصور إلى Cloudinary'
                              : 'Images uploaded to Cloudinary',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // 5. إعادة تحميل الملاعب من Firestore
        final t3 = stopwatch.elapsedMilliseconds;
        // await fieldsService.loadFieldsFromFirestore();
        debugPrint(
          '⏱️ [AddField] Reload fields took: [32m${stopwatch.elapsedMilliseconds - t3}ms[0m',
        );

        // 6. العودة إلى الشاشة السابقة
        if (mounted) {
          if (_isEditing) {
            Navigator.of(context).pop(fieldData);
          } else {
            // Reload fields and switch to list tab
            await _loadAllFields();
            _tabController.animateTo(1);
            _clearForm();
          }
        }
        debugPrint(
          '⏱️ [AddField] Total time: [32m${stopwatch.elapsedMilliseconds}ms[0m',
        );
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error saving field: $e');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? 'حدث خطأ في حفظ الملعب' : 'Error saving field',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }
}

class _FieldCard extends StatelessWidget {
  final Map<String, dynamic> field;
  final bool ar;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FieldCard({
    required this.field,
    required this.ar,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = field['name'] ?? (ar ? 'بدون اسم' : 'Unnamed');
    final location =
        field['location'] ?? (ar ? 'موقع غير محدد' : 'No location');
    final surface = field['surface'] ?? (ar ? 'غير محدد' : 'N/A');
    final price = field['price']?.toDouble() ?? 0.0;
    final photos = field['photos'] as List<dynamic>? ?? [];
    final rating = field['rating']?.toDouble() ?? 0.0;
    final capacity = field['capacity'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Field Image
                  if (photos.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photos.first,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.stadium,
                              size: 40,
                              color: theme.colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.stadium,
                        size: 40,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(width: 16),

                  // Field Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.grass,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              surface,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: onEdit,
                        color: theme.colorScheme.primary,
                        tooltip: ar ? 'تعديل' : 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: onDelete,
                        color: Colors.red,
                        tooltip: ar ? 'حذف' : 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Additional Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoChip(icon: Icons.people, label: '$capacity', ar: ar),
                  _InfoChip(
                    icon: Icons.star,
                    label: rating > 0
                        ? rating.toStringAsFixed(1)
                        : (ar ? 'جديد' : 'New'),
                    ar: ar,
                  ),
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: '${price.toStringAsFixed(0)} ${ar ? 'د.ل' : 'LYD'}',
                    ar: ar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool ar;

  const _InfoChip({required this.icon, required this.label, required this.ar});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
