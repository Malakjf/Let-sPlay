import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/field.dart';
import '../services/field_repository.dart';
import '../services/language.dart';
import '../models/user_permission.dart';
import 'FieldEditPage.dart';

/// Enhanced Fields Page with Cloudinary integration
class FieldsPageEnhanced extends StatefulWidget {
  final LocaleController ctrl;
  final UserPermission userPermission;

  const FieldsPageEnhanced({
    super.key,
    required this.ctrl,
    required this.userPermission,
  });

  @override
  State<FieldsPageEnhanced> createState() => _FieldsPageEnhancedState();
}

class _FieldsPageEnhancedState extends State<FieldsPageEnhanced> {
  final _fieldRepo = FieldRepository.instance;
  List<Field> _fields = [];
  List<Field> _filteredFields = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFields();
    _searchCtrl.addListener(_filterFields);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fields = await _fieldRepo.getAllFields();
      if (mounted) {
        setState(() {
          _fields = fields;
          _filteredFields = fields;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading fields: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterFields() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFields = _fields;
      } else {
        _filteredFields = _fields.where((field) {
          return field.name.toLowerCase().contains(query) ||
              field.location.toLowerCase().contains(query) ||
              (field.description.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  Future<void> _deleteField(Field field) async {
    final ar = widget.ctrl.isArabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'حذف الملعب' : 'Delete Field'),
        content: Text(
          ar
              ? 'هل أنت متأكد من حذف "${field.name}"؟'
              : 'Are you sure you want to delete "${field.name}"?',
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
        await _fieldRepo.deleteField(field.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ar ? 'تم حذف الملعب' : 'Field deleted'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          _loadFields();
        }
      } catch (e) {
        debugPrint('❌ Error deleting field: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ar ? 'فشل حذف الملعب' : 'Failed to delete field'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ar ? 'الملاعب' : 'Fields',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search bar
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: ar
                              ? 'بحث عن الملاعب...'
                              : 'Search fields...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),

                // Fields list
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredFields.isEmpty
                      ? _buildEmptyState(ar, theme)
                      : RefreshIndicator(
                          onRefresh: _loadFields,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredFields.length,
                            itemBuilder: (context, index) {
                              final field = _filteredFields[index];
                              return _buildFieldCard(field, theme, ar);
                            },
                          ),
                        ),
                ),
              ],
            ),
            floatingActionButton: _canAddFields()
                ? FloatingActionButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FieldEditPage(ctrl: widget.ctrl),
                        ),
                      );
                      if (result == true) {
                        _loadFields();
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

  bool _canAddFields() {
    return widget.userPermission == UserPermission.admin;
  }

  Widget _buildEmptyState(bool ar, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            ar ? 'لا توجد ملاعب' : 'No fields yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_canAddFields()) ...[
            const SizedBox(height: 8),
            Text(
              ar ? 'انقر على + لإضافة ملعب' : 'Tap + to add a field',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldCard(Field field, ThemeData theme, bool ar) {
    return GestureDetector(
      onTap: () async {
        if (_canAddFields()) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FieldEditPage(ctrl: widget.ctrl, field: field),
            ),
          );
          if (result == true) {
            _loadFields();
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Field image(s)
            _buildFieldImages(field, theme),

            // Field details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          field.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_canAddFields())
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: theme.colorScheme.error,
                          onPressed: () => _deleteField(field),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          field.location,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    field.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (field.fieldType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            field.fieldType!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        '${field.pricePerHour.toStringAsFixed(2)} ${ar ? 'د.أ/ساعة' : 'JOD/hr'}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildFieldImages(Field field, ThemeData theme) {
    if (field.images.isEmpty) {
      return Container(
        height: 200,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    if (field.images.length == 1) {
      return CachedNetworkImage(
        imageUrl: field.images.first,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: theme.colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(Icons.error, size: 64, color: theme.colorScheme.error),
        ),
      );
    }

    // Multiple images - show in a horizontal scroll
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: field.images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 250,
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 8,
              right: index == field.images.length - 1 ? 0 : 8,
            ),
            child: CachedNetworkImage(
              imageUrl: field.images[index],
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.error,
                  size: 32,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
