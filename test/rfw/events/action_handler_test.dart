import 'package:flutter_test/flutter_test.dart';

import 'package:rfw_spike/core/rfw/runtime/action_handler.dart';

// DynamicMap is typedef for Map<String, Object?>
typedef DynamicMap = Map<String, Object?>;

void main() {
  group('RfwActionHandler', () {
    late RfwActionHandler handler;

    setUp(() {
      handler = RfwActionHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    group('handler registration', () {
      test('registerHandler adds handler for event', () {
        handler.registerHandler('test_event', (args) {});

        expect(handler.hasHandler('test_event'), isTrue);
        expect(handler.registeredEvents, contains('test_event'));
      });

      test('registerAsyncHandler adds async handler for event', () {
        handler.registerAsyncHandler('async_event', (args) async {});

        expect(handler.hasHandler('async_event'), isTrue);
        expect(handler.registeredEvents, contains('async_event'));
      });

      test('unregisterHandler removes handler', () {
        handler.registerHandler('test_event', (args) {});
        expect(handler.hasHandler('test_event'), isTrue);

        handler.unregisterHandler('test_event');
        expect(handler.hasHandler('test_event'), isFalse);
      });

      test('hasHandler returns false for unregistered events', () {
        expect(handler.hasHandler('unknown_event'), isFalse);
      });
    });

    group('event handling', () {
      test('handleEvent calls registered sync handler', () {
        var wasCalled = false;
        Map<String, Object?>? receivedArgs;

        handler.registerHandler('button_pressed', (args) {
          wasCalled = true;
          receivedArgs = args;
        });

        final dynamicMap = <String, Object?>{
          'action': 'refresh_data',
          'source': 'home_screen',
        };

        handler.handleEvent('button_pressed', dynamicMap);

        expect(wasCalled, isTrue);
        expect(receivedArgs?['action'], 'refresh_data');
        expect(receivedArgs?['source'], 'home_screen');
      });

      test('handleEvent calls registered async handler', () async {
        var wasCalled = false;

        handler.registerAsyncHandler('async_event', (args) async {
          await Future.delayed(const Duration(milliseconds: 10));
          wasCalled = true;
        });

        handler.handleEvent('async_event', <String, Object?>{});

        // Give async handler time to complete
        await Future.delayed(const Duration(milliseconds: 50));

        expect(wasCalled, isTrue);
      });

      test('handleEvent passes arguments correctly', () {
        Map<String, Object?>? capturedArgs;

        handler.registerHandler('test', (args) {
          capturedArgs = args;
        });

        final dynamicMap = <String, Object?>{
          'stringValue': 'hello',
          'intValue': 42,
          'boolValue': true,
          'doubleValue': 3.14,
        };

        handler.handleEvent('test', dynamicMap);

        expect(capturedArgs?['stringValue'], 'hello');
        expect(capturedArgs?['intValue'], 42);
        expect(capturedArgs?['boolValue'], true);
        expect(capturedArgs?['doubleValue'], 3.14);
      });

      test('handleEvent handles nested maps', () {
        Map<String, Object?>? capturedArgs;

        handler.registerHandler('test', (args) {
          capturedArgs = args;
        });

        final nestedMap = <String, Object?>{
          'nested': <String, Object?>{'key': 'value'},
        };

        handler.handleEvent('test', nestedMap);

        expect(capturedArgs?['nested'], isA<Map>());
        expect((capturedArgs?['nested'] as Map)['key'], 'value');
      });

      test('unhandled events call onUnhandledEvent callback', () {
        String? unhandledName;
        Map<String, Object?>? unhandledArgs;

        handler.onUnhandledEvent = (name, args) {
          unhandledName = name;
          unhandledArgs = args;
        };

        handler.handleEvent('unknown_event', <String, Object?>{
          'data': 'test',
        });

        expect(unhandledName, 'unknown_event');
        expect(unhandledArgs?['data'], 'test');
      });

      test('onEventFired callback is called for all events', () {
        String? firedName;

        handler.onEventFired = (name, args) {
          firedName = name;
        };

        handler.registerHandler('test', (args) {});
        handler.handleEvent('test', <String, Object?>{});

        expect(firedName, 'test');
      });
    });

    group('error handling', () {
      test('sync handler errors are caught and logged', () {
        // Handler that throws
        handler.registerHandler('error_event', (args) {
          throw Exception('Test error');
        });

        // Should not throw
        expect(
          () => handler.handleEvent('error_event', <String, Object?>{}),
          returnsNormally,
        );
      });

      test('async handler errors are caught and logged', () async {
        handler.registerAsyncHandler('async_error', (args) async {
          throw Exception('Async test error');
        });

        // Should not throw
        handler.handleEvent('async_error', <String, Object?>{});

        // Give time for async to fail
        await Future.delayed(const Duration(milliseconds: 50));
      });
    });
  });

  group('ScopedActionHandler', () {
    test('dispose clears all registered handlers', () {
      final scopedHandler = ScopedActionHandler();

      scopedHandler.registerHandler('event1', (args) {});
      scopedHandler.registerHandler('event2', (args) {});
      scopedHandler.registerAsyncHandler('event3', (args) async {});

      expect(scopedHandler.hasHandler('event1'), isTrue);
      expect(scopedHandler.hasHandler('event2'), isTrue);
      expect(scopedHandler.hasHandler('event3'), isTrue);

      scopedHandler.dispose();

      expect(scopedHandler.hasHandler('event1'), isFalse);
      expect(scopedHandler.hasHandler('event2'), isFalse);
      expect(scopedHandler.hasHandler('event3'), isFalse);
    });
  });
}
