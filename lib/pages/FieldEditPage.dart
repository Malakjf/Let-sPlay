// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/field.dart';
import '../services/field_repository.dart';
import '../services/cloudinary_service.dart';
import '../services/language.dart';
import 'package:image_picker/image_picker.dart';

/// Page for adding or editing a field/stadium
class FieldEditPage extends StatefulWidget {
  final LocaleController ctrl;
  final Field? field; // null for new field

  const FieldEditPage({super.key, required this.ctrl, this.field});

  @override
  State<FieldEditPage> createState() => _FieldEditPageState();
}

class _FieldEditPageState extends State<FieldEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fieldRepo = FieldRepository.instance;
  final _cloudinary = CloudinaryService.instance;
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  List<String> _imageUrls = [];
  bool _isAvailable = true;
  String? _fieldType;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final List<String> _fieldTypes = ['5-a-side', '7-a-side', '11-a-side'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.field?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.field?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.field?.location ?? '',
    );
    _priceController = TextEditingController(
      text: widget.field?.pricePerHour.toString() ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.field?.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.field?.longitude?.toString() ?? '',
    );
    _imageUrls = List.from(widget.field?.images ?? []);
    _isAvailable = widget.field?.isAvailable ?? true;
    _fieldType = widget.field?.fieldType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.field != null;

  Future<void> _addImage() async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      // Upload to Cloudinary
      final imageUrl = await _cloudinary.uploadFieldImage(imageBytes: bytes);

      if (mounted) {
        setState(() {
          _imageUrls.add(imageUrl);
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic ? 'تم إضافة الصورة' : 'Image added',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'فشل تحميل الصورة'
                  : 'Failed to upload image',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(String imageUrl) async {
    final ar = widget.ctrl.isArabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'حذف الصورة' : 'Delete Image'),
        content: Text(
          ar
              ? 'هل أنت متأكد من حذف هذه الصورة؟'
              : 'Are you sure you want to remove this image?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(ar ? 'حذف' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _imageUrls.remove(imageUrl);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic ? 'تم حذف الصورة' : 'Image removed',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _saveField() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final location = _locationController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final latitude = double.tryParse(_latitudeController.text.trim());
      final longitude = double.tryParse(_longitudeController.text.trim());

      if (_isEditing) {
        // Update existing field
        final updatedField = widget.field!.copyWith(
          name: name,
          description: description,
          location: location,
          latitude: latitude,
          longitude: longitude,
          images: _imageUrls,
          pricePerHour: price,
          isAvailable: _isAvailable,
          fieldType: _fieldType,
          updatedAt: DateTime.now(),
        );

        await _fieldRepo.updateField(updatedField);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.ctrl.isArabic
                    ? 'تم تحديث الملعب'
                    : 'Field updated successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Create new field
        final newField = Field(
          id: '', // Will be set by Firestore
          name: name,
          description: description,
          location: location,
          latitude: latitude,
          longitude: longitude,
          images: _imageUrls,
          pricePerHour: price,
          isAvailable: _isAvailable,
          fieldType: _fieldType,
          createdAt: DateTime.now(),
        );

        final fieldId = await _fieldRepo.createField(newField);

        debugPrint('✅ Field created with ID: $fieldId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.ctrl.isArabic
                    ? 'تم إضافة الملعب'
                    : 'Field added successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving field: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic ? 'فشل حفظ الملعب' : 'Failed to save field',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing
                ? (ar ? 'تعديل الملعب' : 'Edit Field')
                : (ar ? 'إضافة ملعب' : 'Add Field'),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Images gallery
                  Text(
                    ar ? 'صور الملعب' : 'Field Images',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildImageGallery(theme, ar),
                  const SizedBox(height: 24),

                  // Field name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: ar ? 'اسم الملعب' : 'Field Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.sports_soccer),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ar
                            ? 'الرجاء إدخال اسم الملعب'
                            : 'Please enter field name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: ar ? 'الوصف' : 'Description',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ar
                            ? 'الرجاء إدخال الوصف'
                            : 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: ar ? 'الموقع' : 'Location',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ar
                            ? 'الرجاء إدخال الموقع'
                            : 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: ar ? 'السعر بالساعة' : 'Price per Hour',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffix: Text(ar ? 'د.أ' : 'JOD'),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ar ? 'الرجاء إدخال السعر' : 'Please enter price';
                      }
                      final price = double.tryParse(value.trim());
                      if (price == null || price <= 0) {
                        return ar
                            ? 'الرجاء إدخال سعر صالح'
                            : 'Please enter valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Field Type dropdown
                  DropdownButtonFormField<String>(
                    value: _fieldType,
                    decoration: InputDecoration(
                      labelText: ar ? 'نوع الملعب' : 'Field Type',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: _fieldTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _fieldType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Latitude & Longitude (optional)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          decoration: InputDecoration(
                            labelText: ar ? 'خط العرض' : 'Latitude',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          decoration: InputDecoration(
                            labelText: ar ? 'خط الطول' : 'Longitude',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Availability switch
                  SwitchListTile(
                    title: Text(ar ? 'متاح للحجز' : 'Available for Booking'),
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveField,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            ar ? 'حفظ' : 'Save',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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

  Widget _buildImageGallery(ThemeData theme, bool ar) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add image button
          GestureDetector(
            onTap: _isUploadingImage ? null : _addImage,
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8, left: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _isUploadingImage
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ar ? 'إضافة' : 'Add',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          // Existing images
          ..._imageUrls.map((url) {
            return Container(
              width: 120,
              margin: const EdgeInsets.only(right: 8, left: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.error,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(url),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
