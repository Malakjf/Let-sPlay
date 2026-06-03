import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/language.dart';
import '../../services/firebase_service.dart';
import '../../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/ImageUploadWidget.dart';

class AddAnnouncementScreen extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic>? announcement;

  const AddAnnouncementScreen({
    super.key,
    required this.ctrl,
    this.announcement,
  });

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _btnTextCtrl;
  late TextEditingController _btnActionCtrl;
  String? _imageUrl;
  String? _cloudinaryPublicId;
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.announcement?['title']);
    _descCtrl = TextEditingController(
      text: widget.announcement?['description'],
    );
    _imageUrl = widget.announcement?['imageUrl'];
    _cloudinaryPublicId = widget.announcement?['cloudinaryPublicId'];
    _btnTextCtrl = TextEditingController(
      text: widget.announcement?['buttonText'],
    );
    _btnActionCtrl = TextEditingController(
      text: widget.announcement?['buttonAction'],
    );
    _isActive = widget.announcement?['isActive'] ?? true;
    if (widget.announcement?['startDate'] != null) {
      _startDate = (widget.announcement!['startDate'] as Timestamp).toDate();
    }
    if (widget.announcement?['endDate'] != null) {
      _endDate = (widget.announcement!['endDate'] as Timestamp).toDate();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _btnTextCtrl.dispose();
    _btnActionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.ctrl.isArabic ? 'يرجى تحميل صورة' : 'Please upload an image',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'imageUrl': _imageUrl,
        'cloudinaryPublicId': _cloudinaryPublicId,
        'buttonText': _btnTextCtrl.text.trim(),
        'buttonAction': _btnActionCtrl.text.trim(),
        'isActive': _isActive,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'targetRoles': ['All'],
        'createdBy': FirebaseService.instance.currentUser?.uid ?? '',
      };

      await FirebaseService.instance.saveAnnouncement(
        data,
        id: widget.announcement?['id'],
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving announcement: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    const backgroundColor = Color(0xFF0A0E27);
    const accentColor = Color(0xFF42A5F5); // Shifted to premium soft blue

    // Helper for modern minimal input decoration
    InputDecoration minimalInput(String label) => InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.saira(color: Colors.white70, fontSize: 14),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.announcement == null
              ? (ar ? 'إضافة إعلان' : 'Add Announcement')
              : (ar ? 'تعديل إعلان' : 'Edit Announcement'),
          style: GoogleFonts.saira(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: accentColor),
              onPressed: (_isSaving || _isUploading) ? null : _save,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _sectionHeader(ar ? 'المعلومات الأساسية' : 'BASIC INFORMATION'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              style: GoogleFonts.saira(color: Colors.white),
              decoration: minimalInput(ar ? 'العنوان' : 'Campaign Title'),
              validator: (v) => v!.isEmpty ? (ar ? 'مطلوب' : 'Required') : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              style: GoogleFonts.saira(color: Colors.white),
              decoration: minimalInput(ar ? 'الوصف' : 'Description / CTA Text'),
              maxLines: 2,
              validator: (v) => v!.isEmpty ? (ar ? 'مطلوب' : 'Required') : null,
            ),
            const SizedBox(height: 24),

            // 🖼️ Upload Image Section
            _sectionHeader(ar ? 'الوسائط' : 'VISUAL ASSET'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                // Subtle transparency, no heavy borders
                color: Colors.white.withOpacity(0.005),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ImageUploadWidget(
                    uploadPreset: CloudinaryService.academyPreset,
                    folder: CloudinaryService.academyFolder,
                    initialImageUrl: _imageUrl,
                    aspectRatio: 16 / 9,
                    borderRadius: 16,
                    onDelete: () => setState(() {
                      _imageUrl = null;
                      _cloudinaryPublicId = null;
                    }),
                    onUploadStarted: () => setState(() => _isUploading = true),
                    onUploadSuccess: (url, publicId) {
                      setState(() {
                        _imageUrl = url;
                        _cloudinaryPublicId = publicId;
                        _isUploading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ar
                                ? 'تم تحميل الصورة بنجاح'
                                : 'Image uploaded successful',
                          ),
                        ),
                      );
                    },
                    onUploadError: (err) {
                      setState(() => _isUploading = false);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionHeader(ar ? 'إعدادات الزر' : 'INTERACTION'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _btnTextCtrl,
                    style: GoogleFonts.saira(color: Colors.white),
                    decoration: minimalInput(ar ? 'نص الزر' : 'Button Text'),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextFormField(
                    controller: _btnActionCtrl,
                    style: GoogleFonts.saira(color: Colors.white),
                    decoration: minimalInput(ar ? 'الرابط' : 'Button URL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            _sectionHeader(ar ? 'الجدولة والحالة' : 'CAMPAIGN DURATION'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                    label: ar ? 'تاريخ البدء' : 'START DATE',
                    date: _startDate,
                    onTap: () => _pickDateTime(true),
                    ar: ar,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _dateTile(
                    label: ar ? 'تاريخ الانتهاء' : 'END DATE',
                    date: _endDate,
                    onTap: () => _pickDateTime(false),
                    ar: ar,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                ar ? 'نشط' : 'Is Active',
                style: GoogleFonts.saira(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: accentColor,
              contentPadding: EdgeInsets.zero,
            ),

            if (widget.announcement != null) ...[
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(ar ? 'حذف الإعلان' : 'Delete Announcement'),
                      content: Text(ar ? 'هل أنت متأكد؟' : 'Are you sure?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(ar ? 'إلغاء' : 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(
                            ar ? 'حذف' : 'Delete',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await FirebaseService.instance.deleteAnnouncement(
                      widget.announcement!['id'],
                    );
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: Text(
                  ar ? 'حذف الإعلان' : 'Delete Announcement',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.saira(
        color: Colors.white24, // Faded for hierarchy
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required bool ar,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.saira(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.saira(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
        } else {
          _endDate = d;
        }
      });
    }
  }
}
