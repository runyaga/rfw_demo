import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw/formats.dart';

import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';

/// Golden tests for RFW widgets per DESIGN.md Section 6.1
///
/// Run with: flutter test --update-goldens test/rfw/goldens/
///
/// These tests verify that remote widget definitions render consistently.
/// Any visual changes will cause test failures until goldens are updated.
void main() {
  setUp(() {
    RfwEnvironment.resetForTesting();
    rfwEnvironment.initialize();
  });

  group('Hello World Golden Tests', () {
    testWidgets('hello_world.rfwtxt renders correctly', (tester) async {
      // Load the actual .rfwtxt file for testing (DESIGN.md Section 6.1)
      final rfwSource = File('assets/rfw/source/hello_world.rfwtxt').readAsStringSync();
      final library = parseLibraryFile(rfwSource);

      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: rfwEnvironment.content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['main']),
                'Root',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('hello_world.png'),
      );
    });
  });

  group('Basic Widget Golden Tests', () {
    testWidgets('simple text renders correctly', (tester) async {
      const rfwText = '''
        import core;
        widget Root = Text(text: "Golden Test Text");
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: rfwEnvironment.content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['main']),
                  'Root',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('simple_text.png'),
      );
    });

    testWidgets('styled text renders correctly', (tester) async {
      const rfwText = '''
        import core;
        widget Root = Text(
          text: "Styled Text",
          style: {
            fontSize: 32.0,
            fontWeight: "bold",
            color: 0xFF0000FF,
          },
        );
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: rfwEnvironment.content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['main']),
                  'Root',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('styled_text.png'),
      );
    });

    testWidgets('container with centered text renders correctly', (tester) async {
      const rfwText = '''
        import core;
        widget Root = Container(
          color: 0xFFE0E0E0,
          child: Center(
            child: Text(
              text: "Centered in Container",
              style: {
                fontSize: 18.0,
                color: 0xFF333333,
              },
            ),
          ),
        );
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 200,
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: rfwEnvironment.content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['main']),
                  'Root',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('container_centered_text.png'),
      );
    });
  });
}
