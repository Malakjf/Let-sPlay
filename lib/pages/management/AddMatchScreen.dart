import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:letsplay/pages/MatchDetails.dart';
import '../../services/language.dart';
import '../../services/matches_service.dart';
import '../../services/field_store.dart';
import 'AddFieldScreen.dart';
import '../../utils/firestore_helper.dart';

class AddMatchScreen extends StatefulWidget {
  final LocaleController ctrl;
  const AddMatchScreen({super.key, required this.ctrl});

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _pitchType;
  String? _gender;
  String? _selectedFieldName;
  Map<String, dynamic>? _selectedFieldData;
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _ageFromCtrl = TextEditingController();
  final _ageToCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _maxPlayersCtrl = TextEditingController();

  // Coach and organizer selection
  final List<Map<String, dynamic>> _selectedCoaches = [];
  final List<Map<String, dynamic>> _selectedOrganizers = [];

  // Edit mode states
  late TabController _tabController;
  final MatchesService _matchesService = MatchesService();

  // Dropdown options
  final List<String> _pitchTypeOptions = ['Indoor', 'Outdoor'];
  final List<String> _genderOptions = ['Male', 'Female', 'Mixed'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _matchesService.loadMatches();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _ageFromCtrl.dispose();
    _ageToCtrl.dispose();
    _maxPlayersCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final Set<String> matchDates = {};
    for (var m in _matchesService.matches) {
      if (m['date'] != null) {
        final date = parseFirestoreDate(m['date']);
        if (date.millisecondsSinceEpoch != 0) {
          matchDates.add(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
        }
      }
    }

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CustomDatePickerDialog(
        initialDate: _selectedDate ?? DateTime.now(),
        matchDates: matchDates,
        isArabic: widget.ctrl.isArabic,
      ),
    );
    if (!mounted) return;
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
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectCoaches(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'role',
            whereIn: ['coach', 'admin', 'Coach', 'Admin', 'COACH', 'ADMIN'],
          )
          .get();

      final coaches = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name':
              data['name'] ??
              data['fullName'] ??
              data['displayName'] ??
              data['username'] ??
              'Unknown Coach',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? 'coach',
        };
      }).toList();

      if (!mounted) return;

      if (coaches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'لا يوجد مدربين مسجلين في النظام'
                  : 'No coaches registered in the system',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                title: Text(
                  widget.ctrl.isArabic ? 'اختر المدربين' : 'Select Coaches',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: coaches.length,
                          itemBuilder: (context, index) {
                            final coach = coaches[index];
                            final isSelected = _selectedCoaches.any(
                              (c) => c['id'] == coach['id'],
                            );
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Theme.of(
                                context,
                              ).appBarTheme.backgroundColor?.withOpacity(0.1),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[700],
                                  child: Text(
                                    coach['name'][0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  coach['name'],
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  coach['email']?.isNotEmpty == true
                                      ? coach['email']
                                      : coach['phone'] ?? '',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
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
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      _selectedCoaches.removeWhere(
                                        (c) => c['id'] == coach['id'],
                                      );
                                    } else {
                                      _selectedCoaches.add(coach);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selectedCoaches.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedCoaches.length} ${widget.ctrl.isArabic ? "مدرب محدد" : "coach(es) selected"}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCoaches.clear();
                            });
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(
                            widget.ctrl.isArabic ? 'إلغاء الكل' : 'Clear All',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(widget.ctrl.isArabic ? 'تم' : 'Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error fetching coaches: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'خطأ في تحميل المدربين'
                  : 'Error loading coaches',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectOrganizers(BuildContext context) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'role',
            whereIn: [
              'organizer',
              'admin',
              'Organizer',
              'Admin',
              'ORGANIZER',
              'ADMIN',
            ],
          )
          .get();

      final organizers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name':
              data['name'] ??
              data['fullName'] ??
              data['displayName'] ??
              data['username'] ??
              'Unknown Organizer',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'role': data['role'] ?? 'organizer',
        };
      }).toList();

      if (!mounted) return;

      if (organizers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'لا يوجد منظمين مسجلين في النظام'
                  : 'No organizers registered in the system',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                title: Text(
                  widget.ctrl.isArabic ? 'اختر المنظمين' : 'Select Organizers',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: organizers.length,
                          itemBuilder: (context, index) {
                            final organizer = organizers[index];
                            final isSelected = _selectedOrganizers.any(
                              (o) => o['id'] == organizer['id'],
                            );
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: Theme.of(
                                context,
                              ).appBarTheme.backgroundColor?.withOpacity(0.1),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey[700],
                                  child: Text(
                                    organizer['name'][0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  organizer['name'],
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  organizer['email']?.isNotEmpty == true
                                      ? organizer['email']
                                      : organizer['phone'] ?? '',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
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
                                  activeColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    if (isSelected) {
                                      _selectedOrganizers.removeWhere(
                                        (o) => o['id'] == organizer['id'],
                                      );
                                    } else {
                                      _selectedOrganizers.add(organizer);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      if (_selectedOrganizers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedOrganizers.length} ${widget.ctrl.isArabic ? "منظم محدد" : "organizer(s) selected"}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedOrganizers.clear();
                            });
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: Text(
                            widget.ctrl.isArabic ? 'إلغاء الكل' : 'Clear All',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(widget.ctrl.isArabic ? 'تم' : 'Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print('Error fetching organizers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'خطأ في تحميل المنظمين'
                  : 'Error loading organizers',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectField(BuildContext context) async {
    final fields = FieldStore.instance.fields;
    if (!mounted) return;

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          title: Text(
            widget.ctrl.isArabic ? 'اختر الملعب' : 'Select Field',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fields.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.ctrl.isArabic
                          ? 'لا توجد ملاعب متاحة'
                          : 'No fields available',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: fields.length,
                      itemBuilder: (context, index) {
                        final field = fields[index];
                        return ListTile(
                          title: Text(
                            field['name'] ?? 'Unknown Field',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          subtitle: Text(
                            field['location'] ?? 'No location',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, field);
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final newField =
                          await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddFieldScreen(ctrl: widget.ctrl),
                            ),
                          );
                      if (newField != null && mounted) {
                        await FieldStore.instance.loadFieldsFromFirestore();
                        setState(() {
                          _selectedFieldName = newField['name'];
                          _selectedFieldData = newField;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                      widget.ctrl.isArabic
                          ? 'إضافة ملعب جديد'
                          : 'Add New Field',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedFieldName = selected['name'];
        _selectedFieldData = selected;
      });
    }
  }

  Future<void> _submitMatch(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'الرجاء ملء جميع الحقول المطلوبة بشكل صحيح'
                  : 'Please fill all required fields correctly',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_selectedFieldName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'يرجى اختيار الملعب'
                : 'Please select a field',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'يرجى اختيار التاريخ والوقت'
                : 'Please select date and time',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final matchId = DateTime.now().millisecondsSinceEpoch.toString();

      final fieldData = {
        'name': _selectedFieldName ?? '',
        'location': _selectedFieldData?['location'] ?? '',
        'amenities': _selectedFieldData?['amenities'] ?? [],
        'photos': _selectedFieldData?['photos'] ?? [],
        'surface': _selectedFieldData?['surface'] ?? '',
        'coords': _selectedFieldData?['coords'],
        'lat': _selectedFieldData?['lat'],
        'lng': _selectedFieldData?['lng'],
        'id': _selectedFieldData?['id'],
      };

      final matchData = {
        '__id': matchId,
        'id': matchId,
        'title': _nameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'pitchType': _pitchType ?? '',
        'gender': _gender ?? '',
        'fieldName': _selectedFieldName ?? '',
        'fieldLocation': _selectedFieldData?['location'] ?? '',
        'price': int.tryParse(_priceCtrl.text.trim()) ?? 0,
        'duration': int.tryParse(_durationCtrl.text.trim()) ?? 90,
        'ageFrom': int.tryParse(_ageFromCtrl.text.trim()) ?? 18,
        'ageTo': int.tryParse(_ageToCtrl.text.trim()) ?? 35,
        'maxPlayers': int.tryParse(_maxPlayersCtrl.text.trim()) ?? 22,
        'date': combinedDateTime.toIso8601String(),
        'time': _selectedTime!.format(context),
        'coaches': _selectedCoaches.map((c) => c['id'] as String).toList(),
        'organizers': _selectedOrganizers
            .map((o) => o['id'] as String)
            .toList(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'playersCount': 0,
        'fieldAmenities': _selectedFieldData?['amenities'] ?? [],
        'fieldData': fieldData,
        'fieldPhotos': _selectedFieldData?['photos'] ?? [],
      };

      print('📤 =========== SUBMITTING MATCH DATA ===========');
      print('📋 Match ID: $matchId');
      print('📅 Combined DateTime: $combinedDateTime');
      print('⏰ Display Time: ${_selectedTime!.format(context)}');
      print('📊 Match Data Structure:');
      matchData.forEach((key, value) {
        final type = value.runtimeType;
        print('  $key: $value ($type)');
      });
      print('===========================================');

      await _matchesService.addMatch(matchData);

      print('✅ Match saved successfully to Firestore');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'تم إضافة المباراة بنجاح'
                  : 'Match added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                MatchDetailsScreen(ctrl: widget.ctrl, matchId: null),
            settings: RouteSettings(arguments: {'match': matchData}),
          ),
        );

        _resetForm();
      }
    } catch (e) {
      print('❌ =========== ERROR ADDING MATCH ===========');
      print('Error: $e');
      print('Stack trace: ${e.toString()}');
      print('===========================================');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'فشل في إضافة المباراة'
                  : 'Failed to add match',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetForm() {
    _nameCtrl.clear();
    _priceCtrl.clear();
    _durationCtrl.clear();
    _ageFromCtrl.clear();
    _ageToCtrl.clear();
    _maxPlayersCtrl.clear();
    setState(() {
      _pitchType = null;
      _gender = null;
      _selectedFieldName = null;
      _selectedFieldData = null;
      _selectedDate = null;
      _selectedTime = null;
      _selectedCoaches.clear();
      _selectedOrganizers.clear();
    });
  }

  void _confirmDeleteMatch(Map<String, dynamic> match, bool ar) {
    final matchName = match['name'] ?? match['title'] ?? 'Match';

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.appBarTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            ar ? 'حذف المباراة' : 'Delete Match',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            ar
                ? 'هل أنت متأكد من حذف "$matchName"؟\nلا يمكن التراجع عن هذا الإجراء.'
                : 'Are you sure you want to delete "$matchName"?\nThis action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                ar ? 'إلغاء' : 'Cancel',
                style: const TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteMatch(match, ar);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                ar ? 'حذف' : 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMatch(Map<String, dynamic> match, bool ar) async {
    final matchId = match['id'] as String?;
    if (matchId == null) return;

    try {
      await _matchesService.deleteMatch(matchId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'تم حذف المباراة بنجاح' : 'Match deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting match: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ar ? 'حدث خطأ أثناء حذف المباراة' : 'Error deleting match',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required IconData icon,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            prefixIcon: Icon(icon, color: theme.iconTheme.color),
            filled: true,
            fillColor: theme.cardColor,
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
          ),
          validator:
              validator ??
              (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return ar ? 'هذا الحقل مطلوب' : 'This field is required';
                }
                return null;
              },
        ),
      ],
    );
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
            ar ? 'إضافة مباراة' : 'Add Match',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: ar ? 'إضافة مباراة' : 'Add Match'),
              Tab(text: ar ? 'المباريات' : 'Matches'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Add Match Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    _buildFormField(
                      controller: _nameCtrl,
                      label: ar ? 'اسم المباراة' : 'Match Name',
                      hint: ar ? 'اسم المباراة' : 'Match name',
                      keyboardType: TextInputType.text,
                      icon: Icons.sports_soccer,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Pitch Type and Gender
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? 'نوع الملعب *' : 'Pitch Type *',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _pitchType,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme.cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: _pitchTypeOptions
                                      .map(
                                        (type) => DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _pitchType = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? (ar
                                            ? 'الرجاء اختيار نوع الملعب'
                                            : 'Please select pitch type')
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? 'الجنس *' : 'Gender *',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _gender,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: theme.cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: _genderOptions
                                      .map(
                                        (gender) => DropdownMenuItem(
                                          value: gender,
                                          child: Text(gender),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _gender = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? (ar
                                            ? 'الرجاء اختيار الجنس'
                                            : 'Please select gender')
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Field Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'الملعب *' : 'Field *',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectField(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedFieldName ??
                                            (ar
                                                ? 'اختر الملعب'
                                                : 'Select Field'),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (_selectedFieldData?['location'] !=
                                          null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedFieldData!['location']!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withOpacity(0.7),
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.iconTheme.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price, Duration
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _priceCtrl,
                            label: ar ? 'السعر' : 'Price',
                            hint: ar ? 'السعر' : 'Price',
                            keyboardType: TextInputType.number,
                            icon: Icons.attach_money,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            controller: _durationCtrl,
                            label: ar ? 'المدة (دقيقة)' : 'Duration (min)',
                            hint: ar ? '90' : '90',
                            keyboardType: TextInputType.number,
                            icon: Icons.timer,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age Range
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _ageFromCtrl,
                            label: ar ? 'العمر من' : 'Age From',
                            hint: ar ? '18' : '18',
                            keyboardType: TextInputType.number,
                            icon: Icons.person,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFormField(
                            controller: _ageToCtrl,
                            label: ar ? 'العمر إلى' : 'Age To',
                            hint: ar ? '35' : '35',
                            keyboardType: TextInputType.number,
                            icon: Icons.person,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Max Players
                    _buildFormField(
                      controller: _maxPlayersCtrl,
                      label: ar ? 'العدد الأقصى للاعبين' : 'Max Players',
                      hint: ar ? '22' : '22',
                      keyboardType: TextInputType.number,
                      icon: Icons.group,
                      isRequired: true,
                      validator: (value) {
                        if ((true) && (value == null || value.isEmpty)) {
                          return ar
                              ? 'هذا الحقل مطلوب'
                              : 'This field is required';
                        }
                        if (value.isNotEmpty) {
                          final number = int.tryParse(value);
                          if (number == null || number <= 0) {
                            return ar
                                ? 'يرجى إدخال رقم صحيح أكبر من الصفر'
                                : 'Please enter a valid number greater than 0';
                          }
                          if (number > 100) {
                            return ar
                                ? 'الحد الأقصى للاعبين هو 100'
                                : 'Maximum players is 100';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Coach Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'المدربين' : 'Coaches',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectCoaches(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sports,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedCoaches.isEmpty
                                            ? (ar
                                                  ? 'اختر المدربين'
                                                  : 'Select Coaches')
                                            : (ar
                                                  ? 'المدربون المحددون:'
                                                  : 'Selected Coaches:'),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (_selectedCoaches.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: _selectedCoaches.map((
                                            coach,
                                          ) {
                                            return Chip(
                                              label: Text(coach['name']),
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 12,
                                              ),
                                              deleteIcon: Icon(
                                                Icons.close,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 16,
                                              ),
                                              onDeleted: () {
                                                setState(() {
                                                  _selectedCoaches.removeWhere(
                                                    (c) =>
                                                        c['id'] == coach['id'],
                                                  );
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.iconTheme.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedCoaches.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 8),
                            child: Text(
                              ar
                                  ? 'اختياري - يمكنك إضافة المدربين لاحقاً'
                                  : 'Optional - can be added later',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Organizer Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ar ? 'المنظمين' : 'Organizers',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectOrganizers(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  color: theme.iconTheme.color,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedOrganizers.isEmpty
                                            ? (ar
                                                  ? 'اختر المنظمين'
                                                  : 'Select Organizers')
                                            : (ar
                                                  ? 'المنظمون المحددون:'
                                                  : 'Selected Organizers:'),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (_selectedOrganizers.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: _selectedOrganizers.map((
                                            organizer,
                                          ) {
                                            return Chip(
                                              label: Text(organizer['name']),
                                              backgroundColor: theme
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.2),
                                              labelStyle: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontSize: 12,
                                              ),
                                              deleteIcon: Icon(
                                                Icons.close,
                                                color:
                                                    theme.colorScheme.primary,
                                                size: 16,
                                              ),
                                              onDeleted: () {
                                                setState(() {
                                                  _selectedOrganizers
                                                      .removeWhere(
                                                        (o) =>
                                                            o['id'] ==
                                                            organizer['id'],
                                                      );
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: theme.iconTheme.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_selectedOrganizers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 8),
                            child: Text(
                              ar
                                  ? 'اختياري - يمكنك إضافة المنظمين لاحقاً'
                                  : 'Optional - can be added later',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date and Time Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? 'التاريخ *' : 'Date *',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: theme.iconTheme.color,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDate != null
                                              ? '${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}'
                                              : ar
                                              ? 'اختر التاريخ'
                                              : 'Select Date',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ar ? 'الوقت *' : 'Time *',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        color: theme.iconTheme.color,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedTime != null
                                              ? _selectedTime!.format(context)
                                              : ar
                                              ? 'اختر الوقت'
                                              : 'Select Time',
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _submitMatch(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          ar ? 'إضافة المباراة' : 'Add Match',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Matches List Tab (Simplified)
            ListenableBuilder(
              listenable: _matchesService,
              builder: (context, child) {
                final matches = _matchesService.matches;
                if (matches.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 64,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ar ? 'لا توجد مباريات' : 'No matches yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ar
                              ? 'ابدأ بإضافة مباراة جديدة من علامة التبويب الأولى'
                              : 'Start by adding a new match from the first tab',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: theme.cardColor,
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchDetailsScreen(
                                ctrl: widget.ctrl,
                                matchId: null,
                              ),
                              settings: RouteSettings(
                                arguments: {'match': match},
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            (match['title'] ?? match['name'] ?? 'M')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          match['title'] ?? match['name'] ?? 'Unknown Match',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${match['fieldName'] ?? 'Unknown Field'} • ${match['pitchType'] ?? ''} • ${match['gender'] ?? ''}',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${match['date'] ?? ''} at ${match['time'] ?? ''}',
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (match['playersCount'] != null &&
                                match['maxPlayers'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${match['playersCount']} / ${match['maxPlayers']}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _EditMatchScreen(
                                      ctrl: widget.ctrl,
                                      matchData: match,
                                    ),
                                  ),
                                );
                              },
                              tooltip: ar ? 'تعديل' : 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              onPressed: () => _confirmDeleteMatch(match, ar),
                              tooltip: ar ? 'حذف' : 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper widget to handle match editing
class _EditMatchScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic> matchData;

  const _EditMatchScreen({required this.ctrl, required this.matchData});

  @override
  State<_EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends State<_EditMatchScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  String? _pitchType;
  String? _gender;
  String? _selectedFieldName;
  Map<String, dynamic>? _selectedFieldData;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _ageFromCtrl;
  late TextEditingController _ageToCtrl;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late TextEditingController _maxPlayersCtrl;

  // Coach and organizer selection
  final List<Map<String, dynamic>> _selectedCoaches = [];
  final List<Map<String, dynamic>> _selectedOrganizers = [];

  final MatchesService _matchesService = MatchesService();

  // Dropdown options
  final List<String> _pitchTypeOptions = ['Indoor', 'Outdoor'];
  final List<String> _genderOptions = ['Male', 'Female', 'Mixed'];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data
    final match = widget.matchData;
    _nameCtrl = TextEditingController(
      text: match['title'] ?? match['name'] ?? '',
    );
    _priceCtrl = TextEditingController(text: match['price']?.toString() ?? '');
    _durationCtrl = TextEditingController(
      text: match['duration']?.toString() ?? '',
    );
    _ageFromCtrl = TextEditingController(
      text: match['ageFrom']?.toString() ?? '',
    );
    _ageToCtrl = TextEditingController(text: match['ageTo']?.toString() ?? '');
    _maxPlayersCtrl = TextEditingController(
      text: match['maxPlayers']?.toString() ?? '',
    );

    // Set dropdown values
    _pitchType = match['pitchType'];
    _gender = match['gender'];

    // Set field data
    _selectedFieldName = match['fieldName'];
    _selectedFieldData = match['fieldData'];

    // Parse date and time
    if (match['date'] != null) {
      _selectedDate = parseFirestoreDate(match['date']);
      if (_selectedDate!.millisecondsSinceEpoch == 0) {
        _selectedDate = null;
      }
    }

    if (match['time'] != null) {
      try {
        final timeStr = match['time'] as String;
        final timeParts = timeStr.split(':');
        if (timeParts.length == 2) {
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        }
      } catch (e) {
        print('Error parsing time: $e');
      }
    }

    // Set coaches and organizers - handle both List<String> and List<Map> formats
    if (match['coaches'] != null && match['coaches'] is List) {
      final coachesList = match['coaches'] as List;
      for (var coach in coachesList) {
        if (coach is Map<String, dynamic>) {
          _selectedCoaches.add(coach);
        } else if (coach is String) {
          // If it's just an ID string, create a map
          _selectedCoaches.add({'id': coach, 'name': 'Coach'});
        }
      }
    }
    if (match['organizers'] != null && match['organizers'] is List) {
      final organizersList = match['organizers'] as List;
      for (var organizer in organizersList) {
        if (organizer is Map<String, dynamic>) {
          _selectedOrganizers.add(organizer);
        } else if (organizer is String) {
          // If it's just an ID string, create a map
          _selectedOrganizers.add({'id': organizer, 'name': 'Organizer'});
        }
      }
    }

    // Load actual names for coaches/organizers if we only have IDs
    _loadCoachAndOrganizerNames();
    _matchesService.loadMatches();
  }

  Future<void> _loadCoachAndOrganizerNames() async {
    // Update coach names
    for (int i = 0; i < _selectedCoaches.length; i++) {
      final coach = _selectedCoaches[i];
      if (coach['name'] == 'Coach' &&
          (coach['id']?.toString().trim().isNotEmpty ?? false)) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(coach['id'])
              .get();
          if (doc.exists && mounted) {
            setState(() {
              _selectedCoaches[i] = {
                'id': coach['id'],
                'name':
                    doc.data()?['name'] ?? doc.data()?['username'] ?? 'Coach',
              };
            });
          }
        } catch (e) {
          debugPrint('Error loading coach name: $e');
        }
      }
    }

    // Update organizer names
    for (int i = 0; i < _selectedOrganizers.length; i++) {
      final organizer = _selectedOrganizers[i];
      if (organizer['name'] == 'Organizer' &&
          (organizer['id']?.toString().trim().isNotEmpty ?? false)) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(organizer['id'])
              .get();
          if (doc.exists && mounted) {
            setState(() {
              _selectedOrganizers[i] = {
                'id': organizer['id'],
                'name':
                    doc.data()?['name'] ??
                    doc.data()?['username'] ??
                    'Organizer',
              };
            });
          }
        } catch (e) {
          debugPrint('Error loading organizer name: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _ageFromCtrl.dispose();
    _ageToCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final Set<String> matchDates = {};
    for (var m in _matchesService.matches) {
      if (m['date'] != null) {
        final date = parseFirestoreDate(m['date']);
        if (date.millisecondsSinceEpoch != 0) {
          matchDates.add(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
        }
      }
    }

    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CustomDatePickerDialog(
        initialDate: _selectedDate ?? DateTime.now(),
        matchDates: matchDates,
        isArabic: widget.ctrl.isArabic,
      ),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectField(BuildContext context) async {
    try {
      await FieldStore.instance.loadFieldsFromFirestore();
      final fields = FieldStore.instance.fields;

      if (!mounted) return;

      final selectedField = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(widget.ctrl.isArabic ? 'اختر ملعب' : 'Select Field'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  return ListTile(
                    title: Text(field['name'] ?? 'Unknown'),
                    subtitle: Text(field['location'] ?? ''),
                    onTap: () => Navigator.of(context).pop(field),
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedField != null) {
        setState(() {
          _selectedFieldName = selectedField['name'];
          _selectedFieldData = selectedField;
        });
      }
    } catch (e) {
      print('Error loading fields: $e');
    }
  }

  Future<void> _selectCoaches(BuildContext context) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Coach')
          .get();

      if (!mounted) return;

      final coaches = querySnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc.data()['name'] ?? 'Unknown'})
          .toList();

      final selectedCoaches = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (BuildContext context) {
          final tempSelected = List<Map<String, dynamic>>.from(
            _selectedCoaches,
          );

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  widget.ctrl.isArabic ? 'اختر المدربين' : 'Select Coaches',
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: coaches.length,
                    itemBuilder: (context, index) {
                      final coach = coaches[index];
                      final isSelected = tempSelected.any(
                        (c) => c['id'] == coach['id'],
                      );

                      return CheckboxListTile(
                        title: Text(coach['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              tempSelected.add(coach);
                            } else {
                              tempSelected.removeWhere(
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
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(widget.ctrl.isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(tempSelected),
                    child: Text(widget.ctrl.isArabic ? 'تأكيد' : 'Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selectedCoaches != null) {
        setState(() {
          _selectedCoaches.clear();
          _selectedCoaches.addAll(selectedCoaches);
        });
      }
    } catch (e) {
      print('Error loading coaches: $e');
    }
  }

  Future<void> _selectOrganizers(BuildContext context) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Organizer')
          .get();

      if (!mounted) return;

      final organizers = querySnapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc.data()['name'] ?? 'Unknown'})
          .toList();

      final selectedOrganizers = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (BuildContext context) {
          final tempSelected = List<Map<String, dynamic>>.from(
            _selectedOrganizers,
          );

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  widget.ctrl.isArabic ? 'اختر المنظمين' : 'Select Organizers',
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: organizers.length,
                    itemBuilder: (context, index) {
                      final organizer = organizers[index];
                      final isSelected = tempSelected.any(
                        (o) => o['id'] == organizer['id'],
                      );

                      return CheckboxListTile(
                        title: Text(organizer['name']),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              tempSelected.add(organizer);
                            } else {
                              tempSelected.removeWhere(
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
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(widget.ctrl.isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(tempSelected),
                    child: Text(widget.ctrl.isArabic ? 'تأكيد' : 'Confirm'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (selectedOrganizers != null) {
        setState(() {
          _selectedOrganizers.clear();
          _selectedOrganizers.addAll(selectedOrganizers);
        });
      }
    } catch (e) {
      print('Error loading organizers: $e');
    }
  }

  Future<void> _updateMatch(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFieldName == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic
                ? 'الرجاء اختيار الملعب والتاريخ والوقت'
                : 'Please select field, date, and time',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Combine date and time
      final combinedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final matchData = {
        'id': widget.matchData['id'], // Keep original ID
        'title': _nameCtrl.text,
        'name': _nameCtrl.text,
        'pitchType': _pitchType,
        'gender': _gender,
        'fieldName': _selectedFieldName,
        'fieldData': _selectedFieldData,
        'price': double.tryParse(_priceCtrl.text) ?? 0.0,
        'duration': int.tryParse(_durationCtrl.text) ?? 90,
        'ageFrom': int.tryParse(_ageFromCtrl.text) ?? 18,
        'ageTo': int.tryParse(_ageToCtrl.text) ?? 35,
        'maxPlayers': int.tryParse(_maxPlayersCtrl.text) ?? 22,
        'playersCount': widget.matchData['playersCount'] ?? 0, // Preserve count
        'coaches': _selectedCoaches,
        'organizers': _selectedOrganizers,
        'date':
            '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
        'time':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'dateTime': combinedDateTime.toIso8601String(),
        'createdAt':
            widget.matchData['createdAt'] ??
            Timestamp.now(), // Preserve original timestamp
        'updatedAt': Timestamp.now(),
      };

      // Update in Firestore
      final mid = (widget.matchData['id']?.toString().trim() ?? '');
      if (mid.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.ctrl.isArabic
                    ? 'معرّف المباراة غير صالح'
                    : 'Invalid match id',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('matches')
          .doc(mid)
          .update(matchData);

      // Reload matches to reflect changes
      _matchesService.loadMatches();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'تم تحديث المباراة بنجاح'
                  : 'Match updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(); // Return to matches list
      }
    } catch (e) {
      print('❌ Error updating match: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.ctrl.isArabic
                  ? 'فشل في تحديث المباراة'
                  : 'Failed to update match',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    required IconData icon,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    final theme = Theme.of(context);
    final ar = widget.ctrl.isArabic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            prefixIcon: Icon(icon, color: theme.iconTheme.color),
            filled: true,
            fillColor: theme.cardColor,
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
          ),
          validator:
              validator ??
              (value) {
                if (isRequired && (value == null || value.isEmpty)) {
                  return ar ? 'هذا الحقل مطلوب' : 'This field is required';
                }
                return null;
              },
        ),
      ],
    );
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
            ar ? 'تعديل المباراة' : 'Edit Match',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                _buildFormField(
                  controller: _nameCtrl,
                  label: ar ? 'اسم المباراة' : 'Match Name',
                  hint: ar ? 'اسم المباراة' : 'Match name',
                  keyboardType: TextInputType.text,
                  icon: Icons.sports_soccer,
                  isRequired: true,
                ),
                const SizedBox(height: 16),

                // Pitch Type and Gender
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'نوع الملعب *' : 'Pitch Type *',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: DropdownButtonFormField<String>(
                              value: _pitchType,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              isExpanded: true,
                              items: _pitchTypeOptions
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _pitchType = value;
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? (ar
                                        ? 'الرجاء اختيار نوع الملعب'
                                        : 'Please select pitch type')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'الجنس *' : 'Gender *',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              isExpanded: true,
                              items: _genderOptions
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? (ar
                                        ? 'الرجاء اختيار الجنس'
                                        : 'Please select gender')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Field Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'الملعب *' : 'Field *',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectField(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: theme.iconTheme.color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFieldName ??
                                        (ar ? 'اختر الملعب' : 'Select Field'),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (_selectedFieldData?['location'] !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedFieldData!['location']!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withOpacity(0.7),
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price, Duration
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _priceCtrl,
                        label: ar ? 'السعر' : 'Price',
                        hint: ar ? 'السعر' : 'Price',
                        keyboardType: TextInputType.number,
                        icon: Icons.attach_money,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: _durationCtrl,
                        label: ar ? 'المدة (دقيقة)' : 'Duration (min)',
                        hint: ar ? '90' : '90',
                        keyboardType: TextInputType.number,
                        icon: Icons.timer,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Age Range
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _ageFromCtrl,
                        label: ar ? 'العمر من' : 'Age From',
                        hint: ar ? '18' : '18',
                        keyboardType: TextInputType.number,
                        icon: Icons.person,
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        controller: _ageToCtrl,
                        label: ar ? 'العمر إلى' : 'Age To',
                        hint: ar ? '35' : '35',
                        keyboardType: TextInputType.number,
                        icon: Icons.person,
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Max Players
                _buildFormField(
                  controller: _maxPlayersCtrl,
                  label: ar ? 'العدد الأقصى للاعبين' : 'Max Players',
                  hint: ar ? '22' : '22',
                  keyboardType: TextInputType.number,
                  icon: Icons.group,
                  isRequired: true,
                  validator: (value) {
                    if ((true) && (value == null || value.isEmpty)) {
                      return ar ? 'هذا الحقل مطلوب' : 'This field is required';
                    }
                    if (value.isNotEmpty) {
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return ar
                            ? 'يرجى إدخال رقم صحيح أكبر من الصفر'
                            : 'Please enter a valid number greater than 0';
                      }
                      if (number > 100) {
                        return ar
                            ? 'الحد الأقصى للاعبين هو 100'
                            : 'Maximum players is 100';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Coach Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'المدربين' : 'Coaches',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectCoaches(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.sports, color: theme.iconTheme.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCoaches.isEmpty
                                        ? (ar
                                              ? 'اختر المدربين'
                                              : 'Select Coaches')
                                        : (ar
                                              ? 'المدربون المحددون:'
                                              : 'Selected Coaches:'),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (_selectedCoaches.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: _selectedCoaches.map((coach) {
                                        return Chip(
                                          label: Text(coach['name']),
                                          backgroundColor: theme
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          labelStyle: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 12,
                                          ),
                                          deleteIcon: Icon(
                                            Icons.close,
                                            color: theme.colorScheme.primary,
                                            size: 16,
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedCoaches.removeWhere(
                                                (c) => c['id'] == coach['id'],
                                              );
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedCoaches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Text(
                          ar
                              ? 'اختياري - يمكنك إضافة المدربين لاحقاً'
                              : 'Optional - can be added later',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Organizer Selection
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'المنظمين' : 'Organizers',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectOrganizers(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people, color: theme.iconTheme.color),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedOrganizers.isEmpty
                                        ? (ar
                                              ? 'اختر المنظمين'
                                              : 'Select Organizers')
                                        : (ar
                                              ? 'المنظمون المحددون:'
                                              : 'Selected Organizers:'),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (_selectedOrganizers.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: _selectedOrganizers.map((
                                        organizer,
                                      ) {
                                        return Chip(
                                          label: Text(organizer['name']),
                                          backgroundColor: theme
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          labelStyle: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 12,
                                          ),
                                          deleteIcon: Icon(
                                            Icons.close,
                                            color: theme.colorScheme.primary,
                                            size: 16,
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedOrganizers.removeWhere(
                                                (o) =>
                                                    o['id'] == organizer['id'],
                                              );
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: theme.iconTheme.color,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedOrganizers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Text(
                          ar
                              ? 'اختياري - يمكنك إضافة المنظمين لاحقاً'
                              : 'Optional - can be added later',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date and Time Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'التاريخ *' : 'Date *',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: theme.iconTheme.color,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedDate != null
                                          ? '${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}'
                                          : ar
                                          ? 'اختر التاريخ'
                                          : 'Select Date',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ar ? 'الوقت *' : 'Time *',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _selectTime(context),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: theme.iconTheme.color,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedTime != null
                                          ? _selectedTime!.format(context)
                                          : ar
                                          ? 'اختر الوقت'
                                          : 'Select Time',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _updateMatch(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      ar ? 'تحديث المباراة' : 'Update Match',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final Set<String> matchDates;
  final bool isArabic;

  const _CustomDatePickerDialog({
    required this.initialDate,
    required this.matchDates,
    required this.isArabic,
  });

  @override
  State<_CustomDatePickerDialog> createState() =>
      _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<_CustomDatePickerDialog> {
  late DateTime _currentMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + increment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOffset = DateUtils.firstDayOffset(
      _currentMonth.year,
      _currentMonth.month,
      localizations,
    );

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  localizations.formatMonthYear(_currentMonth),
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: theme.iconTheme.color),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 240,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: daysInMonth + firstDayOffset,
                itemBuilder: (context, index) {
                  if (index < firstDayOffset) return const SizedBox();
                  final day = index - firstDayOffset + 1;
                  final date = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    day,
                  );
                  final dateStr =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final hasMatch = widget.matchDates.contains(dateStr);
                  final isSelected = DateUtils.isSameDay(date, _selectedDate);
                  final isToday = DateUtils.isSameDay(date, DateTime.now());

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                      Navigator.pop(context, date);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: theme.colorScheme.primary)
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (hasMatch)
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.orange,
                                  shape: BoxShape.circle,
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
          ],
        ),
      ),
    );
  }
}
