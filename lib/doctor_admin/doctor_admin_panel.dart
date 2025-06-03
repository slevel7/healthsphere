import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorAdminPanel extends StatelessWidget {
  const DoctorAdminPanel({super.key});

  // Set this to the current doctor's Firestore ID (replace with auth logic later)
  final String doctorId = 'doc_001';

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(docId)
          .update({'status': newStatus});
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBDE5F9),
      appBar: AppBar(
        title: const Text('Doctor Admin Panel'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('appointments')
              .where('doctorId', isEqualTo: doctorId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading data:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No appointments found."));
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.teal.shade100),
                columns: const [
                  DataColumn(label: Text('Patient')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'pending';

                  return DataRow(
                    color: MaterialStateProperty.resolveWith((states) {
                      if (status == 'accepted') return Colors.green.shade50;
                      if (status == 'rejected') return Colors.red.shade50;
                      return Colors.white;
                    }),
                    cells: [
                      DataCell(Text(data['patientName'] ?? 'Patient')),
                      DataCell(Text(
                        data['date'] != null
                            ? (data['date'] as Timestamp).toDate().toString().split(' ')[0]
                            : '-',
                      )),
                      DataCell(Text(data['time'] ?? '-')),
                      DataCell(Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'accepted'
                              ? Colors.green
                              : status == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      DataCell(Row(
                        children: [
                          ElevatedButton(
                            onPressed: status == 'pending'
                                ? () => _updateStatus(doc.id, 'accepted')
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Accept"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: status == 'pending'
                                ? () => _updateStatus(doc.id, 'rejected')
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text("Reject"),
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
