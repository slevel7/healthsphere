import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsadmin/main.dart';

void main() {
  testWidgets('renders login screen on startup', (WidgetTester tester) async {
    // Load the app
    await tester.pumpWidget(const HealthSphereWebApp());

    // Check for the presence of common login screen text or widget
    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets); // Email & password fields
  });
}
