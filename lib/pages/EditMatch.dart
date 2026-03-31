import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/language.dart';
import '../widgets/AnimatedButton.dart';
import 'MatchUserSelectors.dart'; // Ensure this path points to where you saved the widget

class EditMatchPage extends StatefulWidget {
  final LocaleController ctrl;
  final Map<String, dynamic>? match; // Pass null to create a new match

  const EditMatchPage({super.key, required this.ctrl, this.match});

  @override
  State<EditMatchPage> createState() => _EditMatchPageState();
}

class _EditMatchPageState extends State<EditMatchPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // State for the selectors
  List<String> _organizerIds = [];
  List<String> _coachIds = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data if editing
    if (widget.match != null) {
      _titleController.text = (widget.match!['title'] ?? '').toString();
      _locationController.text = (widget.match!['fieldName'] ?? '').toString();
      
      if (widget.match!['organizers'] != null) {
        _organizerIds = List<String>.from(widget.match!['organizers']);
      } else if (widget.match!['organizerId'] != null) {
        // Backward compatibility
        _organizerIds = [widget.match!['organizerId'].toString()];
      }

      if (widget.match!['coaches'] != null) {
        _coachIds = List<String>.from(widget.match!['coaches']);
      } else if (widget.match!['coachId'] != null) {
        // Backward compatibility
        _coachIds = [widget.match!['coachId'].toString()];
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveMatch() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final matchData = {
        'title': _titleController.text.trim(),
        'fieldName': _locationController.text.trim(),
        'organizers': _organizerIds,
        'coaches': _coachIds,
        'organizerId': _organizerIds.isNotEmpty ? _organizerIds.first : null,
        'coachId': _coachIds.isNotEmpty ? _coachIds.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.match == null) {
        matchData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('matches').add(matchData);
      } else {
        final matchId = widget.match!['id'];
        if (matchId == null) throw Exception("Match ID is missing");
        await FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .update(matchData);
      }

      if (mounted) Navigator.pop(context, true); // Return true to trigger reload
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving match: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.ctrl.isArabic;
    return Scaffold(
      appBar: AppBar(title: Text(widget.match == null 
          ? (ar ? 'مباراة جديدة' : 'New Match') 
          : (ar ? 'تعديل المباراة' : 'Edit Match'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: ar ? 'العنوان' : 'Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? (ar ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: ar ? 'الموقع' : 'Location',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              
              MatchUserSelectors(
                ctrl: widget.ctrl,
                initialOrganizers: _organizerIds,
                initialCoaches: _coachIds,
                onOrganizersChanged: (val) {
                  setState(() => _organizerIds = val);
                },
                onCoachesChanged: (val) {
                  setState(() => _coachIds = val);
                },
              ),

              const SizedBox(height: 32),
              AnimatedButton(
                text: ar ? 'حفظ' : 'Save',
                isLoading: _isLoading,
                onPressed: _saveMatch,
              ),
            ],
          ),
        ),
      ),
    );
}
}