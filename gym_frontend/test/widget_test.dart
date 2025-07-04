import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gym_management/main.dart';

void main() {
  testWidgets('App creates without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Just check that the app builds without throwing an exception
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App has proper structure', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Pump one frame to initialize
    await tester.pump();

    // Verify basic structure exists
    expect(find.byType(Scaffold), findsWidgets);
  });
}