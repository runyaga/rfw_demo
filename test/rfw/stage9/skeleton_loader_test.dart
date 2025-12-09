import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw/formats.dart';

import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';

void main() {
  setUpAll(() {
    RfwEnvironment.resetForTesting();
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }
  });

  group('SkeletonLoader', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/skeleton_loader.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['skeleton_loader']),
        lib,
      );
    });

    testWidgets('SkeletonListItem renders containers', (tester) async {
      final content = DynamicContent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['skeleton_loader']),
                'SkeletonListItem',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debug: print widget tree
      debugPrint('Widget tree:');
      debugDumpApp();

      // Check for ColoredBox widgets (used for skeleton shapes)
      final coloredBoxes = find.byType(ColoredBox);
      debugPrint('Found ${coloredBoxes.evaluate().length} ColoredBox widgets');

      // Should have multiple ColoredBox (avatar + text lines)
      expect(coloredBoxes, findsWidgets);
    });

    testWidgets('SkeletonCard renders with expected structure', (tester) async {
      final content = DynamicContent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['skeleton_loader']),
                  'SkeletonCard',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for Card widget
      expect(find.byType(Card), findsOneWidget);

      // Check for ColoredBox widgets (image placeholder, title, subtitle, desc lines)
      final coloredBoxes = find.byType(ColoredBox);
      debugPrint('SkeletonCard: Found ${coloredBoxes.evaluate().length} ColoredBox widgets');

      // Should have several ColoredBox elements
      expect(coloredBoxes.evaluate().length, greaterThan(3));
    });

    testWidgets('SkeletonBlock renders with args.height and args.width', (tester) async {
      // Test that SkeletonBlock uses args properly
      // We need to call it from a parent widget that passes the args

      const source = '''
import core;
import material;
import skeleton_loader;

widget TestWrapper = SkeletonBlock(height: 100.0, width: 200.0);
''';

      // Parse the test wrapper
      final testLib = parseLibraryFile(source);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['test_wrapper']),
        testLib,
      );

      final content = DynamicContent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['test_wrapper']),
                'TestWrapper',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find ColoredBox widgets (SkeletonBlock uses ColoredBox + SizedBox)
      // There may be multiple due to Scaffold's background
      final coloredBoxes = find.byType(ColoredBox);
      expect(coloredBoxes, findsWidgets);

      // Find the one with our expected color (0xFFBDBDBD = gray)
      final grayColoredBox = find.byWidgetPredicate((widget) =>
          widget is ColoredBox && widget.color.toARGB32() == 0xFFBDBDBD);
      expect(grayColoredBox, findsOneWidget);

      // The ColoredBox should have the specified dimensions via its child SizedBox
      final renderBox = tester.renderObject<RenderBox>(grayColoredBox);
      debugPrint('ColoredBox size: ${renderBox.size}');
      expect(renderBox.size.height, 100.0);
      expect(renderBox.size.width, 200.0);
    });
  });
}
