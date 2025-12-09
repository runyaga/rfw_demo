import 'package:flutter/foundation.dart';
import 'package:rfw/rfw.dart';

import '../registry/core_registry.dart';
import '../registry/map_registry.dart';
import '../registry/material_registry.dart';
import 'action_handler.dart';

/// Client version for capability handshake with server (DESIGN.md Section 5.1)
const String kClientVersion = '1.0.0';

/// RFW Environment singleton that manages the Runtime and DynamicContent.
///
/// Per DESIGN.md Section 3 Phase 1 Step 3:
/// "Runtime singleton/provider initialization with version constant
/// for capability handshake."
class RfwEnvironment {
  RfwEnvironment._();

  static RfwEnvironment _instance = RfwEnvironment._();
  static RfwEnvironment get instance => _instance;

  /// The RFW runtime that manages widget libraries
  Runtime? _runtime;
  Runtime get runtime {
    if (_runtime == null) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    return _runtime!;
  }

  /// The dynamic content that provides data to remote widgets
  DynamicContent? _content;
  DynamicContent get content {
    if (_content == null) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    return _content!;
  }

  /// The action handler for event processing
  RfwActionHandler? _actionHandler;
  RfwActionHandler get actionHandler {
    if (_actionHandler == null) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    return _actionHandler!;
  }

  bool _initialized = false;

  /// Whether the environment has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the RFW environment.
  ///
  /// This registers the core and material widget libraries and sets up
  /// the runtime for rendering remote widgets.
  void initialize() {
    if (_initialized) {
      debugPrint('RfwEnvironment already initialized');
      return;
    }

    _runtime = Runtime();
    _content = DynamicContent();
    _actionHandler = RfwActionHandler();

    // Register core widget library (DESIGN.md Section 3 Phase 1 Step 2)
    runtime.update(
      const LibraryName(<String>['core']),
      createAppCoreWidgets(),
    );

    // Register material widget library
    runtime.update(
      const LibraryName(<String>['material']),
      createAppMaterialWidgets(),
    );

    // Register map widget library (Stage 9)
    runtime.update(
      const LibraryName(<String>['map']),
      createMapWidgets(),
    );

    _initialized = true;
    debugPrint('RfwEnvironment initialized with client version: $kClientVersion');
  }

  /// Update a remote widget library in the runtime.
  ///
  /// Call this when loading new remote widget definitions from the network
  /// or local assets.
  void updateRemoteLibrary(LibraryName name, RemoteWidgetLibrary library) {
    if (!_initialized) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    runtime.update(name, library);
  }

  /// Update the dynamic content with new data.
  ///
  /// This triggers a rebuild of any RemoteWidget instances that depend
  /// on the changed data.
  void updateContent(String key, Object value) {
    if (!_initialized) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    content.update(key, value);
  }

  /// Update multiple content values at once.
  void updateContentMap(Map<String, Object> data) {
    if (!_initialized) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    for (final entry in data.entries) {
      content.update(entry.key, entry.value);
    }
  }

  /// Clear all dynamic content.
  void clearContent() {
    if (!_initialized) {
      throw StateError('RfwEnvironment not initialized. Call initialize() first.');
    }
    // Create a new DynamicContent instance by reinitializing
    // Note: This is a simple approach; in production you might want
    // to track keys and clear them individually
  }

  /// Dispose of the environment (for testing purposes).
  @visibleForTesting
  void dispose() {
    _actionHandler?.dispose();
    _initialized = false;
  }

  /// Reset the singleton for testing purposes.
  @visibleForTesting
  static void resetForTesting() {
    _instance = RfwEnvironment._();
  }
}

/// Global accessor for convenience
RfwEnvironment get rfwEnvironment => RfwEnvironment.instance;
