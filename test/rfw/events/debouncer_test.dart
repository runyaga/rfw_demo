import 'package:flutter_test/flutter_test.dart';

import 'package:rfw_spike/core/rfw/runtime/debouncer.dart';

void main() {
  group('Debouncer', () {
    late Debouncer debouncer;

    setUp(() {
      debouncer = Debouncer(milliseconds: 100);
    });

    tearDown(() {
      debouncer.dispose();
    });

    test('executes action after debounce period', () async {
      var executed = false;

      debouncer.run(() {
        executed = true;
      });

      // Not executed immediately
      expect(executed, isFalse);

      // Wait for debounce period
      await Future.delayed(const Duration(milliseconds: 150));

      expect(executed, isTrue);
    });

    test('resets timer on subsequent calls', () async {
      var callCount = 0;

      // Call multiple times rapidly
      debouncer.run(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.run(() => callCount++);
      await Future.delayed(const Duration(milliseconds: 50));
      debouncer.run(() => callCount++);

      // Still waiting for debounce
      expect(callCount, 0);

      // Wait for final debounce
      await Future.delayed(const Duration(milliseconds: 150));

      // Should only execute once (the last call)
      expect(callCount, 1);
    });

    test('cancel prevents execution', () async {
      var executed = false;

      debouncer.run(() {
        executed = true;
      });

      debouncer.cancel();

      await Future.delayed(const Duration(milliseconds: 150));

      expect(executed, isFalse);
    });

    test('isPending returns correct state', () async {
      expect(debouncer.isPending, isFalse);

      debouncer.run(() {});
      expect(debouncer.isPending, isTrue);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(debouncer.isPending, isFalse);
    });

    test('dispose cancels pending action', () async {
      var executed = false;

      debouncer.run(() {
        executed = true;
      });

      debouncer.dispose();

      await Future.delayed(const Duration(milliseconds: 150));

      expect(executed, isFalse);
    });

    test('runAsync executes async action after debounce', () async {
      var executed = false;

      debouncer.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        executed = true;
      });

      // Wait for debounce + async execution
      await Future.delayed(const Duration(milliseconds: 200));

      expect(executed, isTrue);
    });
  });

  group('Throttler', () {
    late Throttler throttler;

    setUp(() {
      throttler = Throttler(milliseconds: 100);
    });

    tearDown(() {
      throttler.dispose();
    });

    test('executes first call immediately', () {
      var callCount = 0;

      throttler.run(() => callCount++);

      expect(callCount, 1);
    });

    test('throttles subsequent calls within period', () {
      var callCount = 0;

      throttler.run(() => callCount++);
      throttler.run(() => callCount++);
      throttler.run(() => callCount++);

      // Only first call executed
      expect(callCount, 1);
    });

    test('executes trailing call after throttle period', () async {
      var callCount = 0;

      throttler.run(() => callCount++); // Immediate
      throttler.run(() => callCount++); // Queued for trailing
      throttler.run(() => callCount++); // Replaces trailing

      expect(callCount, 1);

      // Wait for throttle period
      await Future.delayed(const Duration(milliseconds: 150));

      // Should have immediate + trailing
      expect(callCount, 2);
    });

    test('disabling trailing prevents queued execution', () async {
      var callCount = 0;

      throttler.run(() => callCount++, trailing: false);
      throttler.run(() => callCount++, trailing: false);
      throttler.run(() => callCount++, trailing: false);

      await Future.delayed(const Duration(milliseconds: 150));

      // Only the first call should have executed
      expect(callCount, 1);
    });

    test('allows new calls after throttle period', () async {
      var callCount = 0;

      throttler.run(() => callCount++, trailing: false);
      expect(callCount, 1);

      // Wait for throttle to expire
      await Future.delayed(const Duration(milliseconds: 150));

      throttler.run(() => callCount++, trailing: false);
      expect(callCount, 2);
    });

    test('cancel prevents trailing execution', () async {
      var callCount = 0;

      throttler.run(() => callCount++); // Immediate
      throttler.run(() => callCount++); // Queued

      throttler.cancel();

      await Future.delayed(const Duration(milliseconds: 150));

      // Only the immediate call should have executed
      expect(callCount, 1);
    });
  });
}
