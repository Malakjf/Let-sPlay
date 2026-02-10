import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:letsplay/widgets/LogoButton.dart';
import '../models/product.dart';
import '../services/language.dart';
import '../services/store_store.dart';
import '../services/firebase_service.dart';
import '../utils/permissions.dart';
import '../models/user_permission.dart';
import '../widgets/GlassContainer.dart';
import 'ProductDetailsSheet.dart';

class StorePage extends StatefulWidget {
  final LocaleController ctrl;
  const StorePage({super.key, required this.ctrl});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _isGridView = true;
  int _lastItemCount = 0;
  UserPermission _userPermission = UserPermission.player;

  @override
  void initState() {
    super.initState();
    _loadCurrentPermission();
    _lastItemCount = StoreStore.instance.items.length;
    StoreStore.instance.addListener(_onStoreChanged);
  }

  Future<void> _loadCurrentPermission() async {
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
    StoreStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final items = StoreStore.instance.items;
    if (_lastItemCount != 0 && items.length > _lastItemCount) {
      final newCount = items.length - _lastItemCount;
      final ar = widget.ctrl.isArabic;
      final msg = newCount == 1
          ? (ar ? 'تمت إضافة منتج جديد!' : 'A new product was added!')
          : (ar
                ? 'تمت إضافة $newCount منتجات جديدة!'
                : '$newCount new products added!');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _lastItemCount = items.length;
  }

  ImageProvider? _getImageProvider(dynamic photo) {
    try {
      if (photo is List) {
        return MemoryImage(Uint8List.fromList(photo.cast<int>()));
      }
      if (photo is String) {
        if (photo.startsWith('http')) {
          return NetworkImage(photo);
        } else if (photo.isNotEmpty) {
          // Assume it's a file path only if it's a non-http string.
          return FileImage(File(photo));
        }
      }
    } catch (e) {
      debugPrint(
        'Could not create image provider for photo: $photo. Error: $e',
      );
    }
    // Return null if photo is not a valid type or an error occurs.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    final theme = Theme.of(context);
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Text(
            ar ? 'المتجر' : 'Store',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.displayLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isGridView ? Icons.list : Icons.grid_view,
                color: theme.iconTheme.color,
              ),
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
            const LogoButton(),
          ],
        ),
        body: ListenableBuilder(
          listenable: StoreStore.instance,
          builder: (context, child) {
            if (StoreStore.instance.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = StoreStore.instance.items;
            if (items.isEmpty) {
              return _buildEmptyState(ar, theme);
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _isGridView
                  ? _buildGridView(items, ar, theme)
                  : _buildListView(items, ar, theme),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool ar, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            ar ? 'لا توجد منتجات' : 'No products available',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ar ? 'سيتم إضافة المنتجات قريباً' : 'Products will be added soon',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    List<Map<String, dynamic>> items,
    bool ar,
    ThemeData theme,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item, ar, theme, isList: false);
      },
    );
  }

  Widget _buildListView(
    List<Map<String, dynamic>> items,
    bool ar,
    ThemeData theme,
  ) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildItemCard(item, ar, theme, isList: true),
        );
      },
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> item,
    bool ar,
    ThemeData theme, {
    bool isList = false,
  }) {
    final photoData = item['photo'];
    final name =
        item['name'] as String? ?? (ar ? 'منتج غير مسمى' : 'Unnamed Product');
    final price = (item['price'] as num? ?? 0.0).toDouble();
    final imageProvider = _getImageProvider(photoData);

    // Create a Product object to pass to the details sheet.
    final product = Product(
      id: item['id']?.toString() ?? 'temp_${UniqueKey()}',
      name: name,
      description: item['description'] as String? ?? '',
      price: price,
      imageUrl: photoData is String ? photoData : null,
      createdAt: DateTime.now(), // Placeholder, not used in the sheet
    );

    return GestureDetector(
      onTap: () {
        ProductDetailsSheet.show(context, product);
      },
      child: Stack(
        children: [
          GlassContainer(
            child: isList
                ? _buildListItem(name, price, imageProvider, ar, theme)
                : _buildGridItem(name, price, imageProvider, ar, theme),
          ),
          // Delete button overlay (if item has an id)
          if (item['id'] != null && _userPermission == UserPermission.admin)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.delete, color: theme.colorScheme.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(ar ? 'حذف المنتج' : 'Delete Item'),
                      content: Text(
                        ar
                            ? 'هل أنت متأكد من حذف هذا المنتج؟'
                            : 'Are you sure you want to delete this item?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(ar ? 'إلغاء' : 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          child: Text(ar ? 'حذف' : 'Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      await StoreStore.instance.deleteItem(
                        item['id'].toString(),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ar ? 'تم حذف المنتج' : 'Item deleted'),
                          backgroundColor: theme.colorScheme.primary,
                        ),
                      );
                    } catch (e) {
                      debugPrint('❌ Error deleting store item: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ar ? 'فشل حذف المنتج' : 'Failed to delete item',
                          ),
                          backgroundColor: theme.colorScheme.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    String name,
    double price,
    ImageProvider? imageProvider,
    bool ar,
    ThemeData theme,
  ) {
    final imageWidget = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
        color: imageProvider == null
            ? theme.colorScheme.primary.withOpacity(0.1)
            : null,
      ),
      child: imageProvider == null
          ? Icon(
              Icons.image,
              size: 40,
              color: theme.colorScheme.primary.withOpacity(0.5),
            )
          : null,
    );

    final detailsWidget = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${price.toStringAsFixed(2)} ${ar ? 'دينار' : 'JOD'}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: imageWidget),
        Expanded(flex: 2, child: detailsWidget),
      ],
    );
  }

  Widget _buildListItem(
    String name,
    double price,
    ImageProvider? imageProvider,
    bool ar,
    ThemeData theme,
  ) {
    final imageWidget = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
        color: imageProvider == null
            ? theme.colorScheme.primary.withOpacity(0.1)
            : null,
      ),
      child: imageProvider == null
          ? Icon(
              Icons.image,
              size: 30,
              color: theme.colorScheme.primary.withOpacity(0.5),
            )
          : null,
    );

    final detailsWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '${price.toStringAsFixed(2)} ${ar ? 'دينار' : 'JOD'}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Row(
      children: [
        imageWidget,
        const SizedBox(width: 16),
        Expanded(child: detailsWidget),
        IconButton(
          icon: Icon(Icons.add_shopping_cart, color: theme.colorScheme.primary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ar ? 'تمت إضافة المنتج إلى السلة' : 'Item added to cart',
                ),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ],
    );
  }
}
