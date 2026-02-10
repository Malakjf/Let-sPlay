import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/language.dart';

/// Page for adding or editing a match
class MatchEditPage extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic>? match; // null for new match

  const MatchEditPage({super.key, required this.ctrl, this.match});

  @override
  State<MatchEditPage> createState() => _MatchEditPageState();
}

class _MatchEditPageState extends State<MatchEditPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _ageFromController;
  late TextEditingController _ageToController;
  late TextEditingController _maxPlayersController;

  String? _pitchType;
  String? _gender;
  String _visibility = 'public';
  String? _selectedFieldName;
  Map<String, dynamic>? _selectedFieldData;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<Map<String, dynamic>> _selectedCoaches = [];
  final List<Map<String, dynamic>> _selectedOrganizers = [];

  bool _isSaving = false;
  List<Map<String, dynamic>> _fields = [];
  bool _isLoadingFields = false;

  final List<String> _pitchTypeOptions = ['Indoor', 'Outdoor'];
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _visibilityOptions = ['public', 'private', 'academy'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadFields();
    if (_isEditing) {
      _loadMatchData();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.match?['name'] ?? '');
    _priceController = TextEditingController(
      text: widget.match?['price']?.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.match?['duration']?.toString() ?? '90',
    );
    _ageFromController = TextEditingController(
      text: widget.match?['ageFrom']?.toString() ?? '18',
    );
    _ageToController = TextEditingController(
      text: widget.match?['ageTo']?.toString() ?? '35',
    );
    _maxPlayersController = TextEditingController(
      text: widget.match?['maxPlayers']?.toString() ?? '22',
    );
  }

  void _loadMatchData() {
    final match = widget.match!;
    _pitchType = match['pitchType'];
    _gender = match['gender'];
    _visibility = match['visibility'] ?? 'public';
    _selectedFieldName = match['fieldName'];

    // Parse date
    if (match['date'] != null) {
      if (match['date'] is Timestamp) {
        _selectedDate = (match['date'] as Timestamp).toDate();
      } else if (match['date'] is String) {
        _selectedDate = DateTime.tryParse(match['date']);
      }
    }

    // Parse time
    if (match['time'] != null && match['time'] is String) {
      final timeParts = (match['time'] as String).split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1].split(' ')[0]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  Future<void> _loadFields() async {
    setState(() {
      _isLoadingFields = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fields')
          .get();

      _fields = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Set selected field if editing
      if (_isEditing && _selectedFieldName != null) {
        _selectedFieldData = _fields.firstWhere(
          (f) => f['name'] == _selectedFieldName,
          orElse: () => {},
        );
      }

      if (mounted) {
        setState(() {
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _ageFromController.dispose();
    _ageToController.dispose();
    _maxPlayersController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.match != null;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectField() async {
    final ar = widget.ctrl.isArabic;
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ar ? 'لا توجد ملاعب متاحة' : 'No fields available'),
        ),
      );
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'اختر الملعب' : 'Select Field'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _fields.length,
            itemBuilder: (_, index) {
              final field = _fields[index];
              return ListTile(
                title: Text(field['name'] ?? ''),
                subtitle: Text(field['location'] ?? ''),
                onTap: () => Navigator.pop(ctx, field),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedFieldName = selected['name'];
        _selectedFieldData = selected;
      });
    }
  }

  Future<void> _selectCoaches() async {
    final ar = widget.ctrl.isArabic;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Coach')
          .get();

      final coaches = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['username'] ?? data['email'] ?? 'Coach',
          'email': data['email'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(ar ? 'اختر المدربين' : 'Select Coaches'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: coaches.length,
                itemBuilder: (_, index) {
                  final coach = coaches[index];
                  final isSelected = _selectedCoaches.any(
                    (c) => c['id'] == coach['id'],
                  );
                  return CheckboxListTile(
                    title: Text(coach['name']),
                    subtitle: Text(coach['email']),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedCoaches.add(coach);
                        } else {
                          _selectedCoaches.removeWhere(
                            (c) => c['id'] == coach['id'],
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ar ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading coaches: $e');
    }
  }

  Future<void> _selectOrganizers() async {
    final ar = widget.ctrl.isArabic;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Organizer')
          .get();

      final organizers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['username'] ?? data['email'] ?? 'Organizer',
          'email': data['email'] ?? '',
        };
      }).toList();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(ar ? 'اختر المنظمين' : 'Select Organizers'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: organizers.length,
                itemBuilder: (_, index) {
                  final organizer = organizers[index];
                  final isSelected = _selectedOrganizers.any(
                    (o) => o['id'] == organizer['id'],
                  );
                  return CheckboxListTile(
                    title: Text(organizer['name']),
                    subtitle: Text(organizer['email']),
                    value: isSelected,
                    onChanged: (value) {
                      setDialogState(() {
                        if (value == true) {
                          _selectedOrganizers.add(organizer);
                        } else {
                          _selectedOrganizers.removeWhere(
                            (o) => o['id'] == organizer['id'],
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ar ? 'إغلاق' : 'Close'),
              ),
            ],
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      debugPrint('❌ Error loading organizers: $e');
    }
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      final ar = widget.ctrl.isArabic;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ar ? 'الرجاء اختيار التاريخ والوقت' : 'Please select date and time',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final matchData = {
        'name': _nameController.text.trim(),
        'title': _nameController.text.trim(),
        'pitchType': _pitchType ?? '',
        'gender': _gender ?? '',
        'visibility': _visibility,
        'fieldName': _selectedFieldName ?? '',
        'fieldLocation': _selectedFieldData?['location'] ?? '',
        'price': int.tryParse(_priceController.text.trim()) ?? 0,
        'duration': int.tryParse(_durationController.text.trim()) ?? 90,
        'ageFrom': int.tryParse(_ageFromController.text.trim()) ?? 18,
        'ageTo': int.tryParse(_ageToController.text.trim()) ?? 35,
        'maxPlayers': int.tryParse(_maxPlayersController.text.trim()) ?? 22,
        'date': Timestamp.fromDate(combinedDateTime),
        'time': _selectedTime!.format(context),
        'coaches': _selectedCoaches.map((c) => c['id'] as String).toList(),
        'organizers': _selectedOrganizers
            .map((o) => o['id'] as String)
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing) {
        // Update existing match
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(widget.match!['id'])
            .update(matchData);
      } else {
        // Create new match
        matchData['createdAt'] = FieldValue.serverTimestamp();
        matchData['playersCount'] = 0;
        matchData['players'] = []; // Initialize empty players array
        await FirebaseFirestore.instance.collection('matches').add(matchData);
      }

      if (mounted) {
        final ar = widget.ctrl.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? (ar ? 'تم تحديث المباراة' : 'Match updated')
                  : (ar ? 'تم إضافة المباراة' : 'Match added'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('❌ Error saving match: $e');
      if (mounted) {
        final ar = widget.ctrl.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ar ? 'فشل الحفظ' : 'Failed to save'),
            backgroundColor: Colors.red,
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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            _isEditing
                ? (ar ? 'تعديل المباراة' : 'Edit Match')
                : (ar ? 'إضافة مباراة' : 'Add Match'),
          ),
          backgroundColor: theme.appBarTheme.backgroundColor,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Match Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: ar ? 'اسم المباراة' : 'Match Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.sports_soccer),
                ),
                validator: (v) => v?.trim().isEmpty == true
                    ? (ar ? 'مطلوب' : 'Required')
                    : null,
              ),
              const SizedBox(height: 16),

              // Pitch Type
              DropdownButtonFormField<String>(
                value: _pitchType,
                decoration: InputDecoration(
                  labelText: ar ? 'نوع الملعب' : 'Pitch Type',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.stadium),
                ),
                items: _pitchTypeOptions.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _pitchType = value;
                  });
                },
                validator: (v) =>
                    v == null ? (ar ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: ar ? 'الجنس' : 'Gender',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.people),
                ),
                items: _genderOptions.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value;
                  });
                },
                validator: (v) =>
                    v == null ? (ar ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 16),

              // Visibility
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: InputDecoration(
                  labelText: ar ? 'الظهور' : 'Visibility',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.visibility),
                ),
                items: _visibilityOptions.map((v) {
                  String label = v;
                  if (v == 'public') label = ar ? 'عام' : 'Public';
                  if (v == 'private') label = ar ? 'خاص' : 'Private';
                  if (v == 'academy') label = ar ? 'أكاديمية' : 'Academy';
                  return DropdownMenuItem(value: v, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _visibility = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Field Selection
              InkWell(
                onTap: _selectField,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: ar ? 'الملعب' : 'Field',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.location_on),
                    suffixIcon: _isLoadingFields
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedFieldName ?? (ar ? 'اختر ملعب' : 'Select field'),
                    style: TextStyle(
                      color: _selectedFieldName == null
                          ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: ar ? 'التاريخ' : 'Date',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : (ar ? 'اختر التاريخ' : 'Select date'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: ar ? 'الوقت' : 'Time',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : (ar ? 'اختر الوقت' : 'Select time'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: ar ? 'السعر' : 'Price',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments),
                  suffixText: ar ? 'ر.س' : 'SAR',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.trim().isEmpty == true
                    ? (ar ? 'مطلوب' : 'Required')
                    : null,
              ),
              const SizedBox(height: 16),

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: ar ? 'المدة (دقائق)' : 'Duration (minutes)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Age Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageFromController,
                      decoration: InputDecoration(
                        labelText: ar ? 'من عمر' : 'Age From',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ageToController,
                      decoration: InputDecoration(
                        labelText: ar ? 'إلى عمر' : 'Age To',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Max Players
              TextFormField(
                controller: _maxPlayersController,
                decoration: InputDecoration(
                  labelText: ar ? 'الحد الأقصى للاعبين' : 'Max Players',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.groups),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Coaches
              InkWell(
                onTap: _selectCoaches,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: ar ? 'المدربين' : 'Coaches',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedCoaches.isEmpty
                        ? (ar ? 'اختر المدربين' : 'Select coaches')
                        : '${_selectedCoaches.length} ${ar ? "مدرب" : "coach(es)"}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Organizers
              InkWell(
                onTap: _selectOrganizers,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: ar ? 'المنظمين' : 'Organizers',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.manage_accounts),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedOrganizers.isEmpty
                        ? (ar ? 'اختر المنظمين' : 'Select organizers')
                        : '${_selectedOrganizers.length} ${ar ? "منظم" : "organizer(s)"}',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveMatch,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? (ar ? 'جاري الحفظ...' : 'Saving...')
                      : _isEditing
                      ? (ar ? 'تحديث' : 'Update')
                      : (ar ? 'إضافة' : 'Add'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
