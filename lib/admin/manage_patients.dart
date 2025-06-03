import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'sidebarnavbar.dart';

class ManagePatientsPage extends StatefulWidget {
  const ManagePatientsPage({super.key});

  @override
  State<ManagePatientsPage> createState() => _ManagePatientsPageState();
}

class _ManagePatientsPageState extends State<ManagePatientsPage> {
  final Map<String, TextEditingController> controllers = {
    'name': TextEditingController(),
    'patientEmail': TextEditingController(),
    'patientPhone': TextEditingController(),
    'dob': TextEditingController(),
    'gender': TextEditingController(),
    'address': TextEditingController(),
    'pastMedicalHistory': TextEditingController(),
    'remark': TextEditingController(),
    'pastrecord': TextEditingController(),
    'report': TextEditingController(),
    'reportdoc': TextEditingController(),
    'profileID': TextEditingController(),
  };

  String? selectedPatientId;
  String assignedDoctorName = '';
  String assignedDoctorId = '';
  String appointmentId = '';
  String appointmentDate = '';
  String appointmentTime = '';
  String searchQuery = '';
  String? imageUrl;
  bool isEditMode = false;

  void savePatient() async {
    final Map<String, dynamic> data = controllers.map((key, value) => MapEntry(key, value.text.trim()));
    data['updatedAt'] = Timestamp.now();
    if (imageUrl != null) data['imageUrl'] = imageUrl!;

    if (selectedPatientId != null) {
      await FirebaseFirestore.instance.collection('patients').doc(selectedPatientId).update(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient updated successfully')),
      );
    }
  }

  void loadPatientData(DocumentSnapshot doc) async {
    final d = doc.data() as Map<String, dynamic>;
    selectedPatientId = doc.id;

    for (final key in controllers.keys) {
      controllers[key]?.text = d[key]?.toString() ?? '';
    }
    imageUrl = d['imageUrl'];

    final profileId = d['profileID'];
    if (profileId != null) {
      final apptSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('profileID', isEqualTo: profileId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (apptSnap.docs.isNotEmpty) {
        final appt = apptSnap.docs.first.data();
        appointmentId = apptSnap.docs.first.id;
        appointmentDate = (appt['date'] as Timestamp?)?.toDate().toLocal().toString().split(' ')[0] ?? 'N/A';
        appointmentTime = appt['time'] ?? 'N/A';
        final doctorId = appt['doctorId'];
        if (doctorId != null) {
          final docSnap = await FirebaseFirestore.instance.collection('doctors').doc(doctorId).get();
          final docData = docSnap.data();
          if (docData != null) {
            assignedDoctorId = doctorId;
            assignedDoctorName = docData['doctorName'] ?? 'N/A';
          }
        }
      }
    }
    setState(() {});
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('patient/patientPicture/${DateTime.now().millisecondsSinceEpoch}.png');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() => imageUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/manage_patients'),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  const Text('Patient List', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Search by name, email, doctor ID, patient ID, date (yyyy-mm-dd), or phone'),
                    onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('patients').orderBy('updatedAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return data['name']?.toLowerCase().contains(searchQuery) == true ||
                              data['patientEmail']?.toLowerCase().contains(searchQuery) == true ||
                              data['profileID']?.toLowerCase().contains(searchQuery) == true ||
                              data['patientPhone']?.toLowerCase().contains(searchQuery) == true ||
                              data['dob']?.toLowerCase().contains(searchQuery) == true;
                        }).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Results found: ${docs.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final patient = docs[index];
                                  final data = patient.data() as Map<String, dynamic>;
                                  return Card(
                                    child: ListTile(
                                      title: Text(data['name'] ?? 'Unnamed'),
                                      subtitle: Text("Email: \${data['patientEmail'] ?? 'N/A'}\nPhone: \${data['patientPhone'] ?? 'N/A'}"),
                                      onTap: () => loadPatientData(patient),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.info_outline, color: Colors.blue),
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Appointment & Doctor Info'),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Doctor: \$assignedDoctorName'),
                                                    Text('Appointment ID: \$appointmentId'),
                                                    Text('Date: \$appointmentDate'),
                                                    Text('Time: \$appointmentTime'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.green),
                                            onPressed: () {
                                              loadPatientData(patient);
                                              setState(() => isEditMode = true);
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => FirebaseFirestore.instance.collection('patients').doc(patient.id).delete(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              color: const Color.fromARGB(255, 245, 239, 247),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patient Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (imageUrl != null)
                      Image.network(imageUrl!, width: 100, height: 100, fit: BoxFit.cover),
                    TextButton.icon(
                      onPressed: pickAndUploadImage,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Upload Photo'),
                    ),
                    ...controllers.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: entry.value,
                        readOnly: !isEditMode,
                        decoration: InputDecoration(
                          labelText: entry.key
                              .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]}')
                              .capitalize(),
                        ),
                      ),
                    )),
                    const Divider(),
                    Text('Doctor Assigned: \$assignedDoctorName (\$assignedDoctorId)'),
                    Text('Appointment ID: \$appointmentId'),
                    Text('Appointment Date: \$appointmentDate'),
                    Text('Appointment Time: \$appointmentTime'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isEditMode ? savePatient : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                    ),
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

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
