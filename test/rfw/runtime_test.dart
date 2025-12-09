import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';
import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';
import 'package:rfw_spike/core/rfw/registry/core_registry.dart';
import 'package:rfw_spike/core/rfw/registry/material_registry.dart';

void main() {
  setUp(() {
    // Reset the singleton before each test
    RfwEnvironment.resetForTesting();
  });

  group('RfwEnvironment', () {
    test('initializes without error', () {
      expect(() => rfwEnvironment.initialize(), returnsNormally);
      expect(rfwEnvironment.isInitialized, isTrue);
    });

    test('double initialization is safe', () {
      rfwEnvironment.initialize();
      expect(() => rfwEnvironment.initialize(), returnsNormally);
    });

    test('runtime is available after initialization', () {
      rfwEnvironment.initialize();
      expect(rfwEnvironment.runtime, isNotNull);
      expect(rfwEnvironment.content, isNotNull);
    });

    test('throws when updating content before initialization', () {
      expect(
        () => rfwEnvironment.updateContent('key', 'value'),
        throwsStateError,
      );
    });

    test('can update content after initialization', () {
      rfwEnvironment.initialize();
      expect(
        () => rfwEnvironment.updateContent('testKey', 'testValue'),
        returnsNormally,
      );
    });
  });

  group('Core Registry', () {
    test('creates core widgets without error', () {
      final coreWidgets = createAppCoreWidgets();
      expect(coreWidgets, isNotNull);
      expect(coreWidgets.widgets, isNotEmpty);
    });

    test('version constant is defined', () {
      expect(kCoreRegistryVersion, isNotEmpty);
      expect(kCoreRegistryVersion, equals('1.0.0'));
    });

    test('includes design system widgets', () {
      final coreWidgets = createAppCoreWidgets();
      expect(coreWidgets.widgets.containsKey('DesignSystemContainer'), isTrue);
      expect(coreWidgets.widgets.containsKey('DesignSystemText'), isTrue);
      expect(coreWidgets.widgets.containsKey('DesignSystemSpacer'), isTrue);
    });
  });

  group('Material Registry', () {
    test('creates material widgets without error', () {
      final materialWidgets = createAppMaterialWidgets();
      expect(materialWidgets, isNotNull);
      expect(materialWidgets.widgets, isNotEmpty);
    });

    test('version constant is defined', () {
      expect(kMaterialRegistryVersion, isNotEmpty);
      expect(kMaterialRegistryVersion, equals('1.0.0'));
    });

    test('includes design system material widgets', () {
      final materialWidgets = createAppMaterialWidgets();
      expect(materialWidgets.widgets.containsKey('DesignSystemButton'), isTrue);
      expect(materialWidgets.widgets.containsKey('DesignSystemCard'), isTrue);
      expect(materialWidgets.widgets.containsKey('DesignSystemTextField'), isTrue);
    });
  });

  group('RFW Text Parsing', () {
    test('parses minimal RFW text successfully', () {
      // Per DESIGN.md Section 3 Phase 1 Testing:
      // "Unit test: `widget root = Text(text: \"Hello\");`"
      const rfwText = '''
        import core;

        widget Root = Text(text: "Hello");
      ''';

      final library = parseLibraryFile(rfwText);
      expect(library, isNotNull);
    });

    test('parses RFW with Container and Text', () {
      const rfwText = '''
        import core;

        widget Root = Container(
          child: Center(
            child: Text(text: "Hello, RFW!"),
          ),
        );
      ''';

      final library = parseLibraryFile(rfwText);
      expect(library, isNotNull);
    });

    test('runtime can load parsed library', () {
      rfwEnvironment.initialize();

      const rfwText = '''
        import core;

        widget Root = Text(text: "Hello");
      ''';

      final library = parseLibraryFile(rfwText);

      expect(
        () => rfwEnvironment.runtime.update(
          const LibraryName(<String>['main']),
          library,
        ),
        returnsNormally,
      );
    });
  });

  group('Client Version', () {
    test('client version is defined', () {
      expect(kClientVersion, isNotEmpty);
      expect(kClientVersion, equals('1.0.0'));
    });
  });
}
