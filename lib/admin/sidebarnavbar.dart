import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SidebarNavbar extends StatelessWidget {
  final String currentRoute;
  const SidebarNavbar({super.key, required this.currentRoute});

  Widget _navItem(BuildContext context, IconData icon, String title, String route) {
    final bool isActive = currentRoute == route;
    return ListTile(
      onTap: () {
        if (currentRoute != route) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      leading: Icon(icon, size: 26, color: isActive ? Colors.white : Colors.white70),
      title: Text(title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: isActive ? Colors.white24 : Colors.transparent,
      hoverColor: Colors.white12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: const Color(0xFF001F54),
      elevation: 4,
      children: [
        DrawerHeader(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('lib/assets/logo.png', width: 80, height: 80, fit: BoxFit.contain),
              const SizedBox(height: 12),
              const Text(
                'HealthSphere Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        _navItem(context, Icons.grid_view, 'Overview', '/admin_dashboard'),
        _navItem(context, Icons.medical_services, 'Doctors', '/manage_doctors'),
        _navItem(context, Icons.person, 'Patients', '/manage_patients'),
        _navItem(context, Icons.medication, 'Medicine', '/manage_medicines'),
        _navItem(context, Icons.payment, 'Payment', '/manage_payments'),
        _navItem(context, Icons.calendar_month, 'Appointments', '/manage_appointments'),
        _navItem(context, Icons.local_shipping, 'Ambulance', '/manage_ambulance'),
        _navItem(context, Icons.chat_bubble_outline, 'Chats', '/manage_ai_chats'),
        _navItem(context, Icons.article_outlined, 'Articles', '/manage_articles'),

        const Divider(color: Colors.white54, indent: 16, endIndent: 16),

        ListTile(
          leading: const Icon(Icons.logout, color: Colors.white),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
