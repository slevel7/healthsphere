import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sidebarnavbar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int doctors = 0, patients = 0, appointments = 0, medicines = 0, ambulances = 0;

  @override
  void initState() {
    super.initState();
    _checkRoleAccess();
    _fetchCounts();
  }

  Future<void> _checkRoleAccess() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = doc.data()?['role'];
    if (role != 'admin') {
      Navigator.pushReplacementNamed(context, '/unauthorized');
    }
  }

  Future<void> _fetchCounts() async {
    final firestore = FirebaseFirestore.instance;
    final docs = await firestore.collection('doctors').get();
    final pats = await firestore.collection('patients').get();
    final apps = await firestore.collection('appointments').get();
    final meds = await firestore.collection('medicines').get();
    final ambs = await firestore.collection('ambulance').get();

    if (!mounted) return;
    setState(() {
      doctors = docs.size;
      patients = pats.size;
      appointments = apps.size;
      medicines = meds.size;
      ambulances = ambs.size;
    });
  }

  Widget _statCard(String label, int count, IconData icon, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 180,
        height: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.85),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: scheme.onPrimary),
            Text(label, style: TextStyle(color: scheme.onPrimary, fontSize: 16)),
            Text('$count', style: TextStyle(color: scheme.onPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          const SidebarNavbar(currentRoute: '/admin_dashboard'),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primaryContainer, scheme.primary],
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
                    title: Text('Admin Dashboard', style: TextStyle(color: scheme.onPrimary)),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.logout, color: scheme.onPrimary),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _statCard('Doctors', doctors, Icons.medical_services, scheme.primary),
                      _statCard('Patients', patients, Icons.people, scheme.secondary),
                      _statCard('Appointments', appointments, Icons.calendar_today, scheme.tertiary),
                      _statCard('Medicines', medicines, Icons.medication, scheme.primaryContainer),
                      _statCard('Ambulances', ambulances, Icons.local_shipping, scheme.error),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}