import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/language.dart';
import '../../services/store_store.dart';
import '../../widgets/App_Bottom_Nav.dart';
import '../../services/firebase_service.dart';
import '../../utils/permissions.dart';
import '../../models/user_permission.dart';

class AddItemScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic>? item;
  const AddItemScreen({super.key, required this.ctrl, this.item});

  @override
  State<AddItemScreen> createState() => _AddItemScreen();
}

class _AddItemScreen extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // _photo can hold local file path (String) on mobile/desktop
  // or raw bytes (Uint8List) on web — keep dynamic to support both.
  dynamic _photo;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _name.text = widget.item!['name'] ?? '';
      _description.text = widget.item!['description'] ?? '';
      _price.text = widget.item!['price']?.toString() ?? '';
      _photo = widget.item!['photo'];
    }
    _loadPermission();
  }

  UserPermission _userPermission = UserPermission.player;

  Future<void> _loadPermission() async {
    try {
      final role = await FirebaseService.instance.getCurrentUserRole();
      setState(() {
        _userPermission = permissionFromRole(role);
      });
    } catch (e) {
      debugPrint('❌ Failed to load user role: $e');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
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
                ? (ar ? 'تعديل المنتج' : 'Edit Item')
                : (ar ? 'إضافة منتج جديد' : 'Add New Item'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                _buildHeaderSection(ar, theme),
                const SizedBox(height: 24),

                // Photo Section
                _buildPhotoSection(ar, theme),
                const SizedBox(height: 20),

                // Basic Information Section
                _buildBasicInfoSection(ar, theme),
                const SizedBox(height: 32),

                // Save Button
                _buildSaveButton(ar, theme),
                const SizedBox(height: 20),

                // Edit Items Section
                _buildEditItemsSection(ar, theme),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNav(index: 3),
      ),
    );
  }

  Widget _buildHeaderSection(bool ar, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            ar ? 'إنشاء منتج جديد' : 'Create New Item',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? 'املأ المعلومات التالية لإضافة منتج جديد إلى المتجر'
                : 'Fill in the information below to add a new item to the store',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(bool ar, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'صورة المنتج' : 'Item Photo',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

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
              if (_photo == null) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
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
                        ar ? 'لا توجد صورة' : 'No photo',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        ar ? 'اضغط لإضافة صورة' : 'Tap to add photo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Builder(
                          builder: (_) {
                            final img = _createImageProvider(_photo);
                            if (img != null) {
                              return Image(
                                image: img,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              );
                            }
                            return Container(
                              color: theme.colorScheme.primary.withOpacity(
                                0.05,
                              ),
                              child: Center(
                                child: Text(
                                  ar ? 'صورة غير مدعومة' : 'Unsupported image',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _photo = null;
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
                const SizedBox(height: 16),
              ],

              // Photo Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhotoActionButton(
                    icon: Icons.camera_alt,
                    label: ar ? 'كاميرا' : 'Camera',
                    onPressed: () async {
                      final XFile? file = await _picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1200,
                        maxHeight: 800,
                      );
                      if (file != null) {
                        if (kIsWeb) {
                          final bytes = await file.readAsBytes();
                          setState(() => _photo = bytes);
                        } else {
                          setState(() => _photo = file.path);
                        }
                      }
                    },
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  _buildPhotoActionButton(
                    icon: Icons.photo_library,
                    label: ar ? 'معرض' : 'Gallery',
                    onPressed: () async {
                      final XFile? file = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        if (kIsWeb) {
                          final bytes = await file.readAsBytes();
                          setState(() => _photo = bytes);
                        } else {
                          setState(() => _photo = file.path);
                        }
                      }
                    },
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

  Widget _buildPhotoActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
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

  /// Convert various stored photo representations into an ImageProvider.
  ///
  /// Handles:
  /// - `Uint8List`
  /// - `List<int>` or `List<dynamic>` containing bytes (e.g. JSArray from web)
  /// - `String` (file path on native platforms or network URL on web)
  /// Returns `null` when conversion is not possible.
  ImageProvider? _createImageProvider(dynamic photo) {
    if (photo == null) return null;
    try {
      if (photo is ImageProvider) return photo;
      if (photo is Uint8List) return MemoryImage(photo);
      if (photo is List<int>) return MemoryImage(Uint8List.fromList(photo));
      if (photo is List<dynamic>) {
        // Firestore on web may return JSArray<dynamic> which is List<dynamic> here.
        final casted = List<int>.from(photo);
        return MemoryImage(Uint8List.fromList(casted));
      }
      if (photo is String) {
        if (kIsWeb) {
          // On web a stored string is likely a URL
          return NetworkImage(photo);
        }
        // On native platforms treat string as a file path
        return FileImage(File(photo));
      }
      // Last resort: try to cast to List<int>
      final asList = photo as List<int>?;
      if (asList != null) return MemoryImage(Uint8List.fromList(asList));
    } catch (e) {
      debugPrint('Image conversion failed: $e');
    }
    return null;
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

        // Product Name
        _buildFormField(
          controller: _name,
          label: ar ? 'اسم المنتج' : 'Product Name',
          hint: ar ? 'أدخل اسم المنتج' : 'Enter product name',
          validator: (v) => v == null || v.trim().isEmpty
              ? (ar ? 'يرجى إدخال اسم المنتج' : 'Please enter product name')
              : null,
          icon: Icons.shopping_bag,
          theme: theme,
        ),
        const SizedBox(height: 16),

        // Product Description
        _buildFormField(
          controller: _description,
          label: ar ? 'وصف المنتج' : 'Product Description',
          hint: ar ? 'أدخل وصف المنتج' : 'Enter product description',
          validator: (v) => v == null || v.trim().isEmpty
              ? (ar
                    ? 'يرجى إدخال وصف المنتج'
                    : 'Please enter product description')
              : null,
          icon: Icons.description,
          theme: theme,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Product Price
        _buildFormField(
          controller: _price,
          label: ar ? 'سعر المنتج' : 'Product Price',
          hint: 'JOD',
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.trim().isEmpty
              ? (ar ? 'يرجى إدخال سعر المنتج' : 'Please enter product price')
              : null,
          icon: Icons.attach_money,
          theme: theme,
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool ar, ThemeData theme) {
    return ElevatedButton(
      onPressed: _saveItem,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: theme.colorScheme.primary.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.save, size: 20),
          const SizedBox(width: 8),
          Text(
            _isEditing
                ? (ar ? 'تحديث المنتج' : 'Update Item')
                : (ar ? 'حفظ المنتج' : 'Save Item'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Edit Items Section (moved outside build)
  Widget _buildEditItemsSection(bool ar, ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: StoreStore.instance.getAllItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              ar ? 'لا توجد منتجات بعد' : 'No items yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                ar ? 'تعديل المنتجات المضافة' : 'Edit Added Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = items[idx];
                final imageProvider = _createImageProvider(item['photo']);
                return ListTile(
                  leading: imageProvider != null
                      ? CircleAvatar(backgroundImage: imageProvider)
                      : const CircleAvatar(child: Icon(Icons.image)),
                  title: Text(item['name'] ?? ''),
                  subtitle: Text(item['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_userPermission == UserPermission.admin) ...[
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddItemScreen(
                                  ctrl: widget.ctrl,
                                  item: item,
                                ),
                              ),
                            );
                            if (updated != null) {
                              setState(() {}); // Refresh list after edit
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final ar = widget.ctrl.isArabic;
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(ar ? 'حذف المنتج' : 'Delete Item'),
                                content: Text(
                                  ar
                                      ? 'هل أنت متأكد من حذف "${item['name']}"؟'
                                      : 'Are you sure you want to delete "${item['name']}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(ar ? 'إلغاء' : 'Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    child: Text(ar ? 'حذف' : 'Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                await StoreStore.instance.deleteItem(
                                  item['id'].toString(),
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ar ? 'تم حذف المنتج' : 'Item deleted',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {});
                              } catch (e) {
                                debugPrint('❌ Error deleting item: $e');
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ar
                                          ? 'فشل حذف المنتج'
                                          : 'Failed to delete item',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveItem() async {
    final ar = widget.ctrl.isArabic;

    if (_userPermission != UserPermission.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ar ? 'غير مصرح' : 'Not authorized'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      if (_photo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'يرجى إضافة صورة للمنتج' : 'Please add a photo for the item',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_isEditing) {
        // Update existing item - only update the changed fields
        final updates = {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'price': double.tryParse(_price.text.trim()) ?? 0.0,
          'photo': _photo,
          'updatedAt': DateTime.now().toIso8601String(),
        };

        await StoreStore.instance.updateItem(widget.item!['id'], updates);

        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ar ? 'تم تحديث المنتج بنجاح' : 'Item updated successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Create updated item for pop (stream will update UI)
        final updatedItem = {...widget.item!, ...updates};
        Navigator.of(context).pop(updatedItem);
      } else {
        // Add new item
        final newItem = {
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'price': double.tryParse(_price.text.trim()) ?? 0.0,
          'photo': _photo,
          'createdAt': DateTime.now().toIso8601String(),
        };

        await StoreStore.instance.addItem(newItem);

        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ar ? 'تمت إضافة المنتج بنجاح' : 'Item added successfully',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.of(context).pop(newItem);
      }
    }
  }
}
