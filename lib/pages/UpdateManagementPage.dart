import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateManagementPage extends StatefulWidget {
  const UpdateManagementPage({super.key});

  @override
  State<UpdateManagementPage> createState() => _UpdateManagementPageState();
}

class _UpdateManagementPageState extends State<UpdateManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _versionController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _buttonTextController = TextEditingController();
  final _storeUrlController = TextEditingController();
  bool _isMandatory = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUpdate();
  }

  Future<void> _loadCurrentUpdate() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_updates')
        .doc('latest')
        .get();
    if (doc.exists) {
      final raw = doc.data();
      final data = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(raw);
      _versionController.text = data['latestVersion'] ?? '';
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _imageUrlController.text = data['imageUrl'] ?? '';
      _buttonTextController.text = data['buttonText'] ?? '';
      _storeUrlController.text = data['storeUrl'] ?? '';
      _isMandatory = data['isMandatory'] ?? false;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance
        .collection('app_updates')
        .doc('latest')
        .set({
          'latestVersion': _versionController.text,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'imageUrl': _imageUrlController.text,
          'buttonText': _buttonTextController.text,
          'storeUrl': _storeUrlController.text,
          'isMandatory': _isMandatory,
          'updatedAt': FieldValue.serverTimestamp(),
        });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Update published!')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Manage App Updates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField('Latest Version (e.g. 2.0.0)', _versionController),
              _buildField('Title', _titleController),
              _buildField('Description', _descriptionController, maxLines: 3),
              _buildField('Banner Image URL', _imageUrlController),
              _buildField('Button Text', _buttonTextController),
              _buildField('Store URL', _storeUrlController),
              SwitchListTile(
                title: const Text('Mandatory Update'),
                value: _isMandatory,
                onChanged: (v) => setState(() => _isMandatory = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUpdate,
                  child: const Text('Save & Publish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
