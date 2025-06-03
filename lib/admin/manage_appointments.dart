import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sidebarnavbar.dart';

class ManageAppointmentsPage extends StatefulWidget {
  const ManageAppointmentsPage({super.key});

  @override
  State<ManageAppointmentsPage> createState() => _ManageAppointmentsPageState();
}

class _ManageAppointmentsPageState extends State<ManageAppointmentsPage> {
  // doctor display vars
  String _docId = '';
  String _docName = '';
  String _docSpec = '';
  String _docPhone = '';
  String _docEmail = '';
  String _docRating = '';

  // appointment vars
  String _apptDate = '';
  String _apptTime = '';
  String _apptStatus = '';

  // patient vars
  String _patId = '';
  final _patEmailCtrl = TextEditingController();
  final _patPhoneCtrl = TextEditingController();
  final _patHistoryCtrl = TextEditingController();
  final _patDobCtrl = TextEditingController();
  final _patGenderCtrl = TextEditingController();
  final _patAddressCtrl = TextEditingController();

  /// status filter
  final List<String> _filters = ['All', 'pending', 'accepted', 'rejected'];
  String _selectedFilter = 'pending';

  /// util – safe map read
  T? _safe<T>(DocumentSnapshot doc, String key) {
    final data = doc.data();
    if (data is Map && data.containsKey(key)) return data[key] as T?;
    return null;
  }

  /// build query with filter
  Query _query() {
    var q = FirebaseFirestore.instance.collection('appointments').orderBy('createdAt', descending: true);
    if (_selectedFilter != 'All') q = q.where('status', isEqualTo: _selectedFilter);
    return q;
  }

  /// load doctor + appointment to panel
  Future<void> _loadDetails(DocumentSnapshot a) async {
    setState(() {
      _apptDate = _safe<Timestamp>(a, 'date')?.toDate().toString().split(' ')[0] ?? '';
      _apptTime = _safe<String>(a, 'time') ?? '';
      _apptStatus = _safe<String>(a, 'status') ?? '';
      _patId = _safe<String>(a, 'patientId') ?? _safe<String>(a, 'paitentID') ?? '';
    });

    final docId = _safe<String>(a, 'doctorId');
    if (docId != null) {
      final dSnap = await FirebaseFirestore.instance.collection('doctors').doc(docId).get();
      final d = dSnap.data();
      if (d != null) {
        setState(() {
          _docId = d['id'] ?? docId;
          _docName = d['doctorName'] ?? '';
          _docSpec = d['specialization'] ?? '';
          _docPhone = d['doctorPhoneNo'] ?? '';
          _docEmail = d['doctorEmail'] ?? '';
          _docRating = (d['rating'] ?? '').toString();
        });
      }
    }

    if (_patId.isNotEmpty) {
      final pSnap = await FirebaseFirestore.instance.collection('patients').doc(_patId).get();
      final p = pSnap.data();
      if (p != null) {
        setState(() {
          _patEmailCtrl.text = p['patientEmail'] ?? '';
          _patPhoneCtrl.text = p['patientPhone'] ?? '';
          _patHistoryCtrl.text = p['pastMedicalHistory'] ?? '';
          _patDobCtrl.text = p['dob'] ?? '';
          _patGenderCtrl.text = p['gender'] ?? '';
          _patAddressCtrl.text = p['address'] ?? '';
        });
      }
    }
  }

  Future<void> _savePatientUpdates() async {
    if (_patId.isEmpty) return;
    await FirebaseFirestore.instance.collection('patients').doc(_patId).update({
      'patientEmail': _patEmailCtrl.text.trim(),
      'patientPhone': _patPhoneCtrl.text.trim(),
      'pastMedicalHistory': _patHistoryCtrl.text.trim(),
      'dob': _patDobCtrl.text.trim(),
      'gender': _patGenderCtrl.text.trim(),
      'address': _patAddressCtrl.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient details updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/manage_appointments'),

          // LEFT PANE
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  const Text('Appointments List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Status:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() => _selectedFilter = v ?? 'All'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _query().snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snap.data!.docs;
                        if (docs.isEmpty) return const Center(child: Text('No data'));
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (c, i) {
                            final ap = docs[i];
                            final ref = FirebaseFirestore.instance.collection('appointments').doc(ap.id);
                            final pid = _safe<String>(ap, 'patientId') ?? _safe<String>(ap, 'paitentID') ?? '';
                            return Card(
                              child: ListTile(
                                title: Text(_safe<String>(ap, 'doctorName') ?? ''),
                                subtitle: Text('Patient ID: $pid\nDate: ${_safe<Timestamp>(ap, 'date')?.toDate().toString().split(' ')[0] ?? ''}\nTime: ${_safe<String>(ap, 'time') ?? ''}'),
                                onTap: () => _loadDetails(ap),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => ref.update({'status': 'accepted'})),
                                  IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => ref.update({'status': 'rejected'})),
                                  IconButton(icon: const Icon(Icons.delete), onPressed: () => ref.delete()),
                                ]),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT DETAILS PANEL
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFF5F0F9),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appointment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('ID: $_docId'),
                    Text('Name: $_docName'),
                    Text('Specialist: $_docSpec'),
                    Text('Phone: $_docPhone'),
                    Text('Email: $_docEmail'),
                    Text('Rating: $_docRating'),
                    const Divider(),
                    const Text('Patient (Editable)', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(controller: _patEmailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: _patPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                    TextField(controller: _patHistoryCtrl, decoration: const InputDecoration(labelText: 'Medical History')),
                    TextField(controller: _patDobCtrl, decoration: const InputDecoration(labelText: 'DOB')),
                    TextField(controller: _patGenderCtrl, decoration: const InputDecoration(labelText: 'Gender')),
                    TextField(controller: _patAddressCtrl, decoration: const InputDecoration(labelText: 'Address')),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _savePatientUpdates, child: const Text('Save')),
                    const Divider(),
                    const Text('Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Date: $_apptDate'),
                    Text('Time: $_apptTime'),
                    Text('Status: $_apptStatus'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
