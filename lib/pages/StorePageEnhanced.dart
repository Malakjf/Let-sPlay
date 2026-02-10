import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_repository.dart';
import '../services/language.dart';
import '../widgets/GlassContainer.dart';
import 'ProductEditPage.dart';
import '../services/firebase_service.dart';
import '../utils/permissions.dart';
import '../models/user_permission.dart';

/// Enhanced Store Page with Cloudinary integration
class StorePageEnhanced extends StatefulWidget {
  final LocaleController ctrl;
  const StorePageEnhanced({super.key, required this.ctrl});

  @override
  State<StorePageEnhanced> createState() => _StorePageEnhancedState();
}

class _StorePageEnhancedState extends State<StorePageEnhanced> {
  final _productRepo = ProductRepository.instance;
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isGridView = true;
  UserPermission _userPermission = UserPermission.player;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadPermission();
  }

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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productRepo.getAllProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final ar = widget.ctrl.isArabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'حذف المنتج' : 'Delete Product'),
        content: Text(
          ar
              ? 'هل أنت متأكد من حذف "${product.name}"؟'
              : 'Are you sure you want to delete "${product.name}"?',
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

    if (confirmed == true) {
      try {
        await _productRepo.deleteProduct(product.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ar ? 'تم حذف المنتج' : 'Product deleted'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          _loadProducts();
        }
      } catch (e) {
        debugPrint('❌ Error deleting product: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ar ? 'فشل حذف المنتج' : 'Failed to delete product'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
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
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ar ? 'المتجر' : 'Store',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                        ),
                        onPressed: () {
                          setState(() {
                            _isGridView = !_isGridView;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Products list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _products.isEmpty
                      ? _buildEmptyState(ar, theme)
                      : RefreshIndicator(
                          onRefresh: _loadProducts,
                          child: _isGridView
                              ? _buildGridView(theme, ar)
                              : _buildListView(theme, ar),
                        ),
                ),
              ],
            ),
            floatingActionButton: _userPermission == UserPermission.admin
                ? FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductEditPage(ctrl: widget.ctrl),
                        ),
                      );
                      if (result == true) {
                        _loadProducts();
                      }
                    },
                    child: const Icon(Icons.add),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool ar, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            ar ? 'لا توجد منتجات' : 'No products yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ar ? 'انقر على + لإضافة منتج' : 'Tap + to add a product',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(ThemeData theme, bool ar) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product, theme, ar);
      },
    );
  }

  Widget _buildListView(ThemeData theme, bool ar) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductListTile(product, theme, ar);
      },
    );
  }

  Widget _buildProductCard(Product product, ThemeData theme, bool ar) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductEditPage(ctrl: widget.ctrl, product: product),
          ),
        );
        if (result == true) {
          _loadProducts();
        }
      },
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildImagePlaceholder(theme),
                      )
                    : _buildImagePlaceholder(theme),
              ),
            ),
            // Product details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(2)} ${ar ? 'د.أ' : 'JOD'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userPermission == UserPermission.admin)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: theme.colorScheme.error,
                          onPressed: () => _deleteProduct(product),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListTile(Product product, ThemeData theme, bool ar) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildImagePlaceholder(theme),
                  )
                : _buildImagePlaceholder(theme),
          ),
        ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${product.price.toStringAsFixed(2)} ${ar ? 'د.أ' : 'JOD'}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_userPermission == UserPermission.admin) ...[
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductEditPage(ctrl: widget.ctrl, product: product),
                    ),
                  );
                  if (result == true) {
                    _loadProducts();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                color: theme.colorScheme.error,
                onPressed: () => _deleteProduct(product),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image_not_supported,
        color: theme.colorScheme.onSurfaceVariant,
        size: 32,
      ),
    );
  }
}
