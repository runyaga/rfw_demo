import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw/formats.dart';

import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';
import 'package:rfw_spike/features/remote_view/remote_view.dart';

void main() {
  setUp(() {
    RfwEnvironment.resetForTesting();
  });

  group('RemoteView', () {
    testWidgets('shows error when asset not found', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemoteView(
            assetPath: 'assets/rfw/defaults/nonexistent.rfw',
          ),
        ),
      );

      // Wait for load attempt to complete
      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('Unable to load content'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('custom error builder is used', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RemoteView(
            assetPath: 'assets/rfw/defaults/nonexistent.rfw',
            errorBuilder: (error) => const Text('Custom Error'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Custom Error'), findsOneWidget);
    });

    testWidgets('retry button triggers reload', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RemoteView(
            assetPath: 'assets/rfw/defaults/nonexistent.rfw',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap retry button
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();

      // Should still show error (asset still doesn't exist)
      await tester.pumpAndSettle();
      expect(find.text('Unable to load content'), findsOneWidget);
    });
  });

  group('RemoteWidget rendering', () {
    testWidgets('renders parsed RFW content correctly', (tester) async {
      // Create test RFW content
      const rfwText = '''
        import core;
        widget Root = Text(text: "Test Content");
      ''';

      // Parse for testing
      final library = parseLibraryFile(rfwText);

      // Initialize environment
      rfwEnvironment.initialize();

      // Manually load the library
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      // Build widget that uses the runtime directly
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

      // Verify the remote widget rendered
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders Container with Text', (tester) async {
      const rfwText = '''
        import core;
        widget Root = Container(
          child: Center(
            child: Text(text: "Centered Text"),
          ),
        );
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.initialize();
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

      expect(find.text('Centered Text'), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });
  });
}
