// Updated ManageMedicinesPage with list, edit, accept/reject, real-time image, and detail popup
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'sidebarnavbar.dart';

class ManageMedicinesPage extends StatefulWidget {
  const ManageMedicinesPage({super.key});

  @override
  State<ManageMedicinesPage> createState() => _ManageMedicinesPageState();
}

class _ManageMedicinesPageState extends State<ManageMedicinesPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _useForController = TextEditingController();
  final _quantityController = TextEditingController();
  final _batchNoController = TextEditingController();
  final _priceController = TextEditingController();
  final _boughtFromController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _manufacturedByController = TextEditingController();
  final _manufactureDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _storeDetailsController = TextEditingController();
  final _sizeController = TextEditingController();
  final _photoURLController = TextEditingController();
  String _approvalStatus = 'Pending';
  Uint8List? _selectedImage;

  List<DocumentSnapshot> _medicines = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    final snapshot = await _firestore.collection('medicines').orderBy('medicineID').get();
    setState(() => _medicines = snapshot.docs);
  }

  Future<void> _pickAndUploadImage(String id) async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes == null) return;
    final ref = FirebaseStorage.instance.ref().child('pharmacy/medicinephoto/$id.png');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final url = await ref.getDownloadURL();
    setState(() {
      _photoURLController.text = url;
      _selectedImage = bytes;
    });
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _idController.text.trim();
    final doc = _firestore.collection('medicines').doc(id);
    final data = {
      'medicineID': id,
      'name': _nameController.text.trim(),
      'ingredients': _ingredientsController.text.trim(),
      'useFor': _useForController.text.trim(),
      'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
      'batchNo': _batchNoController.text.trim(),
      'price': int.tryParse(_priceController.text.trim()) ?? 0,
      'boughtFrom': _boughtFromController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'manufacturedBy': _manufacturedByController.text.trim(),
      'manufactureDate': _manufactureDateController.text.trim(),
      'expiryDate': _expiryDateController.text.trim(),
      'storeDetails': _storeDetailsController.text.trim(),
      'size': _sizeController.text.trim(),
      'medicinePhoto': _photoURLController.text.trim(),
      'approvalStatus': _approvalStatus
    };
    await doc.set(data);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine saved')));
    _formKey.currentState?.reset();
    setState(() => _selectedImage = null);
    _fetchMedicines();
  }

  void _loadForEdit(Map<String, dynamic> data) {
    _idController.text = data['medicineID'] ?? '';
    _nameController.text = data['name'] ?? '';
    _ingredientsController.text = data['ingredients'] ?? '';
    _useForController.text = data['useFor'] ?? '';
    _quantityController.text = '${data['quantity'] ?? ''}';
    _batchNoController.text = data['batchNo'] ?? '';
    _priceController.text = '${data['price'] ?? ''}';
    _boughtFromController.text = data['boughtFrom'] ?? '';
    _barcodeController.text = data['barcode'] ?? '';
    _manufacturedByController.text = data['manufacturedBy'] ?? '';
    _manufactureDateController.text = data['manufactureDate'] ?? '';
    _expiryDateController.text = data['expiryDate'] ?? '';
    _storeDetailsController.text = data['storeDetails'] ?? '';
    _sizeController.text = data['size'] ?? '';
    _photoURLController.text = data['medicinePhoto'] ?? '';
    _approvalStatus = data['approvalStatus'] ?? 'Pending';
  }

  void _showDetailPopup(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(data['name'] ?? 'Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
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

  Widget _medicineCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Card(
      child: ListTile(
        leading: d['medicinePhoto'] != null ? Image.network(
          d['medicinePhoto'],
          width: 50,
          height: 50,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        ) : const Icon(Icons.medication),
        title: Text(d['name'] ?? ''),
        subtitle: Text('Batch: ${d['batchNo']}, Qty: ${d['quantity']}, Status: ${d['approvalStatus']}'),
        trailing: Wrap(
          spacing: 10,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _loadForEdit(d)),
            IconButton(icon: const Icon(Icons.info), onPressed: () => _showDetailPopup(d)),
            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _firestore.collection('medicines').doc(d['medicineID']).update({'approvalStatus': 'Approved'})),
            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _firestore.collection('medicines').doc(d['medicineID']).update({'approvalStatus': 'Rejected'}))
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
          const SidebarNavbar(currentRoute: '/manage_medicines'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Medicine List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView(
                            children: _medicines.map(_medicineCard).toList(),
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
                            _buildField(_idController, 'Medicine ID', required: true),
                            _buildField(_nameController, 'Name', required: true),
                            _buildField(_ingredientsController, 'Ingredients'),
                            _buildField(_useForController, 'Use For'),
                            _buildField(_quantityController, 'Quantity'),
                            _buildField(_batchNoController, 'Batch No'),
                            _buildField(_priceController, 'Price'),
                            _buildField(_boughtFromController, 'Bought From'),
                            _buildField(_barcodeController, 'Barcode'),
                            _buildField(_manufacturedByController, 'Manufactured By'),
                            _buildField(_manufactureDateController, 'Manufacture Date'),
                            _buildField(_expiryDateController, 'Expiry Date'),
                            _buildField(_storeDetailsController, 'Store Details'),
                            _buildField(_sizeController, 'Size'),
                            Row(
                              children: [
                                Expanded(child: _buildField(_photoURLController, 'Photo URL')),
                                IconButton(
                                  icon: const Icon(Icons.upload_file),
                                  onPressed: () => _pickAndUploadImage(_idController.text.trim()),
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
                              onPressed: _saveMedicine,
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
