import 'package:flutter/material.dart';

class MedicineDashboard extends StatelessWidget {
  const MedicineDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Dashboard')),
      body: const Center(
        child: Text('Welcome to the Medicine Dashboard'),
      ),
    );
  }
}
