import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/product_repository.dart';
import '../services/cloudinary_service.dart';
import '../services/language.dart';
import '../widgets/ImageUploadWidget.dart';

/// Page for adding or editing a product
class ProductEditPage extends StatefulWidget {
  final LocaleController ctrl;
  final Product? product; // null for new product

  const ProductEditPage({super.key, required this.ctrl, this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _productRepo = ProductRepository.instance;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String? _imageUrl;
  bool _isAvailable = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '0',
    );
    _imageUrl = widget.product?.imageUrl;
    _isAvailable = widget.product?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.product != null;

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;

      if (_isEditing) {
        // Update existing product
        final updatedProduct = widget.product!.copyWith(
          name: name,
          description: description,
          price: price,
          stock: stock,
          imageUrl: _imageUrl,
          isAvailable: _isAvailable,
          updatedAt: DateTime.now(),
        );

        await _productRepo.updateProduct(updatedProduct);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.ctrl.isArabic
                    ? 'تم تحديث المنتج'
                    : 'Product updated successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Create new product
        final newProduct = Product(
          id: '', // Will be set by Firestore
          name: name,
          description: description,
          price: price,
          stock: stock,
          imageUrl: _imageUrl,
          isAvailable: _isAvailable,
          createdAt: DateTime.now(),
        );

        final productId = await _productRepo.createProduct(newProduct);

        debugPrint('✅ Product created with ID: $productId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.ctrl.isArabic
                    ? 'تم إضافة المنتج'
                    : 'Product added successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'فشل حفظ المنتج'
                  : 'Failed to save product',
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
                ? (ar ? 'تعديل المنتج' : 'Edit Product')
                : (ar ? 'إضافة منتج' : 'Add Product'),
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
                  // Image upload
                  ImageUploadWidget(
                    uploadPreset: CloudinaryService.productsPreset,
                    publicId: widget.product?.id,
                    initialImageUrl: _imageUrl,
                    height: 200,
                    label: ar ? 'صورة المنتج' : 'Product Image',
                    onUploadSuccess: (imageUrl) {
                      setState(() {
                        _imageUrl = imageUrl;
                      });
                    },
                    onUploadError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ar ? 'فشل تحميل الصورة' : 'Image upload failed',
                          ),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Product name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: ar ? 'اسم المنتج' : 'Product Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.shopping_bag),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ar
                            ? 'الرجاء إدخال اسم المنتج'
                            : 'Please enter product name';
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

                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: ar ? 'السعر' : 'Price',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffix: Text(ar ? 'د.أ' : 'JOD'),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
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

                  // Stock
                  TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: ar ? 'الكمية المتاحة' : 'Stock',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.inventory),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ar
                            ? 'الرجاء إدخال الكمية'
                            : 'Please enter stock';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Availability switch
                  SwitchListTile(
                    title: Text(ar ? 'متاح للبيع' : 'Available for Sale'),
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
                    onPressed: _isSaving ? null : _saveProduct,
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
}
