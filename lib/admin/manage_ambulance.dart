import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sidebarnavbar.dart';

class ManageAmbulancePage extends StatefulWidget {
  const ManageAmbulancePage({super.key});

  @override
  State<ManageAmbulancePage> createState() => _ManageAmbulancePageState();
}

class _ManageAmbulancePageState extends State<ManageAmbulancePage> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController hospitalController = TextEditingController();
  final TextEditingController conditionController = TextEditingController();

  void addAmbulance() async {
    final location = locationController.text.trim();
    final hospital = hospitalController.text.trim();
    final condition = conditionController.text.trim();

    if (location.isEmpty || hospital.isEmpty || condition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('ambulance').add({
      'pickuplocation': location,
      'hospitalID': hospital,
      'patientcondition': condition,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ambulance entry added successfully')),
    );

    locationController.clear();
    hospitalController.clear();
    conditionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/manage_ambulance'),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB6E0FE), Color(0xFF5B8CFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: const Text("Manage Ambulance", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Pickup Location', filled: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: hospitalController,
                    decoration: const InputDecoration(labelText: 'Hospital ID', filled: true),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: conditionController,
                    decoration: const InputDecoration(labelText: 'Patient Condition', filled: true),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: addAmbulance,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Ambulance Entry"),
                  ),
                  const SizedBox(height: 20),
                  const Expanded(child: AmbulanceList())
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AmbulanceList extends StatelessWidget {
  const AmbulanceList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ambulance')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final ambulance = docs[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text('Location: ${ambulance['pickuplocation']}'),
                subtitle: Text('Hospital ID: ${ambulance['hospitalID']}\nCondition: ${ambulance['patientcondition']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('ambulance')
                        .doc(ambulance.id)
                        .delete();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
