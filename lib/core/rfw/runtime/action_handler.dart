import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rfw/rfw.dart';

/// Type definition for event handlers
typedef RfwEventHandler = void Function(Map<String, Object?> arguments);

/// Type definition for async event handlers
typedef RfwAsyncEventHandler = Future<void> Function(Map<String, Object?> arguments);

/// RFW Action Handler that manages bidirectional communication between
/// remote widgets and native code.
///
/// Per DESIGN.md Section 3 Phase 3 Step 2:
/// "Implement the onEvent callback in the RemoteWidget. Create a generalized
/// ActionHandler switch statement. This handler receives the event name
/// (e.g., submit_form) and arguments, then delegates to the appropriate
/// Bloc/Provider method."
class RfwActionHandler {
  RfwActionHandler();

  /// Registered event handlers keyed by event name
  final Map<String, RfwEventHandler> _handlers = {};

  /// Registered async event handlers keyed by event name
  final Map<String, RfwAsyncEventHandler> _asyncHandlers = {};

  /// Optional callback for logging/analytics when events are fired
  void Function(String name, Map<String, Object?> arguments)? onEventFired;

  /// Optional callback for logging/analytics when events are unhandled
  void Function(String name, Map<String, Object?> arguments)? onUnhandledEvent;

  /// Register a synchronous handler for a specific event name.
  ///
  /// Example:
  /// ```dart
  /// actionHandler.registerHandler('button_pressed', (args) {
  ///   final action = args['action'] as String?;
  ///   if (action == 'refresh_data') {
  ///     ref.read(dataProvider.notifier).refresh();
  ///   }
  /// });
  /// ```
  void registerHandler(String eventName, RfwEventHandler handler) {
    _handlers[eventName] = handler;
  }

  /// Register an asynchronous handler for a specific event name.
  ///
  /// Useful for handlers that need to perform async operations like
  /// API calls or database updates.
  void registerAsyncHandler(String eventName, RfwAsyncEventHandler handler) {
    _asyncHandlers[eventName] = handler;
  }

  /// Unregister a handler for a specific event name.
  void unregisterHandler(String eventName) {
    _handlers.remove(eventName);
    _asyncHandlers.remove(eventName);
  }

  /// Check if a handler is registered for a specific event name.
  bool hasHandler(String eventName) {
    return _handlers.containsKey(eventName) || _asyncHandlers.containsKey(eventName);
  }

  /// Get a list of all registered event names.
  List<String> get registeredEvents => [
    ..._handlers.keys,
    ..._asyncHandlers.keys,
  ];

  /// Handle an event fired from a RemoteWidget.
  ///
  /// This method should be passed to the `onEvent` callback of RemoteWidget:
  /// ```dart
  /// RemoteWidget(
  ///   runtime: runtime,
  ///   data: content,
  ///   widget: widgetName,
  ///   onEvent: actionHandler.handleEvent,
  /// );
  /// ```
  void handleEvent(String name, DynamicMap arguments) {
    final Map<String, Object?> args = _convertDynamicMap(arguments);

    // Log the event
    onEventFired?.call(name, args);
    debugPrint('RFW Event: $name, args: $args');

    // Try synchronous handler first
    final syncHandler = _handlers[name];
    if (syncHandler != null) {
      try {
        syncHandler(args);
      } catch (e, stack) {
        debugPrint('Error in sync handler for "$name": $e\n$stack');
      }
      return;
    }

    // Try async handler
    final asyncHandler = _asyncHandlers[name];
    if (asyncHandler != null) {
      _executeAsyncHandler(name, asyncHandler, args);
      return;
    }

    // No handler found
    _handleUnknownEvent(name, args);
  }

  /// Execute async handler with error handling
  Future<void> _executeAsyncHandler(
    String name,
    RfwAsyncEventHandler handler,
    Map<String, Object?> args,
  ) async {
    try {
      await handler(args);
    } catch (e, stack) {
      debugPrint('Error in async handler for "$name": $e\n$stack');
    }
  }

  /// Handle events that have no registered handler
  void _handleUnknownEvent(String name, Map<String, Object?> args) {
    onUnhandledEvent?.call(name, args);
    debugPrint('Unhandled RFW event: $name, args: $args');
  }

  /// Convert a DynamicMap to a standard Map with String keys
  Map<String, Object?> _convertDynamicMap(DynamicMap dynamicMap) {
    final result = <String, Object?>{};

    for (final key in dynamicMap.keys) {
      final value = dynamicMap[key];
      if (value is DynamicMap) {
        result[key] = _convertDynamicMap(value);
      } else if (value is DynamicList) {
        result[key] = _convertDynamicList(value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Convert a DynamicList to a standard List
  List<Object?> _convertDynamicList(DynamicList dynamicList) {
    final result = <Object?>[];

    for (var i = 0; i < dynamicList.length; i++) {
      final value = dynamicList[i];
      if (value is DynamicMap) {
        result.add(_convertDynamicMap(value));
      } else if (value is DynamicList) {
        result.add(_convertDynamicList(value));
      } else {
        result.add(value);
      }
    }

    return result;
  }

  /// Clear all registered handlers.
  void dispose() {
    _handlers.clear();
    _asyncHandlers.clear();
  }
}

/// A scoped action handler that automatically manages handler lifecycle
/// based on widget lifecycle.
///
/// Usage with ConsumerStatefulWidget:
/// ```dart
/// class _MyPageState extends ConsumerState<MyPage> {
///   late final ScopedActionHandler _actionHandler;
///
///   @override
///   void initState() {
///     super.initState();
///     _actionHandler = ScopedActionHandler();
///     _actionHandler.register('button_pressed', _onButtonPressed);
///   }
///
///   @override
///   void dispose() {
///     _actionHandler.dispose();
///     super.dispose();
///   }
/// }
/// ```
class ScopedActionHandler extends RfwActionHandler {
  final List<String> _registeredEvents = [];

  @override
  void registerHandler(String eventName, RfwEventHandler handler) {
    super.registerHandler(eventName, handler);
    _registeredEvents.add(eventName);
  }

  @override
  void registerAsyncHandler(String eventName, RfwAsyncEventHandler handler) {
    super.registerAsyncHandler(eventName, handler);
    _registeredEvents.add(eventName);
  }

  @override
  void dispose() {
    // Clear all registered events from this scope
    for (final event in _registeredEvents) {
      unregisterHandler(event);
    }
    _registeredEvents.clear();
    super.dispose();
  }
}
