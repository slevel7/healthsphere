import 'package:flutter/material.dart';

class AmbulanceDashboard extends StatelessWidget {
  const AmbulanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambulance Dashboard')),
      body: const Center(
        child: Text('Welcome to the Ambulance Dashboard'),
      ),
    );
  }
}
