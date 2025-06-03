// Full-featured ManageDoctorsPage with image fallback and verified URL
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'sidebarnavbar.dart';

class ManageDoctorsPage extends StatefulWidget {
  const ManageDoctorsPage({super.key});

  @override
  State<ManageDoctorsPage> createState() => _ManageDoctorsPageState();
}

class _ManageDoctorsPageState extends State<ManageDoctorsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _specializationController = TextEditingController();
  final _ratingController = TextEditingController();
  final _hospitalIdController = TextEditingController();
  final _historyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _photoURLController = TextEditingController();

  Uint8List? _selectedImage;
  List<DocumentSnapshot> _doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final snapshot = await _firestore.collection('doctors').orderBy('doctorName').get();
    setState(() => _doctors = snapshot.docs);
  }

  Future<void> _pickAndUploadImage(String id) async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes == null) return;
    final ref = FirebaseStorage.instance.ref().child('doctor/doctorImages/$id.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();
    setState(() {
      _photoURLController.text = url;
      _selectedImage = bytes;
    });
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _idController.text.trim().isEmpty ? _firestore.collection('doctors').doc().id : _idController.text.trim();
    final doc = _firestore.collection('doctors').doc(id);
    final data = {
      'id': id,
      'doctorName': _nameController.text.trim(),
      'specialization': _specializationController.text.trim(),
      'rating': double.tryParse(_ratingController.text.trim()) ?? 0,
      'hospitalID': _hospitalIdController.text.trim(),
      'doctorHistory': _historyController.text.trim(),
      'doctorPhoneNo': _phoneController.text.trim(),
      'doctorEmail': _emailController.text.trim(),
      'qualification': _qualificationController.text.trim(),
      'medicalLicenseNumber': _licenseController.text.trim(),
      'doctorImage': _photoURLController.text.trim(),
    };
    await doc.set(data);
    _formKey.currentState?.reset();
    setState(() => _selectedImage = null);
    _fetchDoctors();
  }

  void _loadForEdit(Map<String, dynamic> d) {
    _idController.text = d['id'] ?? '';
    _nameController.text = d['doctorName'] ?? '';
    _specializationController.text = d['specialization'] ?? '';
    _ratingController.text = '${d['rating'] ?? ''}';
    _hospitalIdController.text = d['hospitalID'] ?? '';
    _historyController.text = d['doctorHistory'] ?? '';
    _phoneController.text = d['doctorPhoneNo'] ?? '';
    _emailController.text = d['doctorEmail'] ?? '';
    _qualificationController.text = d['qualification'] ?? '';
    _licenseController.text = d['medicalLicenseNumber'] ?? '';
    _photoURLController.text = d['doctorImage'] ?? '';
  }

  void _showDetailPopup(Map<String, dynamic> d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d['doctorName'] ?? 'Doctor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: d.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildField(TextEditingController c, String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label, filled: true),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    ),
  );

  Widget _doctorCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Card(
      child: ListTile(
        leading: d['doctorImage'] != null ? Image.network(
          d['doctorImage'],
          width: 50,
          height: 50,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50),
        ) : const Icon(Icons.person),
        title: Text(d['doctorName'] ?? ''),
        subtitle: Text('Spec: ${d['specialization']}, Rating: ${d['rating']}'),
        trailing: Wrap(
          spacing: 10,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _loadForEdit(d)),
            IconButton(icon: const Icon(Icons.info), onPressed: () => _showDetailPopup(d))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/manage_doctors'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Doctor List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView(
                            children: _doctors.map(_doctorCard).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 400,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildField(_idController, 'Doctor ID'),
                            _buildField(_nameController, 'Doctor Name', required: true),
                            _buildField(_specializationController, 'Specialization'),
                            _buildField(_ratingController, 'Rating'),
                            _buildField(_hospitalIdController, 'Hospital ID'),
                            _buildField(_historyController, 'History'),
                            _buildField(_phoneController, 'Phone'),
                            _buildField(_emailController, 'Email'),
                            _buildField(_qualificationController, 'Qualification'),
                            _buildField(_licenseController, 'License Number'),
                            Row(
                              children: [
                                Expanded(child: _buildField(_photoURLController, 'Photo URL')),
                                IconButton(
                                  icon: const Icon(Icons.upload_file),
                                  onPressed: () => _pickAndUploadImage(
                                    _idController.text.trim().isEmpty ? 'new_doc' : _idController.text.trim(),
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedImage != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Image.memory(_selectedImage!, height: 100),
                              ),
                            FilledButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Save'),
                              onPressed: _saveDoctor,
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
