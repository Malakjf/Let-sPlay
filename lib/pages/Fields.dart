import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language.dart';
import '../services/field_store.dart';
import '../services/guest_service.dart';
import '../models/user_permission.dart';
import '../widgets/LogoButton.dart';
import 'FieldDetails.dart';
import 'management/AddFieldScreen.dart';

class FieldsScreen extends StatefulWidget {
  final LocaleController ctrl;
  final UserPermission userPermission;
  const FieldsScreen({
    super.key,
    required this.ctrl,
    required this.userPermission,
  });

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  late List<Map<String, dynamic>> _allFields;
  late List<Map<String, dynamic>> _filteredFields;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _allFields = [];
    _filteredFields = [];
    _loadFields();
    FieldStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    FieldStore.instance.removeListener(_onStoreChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load fields from Firestore using FieldStore
      await FieldStore.instance.loadFieldsFromFirestore();

      if (!mounted) return;

      // Get the updated local fields
      setState(() {
        _allFields = List.of(FieldStore.instance.fields);
        _filteredFields = List.of(_allFields);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading fields: $e');
    }
  }

  void _onStoreChanged() {
    if (!_isLoading) {
      setState(() {
        _allFields = List.of(FieldStore.instance.fields);
        _filteredFields = List.of(_allFields);
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filteredFields = _allFields
          .where(
            (f) =>
                (f['name']?.toString() ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (f['location']?.toString() ?? '').toLowerCase().contains(
                  query.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  void _onSort() {
    setState(() {
      _filteredFields.sort((a, b) {
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
    });
  }

  Widget _fieldPlaceholder(BuildContext context, String name) {
    final letter = name.isEmpty ? 'F' : name[0].toUpperCase();
    final theme = Theme.of(context);
    return Container(
      width: 80,
      height: 60,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stadium, color: theme.colorScheme.primary, size: 24),
            const SizedBox(height: 2),
            Text(
              letter,
              style: GoogleFonts.spaceGrotesk(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldImage(Map<String, dynamic> field) {
    final photos = field['photos'] as List<dynamic>?;
    if (photos != null && photos.isNotEmpty) {
      final firstPhoto = photos.first;
      if (firstPhoto is String && firstPhoto.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            firstPhoto,
            width: 80,
            height: 60,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _fieldPlaceholder(context, field['name'] ?? '');
            },
            errorBuilder: (context, error, stackTrace) {
              return _fieldPlaceholder(context, field['name'] ?? '');
            },
          ),
        );
      }
    }
    return _fieldPlaceholder(context, field['name'] ?? '');
  }

  /* -------------------------------------------------*/
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.ctrl,
      builder: (context, _) {
        final ar = widget.ctrl.isArabic;
        final theme = Theme.of(context);
        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                /* --------------- Header section --------------- */
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          ar ? 'قائمة الملاعب' : 'Fields List',
                          style: GoogleFonts.spaceGrotesk(
                            color: theme.textTheme.displayLarge?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: Row(
                          children: [
                            if (!_isLoading && _error == null)
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                onPressed: _loadFields,
                                tooltip: ar ? 'تحديث' : 'Refresh',
                              ),
                            const LogoButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                /* --------------- Search + Sort row --------------- */
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onSearch,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: theme.cardColor,
                            hintText: ar
                                ? 'ابحث بالاسم أو الموقع'
                                : 'Search by name or location',
                            hintStyle: TextStyle(
                              color:
                                  theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.9) ??
                                  Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _onSort,
                        icon: Icon(
                          Icons.sort,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        tooltip: ar ? 'ترتيب حسب الاسم' : 'Sort by name',
                      ),
                    ],
                  ),
                ),

                /* --------------- Loading/Error States --------------- */
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            ar ? 'جاري تحميل الملاعب...' : 'Loading fields...',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_error != null)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.redAccent,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ar
                                  ? 'حدث خطأ في تحميل الملاعب'
                                  : 'Error loading fields',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _loadFields,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                              ),
                              child: Text(ar ? 'إعادة المحاولة' : 'Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_filteredFields.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.stadium_outlined,
                              color:
                                  theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.5) ??
                                  Colors.white54,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchCtrl.text.isEmpty
                                  ? (ar
                                        ? 'لا توجد ملاعب متاحة'
                                        : 'No fields available')
                                  : (ar
                                        ? 'لم يتم العثور على نتائج'
                                        : 'No results found'),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchCtrl.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  ar
                                      ? 'حاول البحث بكلمات أخرى'
                                      : 'Try searching with different keywords',
                                  style: TextStyle(
                                    color:
                                        theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.7) ??
                                        Colors.grey,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  /* --------------- Fields list --------------- */
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadFields,
                      color: theme.colorScheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredFields.length,
                        itemBuilder: (_, i) =>
                            _fieldCard(context, _filteredFields[i], ar),
                      ),
                    ),
                  ),
              ],
            ),

            /* -------------------- Add Field Button ------------------------ */
            floatingActionButton: widget.userPermission == UserPermission.admin
                ? FloatingActionButton(
                    onPressed: () async {
                      final ar = widget.ctrl.isArabic;
                      if (!GuestService.handleGuestInteraction(context, ar)) {
                        return;
                      }

                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddFieldScreen(ctrl: widget.ctrl),
                        ),
                      );

                      if (result != null) {
                        // FieldStore updates automatically via listener.
                        // Reloading here causes the new item to disappear if not yet synced to server.
                      }
                    },
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
          ),
        );
      },
    );
  }

  /* ===============================================================
     Single field card
     ===============================================================*/
  Widget _fieldCard(BuildContext context, Map<String, dynamic> f, bool ar) {
    return GestureDetector(
      onTap: () {
        // Check if user is guest before navigating
        if (!GuestService.handleGuestInteraction(context, ar)) {
          return; // Guest user - blocked
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FieldDetailsScreen(ctrl: widget.ctrl, field: f),
          ),
        );
      },
      child: Builder(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          final price =
              f['price'] != null &&
                  (f['price'] is num) &&
                  (f['price'] as num) > 0
              ? '${f['price']} ${ar ? 'د.أ/ساعة' : 'JOD/hour'}'
              : (ar ? 'مجاني' : 'Free');

          final amenities = f['amenities'] as List<dynamic>? ?? [];
          final amenitiesText = amenities.isNotEmpty
              ? amenities.take(2).map((a) => a.toString()).join(', ')
              : (ar ? 'لا توجد مرافق' : 'No amenities');

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                _fieldImage(f),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              f['name'] ?? 'No Name',
                              style: GoogleFonts.spaceGrotesk(
                                color: theme.textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              price,
                              style: GoogleFonts.spaceGrotesk(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f['location'] ?? 'No Location',
                        style: GoogleFonts.spaceGrotesk(
                          color: theme.textTheme.titleMedium?.color,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (f['surface'] != null)
                        Row(
                          children: [
                            Icon(
                              Icons.grass,
                              color:
                                  theme.textTheme.titleMedium?.color
                                      ?.withOpacity(0.7) ??
                                  Colors.grey,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              f['surface'].toString(),
                              style: GoogleFonts.spaceGrotesk(
                                color:
                                    theme.textTheme.titleMedium?.color
                                        ?.withOpacity(0.7) ??
                                    Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.people,
                              color:
                                  theme.textTheme.titleMedium?.color
                                      ?.withOpacity(0.7) ??
                                  Colors.grey,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${f['capacity'] ?? 0} ${ar ? 'شخص' : 'people'}',
                              style: GoogleFonts.spaceGrotesk(
                                color:
                                    theme.textTheme.titleMedium?.color
                                        ?.withOpacity(0.7) ??
                                    Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      if (amenitiesText.isNotEmpty)
                        Text(
                          amenitiesText,
                          style: GoogleFonts.spaceGrotesk(
                            color: theme.textTheme.titleMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
