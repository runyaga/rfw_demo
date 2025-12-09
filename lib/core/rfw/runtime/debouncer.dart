import 'dart:async';

/// A utility class for debouncing high-frequency events.
///
/// Per DESIGN.md Section 7.3:
/// "TextField represents a significant challenge... This high-frequency
/// round-trip works but requires optimized, non-blocking logic in the
/// client handler."
///
/// Usage:
/// ```dart
/// final debouncer = Debouncer(milliseconds: 300);
///
/// void onTextChanged(String value) {
///   debouncer.run(() {
///     // This will only execute after 300ms of no calls
///     validateEmail(value);
///   });
/// }
/// ```
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  /// Run the action after the debounce period.
  /// If called again before the period expires, the timer resets.
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Run an async action after the debounce period.
  void runAsync(Future<void> Function() action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      action();
    });
  }

  /// Cancel any pending debounced action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Check if there is a pending debounced action.
  bool get isPending => _timer?.isActive ?? false;

  /// Dispose of the debouncer, cancelling any pending actions.
  void dispose() {
    cancel();
  }
}

/// A throttler that ensures actions are not executed more frequently
/// than a specified interval.
///
/// Unlike debouncing (which waits for inactivity), throttling executes
/// immediately and then ignores calls for a period.
///
/// Usage:
/// ```dart
/// final throttler = Throttler(milliseconds: 100);
///
/// void onScroll() {
///   throttler.run(() {
///     // Executes at most once per 100ms
///     updateScrollPosition();
///   });
/// }
/// ```
class Throttler {
  final int milliseconds;
  DateTime? _lastExecutionTime;
  Timer? _trailingTimer;
  void Function()? _lastAction;

  Throttler({required this.milliseconds});

  /// Run the action if the throttle period has passed.
  /// Optionally queues a trailing call to ensure the last call is executed.
  void run(void Function() action, {bool trailing = true}) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!).inMilliseconds >= milliseconds) {
      _lastExecutionTime = now;
      action();
      _lastAction = null;
    } else if (trailing) {
      // Queue the trailing call
      _lastAction = action;
      _trailingTimer?.cancel();
      final remaining = milliseconds - now.difference(_lastExecutionTime!).inMilliseconds;
      _trailingTimer = Timer(Duration(milliseconds: remaining), () {
        _lastExecutionTime = DateTime.now();
        _lastAction?.call();
        _lastAction = null;
      });
    }
  }

  /// Cancel any pending throttled action.
  void cancel() {
    _trailingTimer?.cancel();
    _trailingTimer = null;
    _lastAction = null;
  }

  /// Dispose of the throttler, cancelling any pending actions.
  void dispose() {
    cancel();
  }
}
