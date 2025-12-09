// Basic smoke test for the RFW Spike app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rfw_spike/main.dart';

void main() {
  testWidgets('App renders with home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );

    // Verify that the app title appears
    expect(find.text('RFW Spike'), findsOneWidget);

    // Verify that a Scaffold is present
    expect(find.byType(Scaffold), findsOneWidget);

    // Verify AppBar is present
    expect(find.byType(AppBar), findsOneWidget);

    // Verify navigation cards are present
    expect(find.text('Stage 3: Static Rendering'), findsOneWidget);
    expect(find.text('Stage 5: Dynamic Data Binding'), findsOneWidget);
  });
}
