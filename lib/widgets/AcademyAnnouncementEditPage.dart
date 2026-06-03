import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';
import '../widgets/ImageUploadWidget.dart';

class AcademyAnnouncementEditPage extends StatefulWidget {
  final Map<String, dynamic>? announcement;
  final String? announcementId;

  const AcademyAnnouncementEditPage({
    super.key,
    this.announcement,
    this.announcementId,
  });

  @override
  State<AcademyAnnouncementEditPage> createState() =>
      _AcademyAnnouncementEditPageState();
}

class _AcademyAnnouncementEditPageState
    extends State<AcademyAnnouncementEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _imageUrl;
  String? _cloudinaryPublicId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!['title'] ?? '';
      _descController.text = widget.announcement!['description'] ?? '';
      _imageUrl = widget.announcement!['imageUrl'];
      _cloudinaryPublicId = widget.announcement!['cloudinaryPublicId'];
      _isActive = widget.announcement!['isActive'] ?? true;
      if (widget.announcement!['startDate'] != null) {
        _startDate = (widget.announcement!['startDate'] as Timestamp).toDate();
      }
      if (widget.announcement!['endDate'] != null) {
        _endDate = (widget.announcement!['endDate'] as Timestamp).toDate();
      }
    }
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an image first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'imageUrl': _imageUrl,
        'cloudinaryPublicId': _cloudinaryPublicId,
        'startDate': _startDate != null
            ? Timestamp.fromDate(_startDate!)
            : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.announcementId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['createdBy'] = FirebaseAuth.instance.currentUser?.uid;
        await FirebaseFirestore.instance
            .collection('academy_announcements')
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('academy_announcements')
            .doc(widget.announcementId)
            .update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement saved successfully! ✨')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.announcementId == null
              ? 'CREATE POPUP AD'
              : 'EDIT ANNOUNCEMENT',
          style: GoogleFonts.saira(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🖼️ Modern Image Upload Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CAMPAIGN CREATIVE',
                          style: GoogleFonts.saira(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                      onUploadStarted: () =>
                          setState(() => _isUploading = true),
                      onUploadSuccess: (url, publicId) {
                        setState(() {
                          _imageUrl = url;
                          _cloudinaryPublicId = publicId;
                          _isUploading = false;
                        });
                      },
                      onUploadError: (err) =>
                          setState(() => _isUploading = false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 📝 Form Fields
              _buildTextField(
                controller: _titleController,
                label: 'CAMPAIGN TITLE',
                hint: 'e.g. Summer Academy Registration',
                icon: Icons.campaign,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _descController,
                label: 'DESCRIPTION / CTA TEXT',
                hint: 'What should the users know?',
                maxLines: 3,
                icon: Icons.description,
              ),
              const SizedBox(height: 24),

              // 🗓️ Date Range & Toggle
              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: 'START DATE',
                      date: _startDate,
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTile(
                      label: 'END DATE',
                      date: _endDate,
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: Text(
                  'ACTIVE STATUS',
                  style: GoogleFonts.saira(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Toggle visibility in the app immediately',
                ),
                value: _isActive,
                activeColor: const Color(0xFFFFD700),
                onChanged: (val) => setState(() => _isActive = val),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                tileColor: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white,
              ),
              const SizedBox(height: 40),

              // 🚀 Action Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: (_isSaving || _isUploading)
                      ? null
                      : _saveAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'PUBLISH ANNOUNCEMENT',
                          style: GoogleFonts.saira(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.saira(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.saira(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date == null
                  ? 'Not Set'
                  : '${date.day}/${date.month}/${date.year}',
              style: GoogleFonts.saira(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }
}
