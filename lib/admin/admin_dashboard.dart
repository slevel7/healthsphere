import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> _getCount(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs.length;
  }

  Future<Map<String, int>> _getAppointmentsPerDoctor() async {
    final doctors = await _firestore.collection('doctor details').get();
    Map<String, int> countMap = {};
    for (var doc in doctors.docs) {
      final doctorName = doc['doctorName'];
      final appointments = doc['appoinmtment'] ?? [];
      countMap[doctorName] = appointments.length;
    }
    return countMap;
  }

  void _addDoctor(BuildContext context) {
    final _name = TextEditingController();
    final _spec = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add Doctor"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: InputDecoration(labelText: "Doctor Name")),
            TextField(controller: _spec, decoration: InputDecoration(labelText: "Specialization")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('doctor details').add({
                'doctorName': _name.text,
                'specilization': _spec.text,
                'rating': 0,
                'hospitalID': '',
                'doctorHistory': '',
                'appoinmtment': [],
                'doctorPhoneNo': '',
                'doctorEmail': '',
              });
              Navigator.pop(context);
            },
            child: Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: FutureBuilder(
        future: Future.wait([
          _getCount('doctor details'),
          _getCount('patient details'),
          _getAppointmentsPerDoctor(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final doctorCount = snapshot.data![0] as int;
          final patientCount = snapshot.data![1] as int;
          final appointmentsMap = snapshot.data![2] as Map<String, int>;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Total Doctors: $doctorCount", style: TextStyle(fontSize: 18)),
                Text("Total Patients: $patientCount", style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Text("Appointments per Doctor:", style: TextStyle(fontSize: 18)),
                ...appointmentsMap.entries.map((e) => Text("${e.key}: ${e.value}")),
                Spacer(),
                ElevatedButton(
                  onPressed: () => _addDoctor(context),
                  child: Text("Add Doctor"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
