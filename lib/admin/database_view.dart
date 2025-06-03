// lib/admin/database_view.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseViewPage extends StatelessWidget {
  const DatabaseViewPage({super.key});

  final List<String> collections = const [
    'doctors',
    'patients',
    'medicines',
    'ambulances',
    'appointments'
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: collections.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Firebase Database Overview"),
          backgroundColor: Colors.deepPurple,
          bottom: TabBar(
            isScrollable: true,
            tabs: collections.map((c) => Tab(text: c)).toList(),
          ),
        ),
        body: TabBarView(
          children: collections.map((collection) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection(collection).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(child: Text('No data found.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(doc.id),
                          subtitle: Text(doc.data().toString()),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
