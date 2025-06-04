import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:healthsphere_admin/admin/manage_ai_chats.dart';
import 'theme/app_theme.dart';
// Admin Pages
import 'admin/login.dart';
import 'admin/dashboard.dart';
import 'admin/manage_doctors.dart';
import 'admin/manage_medicines.dart';
import 'admin/manage_ambulance.dart';
import 'admin/manage_patients.dart';
import 'admin/manage_appointments.dart';
import 'admin/database_view.dart';
import 'admin/manage_articles.dart'; // or your path, like admin/article_admin.dart


// Role-specific dashboards
import 'doctor_admin/doctor_admin_panel.dart';
import 'medicine/medicine_dashboard.dart';
import 'ambulance/ambulance_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    throw UnsupportedError('This admin panel is for web only.');
  }

  runApp(const HealthSphereWebApp());
}

class HealthSphereWebApp extends StatelessWidget {
  const HealthSphereWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthSphere Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleRedirector(), // ⬅️ Handles auth + role check
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        '/manage_doctors': (context) => const ManageDoctorsPage(),
        '/manage_medicines': (context) => const ManageMedicinesPage(),
        '/manage_ambulance': (context) => const ManageAmbulancePage(),
        '/manage_patients': (context) => const ManagePatientsPage(),
        '/manage_appointments': (context) => const ManageAppointmentsPage(),
        '/database_view': (context) => const DatabaseViewPage(),
        '/doctor_dashboard': (context) => const DoctorAdminPanel(),
        '/medicine_dashboard': (context) => const MedicineDashboard(),
        '/ambulance_dashboard': (context) => const AmbulanceDashboard(),
        '/manage_articles': (context) => const ManageArticlesPage(),
        '/manage_ai_chats': (context) => const ManageAIChatsPage(),

      },
    );
  }
}
class RoleRedirector extends StatelessWidget {
  const RoleRedirector({super.key});

  Future<String> _determineRoute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '/login';

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'];

    switch (role) {
      case 'admin':
        return '/admin_dashboard';
      case 'doctor':
        return '/doctor_dashboard';
      case 'medicine':
        return '/medicine_dashboard';
      case 'ambulance':
        return '/ambulance_dashboard';
      default:
        await FirebaseAuth.instance.signOut();
        return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _determineRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, snapshot.data!);
        });

        return const Scaffold(); // temporary until navigation
      },
    );
  }
}
