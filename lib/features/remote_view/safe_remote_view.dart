import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import '../../core/rfw/runtime/rfw_environment.dart';

/// A wrapper around RemoteWidget with robust error handling and fallback support.
///
/// Implements the Layered Error Handling approach from QUESTIONS.md Section 4:
/// - Layer 1: Data Defaults (handled in DynamicContent)
/// - Layer 2: Widget Fallbacks (unknown widget -> SizedBox.shrink)
/// - Layer 3: Screen-Level Recovery (ErrorCard with retry)
/// - Layer 4: Crash Prevention (catch stack overflow)
class SafeRemoteView extends StatefulWidget {
  /// Primary asset path to load
  final String assetPath;

  /// Fallback asset path if primary fails (offline-first strategy)
  final String? fallbackAssetPath;

  /// The name of the widget to render
  final String widgetName;

  /// Optional callback when an event is fired
  final void Function(String name, DynamicMap arguments)? onEvent;

  /// Optional callback when an error occurs (for logging/analytics)
  final void Function(Object error, StackTrace? stack)? onError;

  /// Custom fallback widget when all else fails
  final Widget? fallbackWidget;

  const SafeRemoteView({
    required this.assetPath,
    this.fallbackAssetPath,
    this.widgetName = 'Root',
    this.onEvent,
    this.onError,
    this.fallbackWidget,
    super.key,
  });

  @override
  State<SafeRemoteView> createState() => _SafeRemoteViewState();
}

class _SafeRemoteViewState extends State<SafeRemoteView> {
  bool _loading = true;
  Object? _error;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
    _loadAsset();
  }

  @override
  void didUpdateWidget(SafeRemoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _loadAsset();
    }
  }

  void _ensureInitialized() {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }
  }

  Future<void> _loadAsset() async {
    setState(() {
      _loading = true;
      _error = null;
      _usingFallback = false;
    });

    // Try primary asset first
    final primarySuccess = await _tryLoadAsset(widget.assetPath);

    if (!primarySuccess && widget.fallbackAssetPath != null) {
      // Try fallback asset (DESIGN.md Section 3 Phase 2 Step 3)
      debugPrint('Primary asset failed, trying fallback: ${widget.fallbackAssetPath}');
      final fallbackSuccess = await _tryLoadAsset(widget.fallbackAssetPath!);
      if (fallbackSuccess && mounted) {
        setState(() {
          _usingFallback = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<bool> _tryLoadAsset(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode with crash prevention (Layer 4)
      final library = _decodeSecurely(bytes);

      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      if (mounted) {
        setState(() {
          _error = null;
        });
      }
      return true;
    } catch (e, stack) {
      _reportError(e, stack);
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
      return false;
    }
  }

  /// Layer 4: Crash Prevention - secure decoding with error catching
  RemoteWidgetLibrary _decodeSecurely(Uint8List bytes) {
    try {
      return decodeLibraryBlob(bytes);
    } on StackOverflowError catch (e, stack) {
      _reportError(e, stack);
      rethrow;
    }
  }

  void _reportError(Object error, StackTrace? stack) {
    widget.onError?.call(error, stack);
    debugPrint('SafeRemoteView error: $error');
  }

  void _handleEvent(String name, DynamicMap arguments) {
    widget.onEvent?.call(name, arguments);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      // Layer 3: Screen-Level Recovery
      return widget.fallbackWidget ?? _buildErrorRecovery();
    }

    // Layer 4: Wrap in error boundary for render-time crashes
    return _ErrorBoundary(
      onError: _reportError,
      fallback: widget.fallbackWidget ?? _buildErrorRecovery(),
      child: Column(
        children: [
          if (_usingFallback)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Offline mode - showing cached content',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: rfwEnvironment.content,
              widget: FullyQualifiedWidgetName(
                const LibraryName(<String>['main']),
                widget.widgetName,
              ),
              onEvent: _handleEvent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRecovery() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAsset,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple error boundary widget for catching render-time errors
class _ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget fallback;
  final void Function(Object error, StackTrace? stack) onError;

  const _ErrorBoundary({
    required this.child,
    required this.fallback,
    required this.onError,
  });

  @override
  State<_ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<_ErrorBoundary> {
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    _hasError = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback;
    }

    // Note: Flutter doesn't have true error boundaries like React.
    // Errors during build will still propagate. This is a best-effort approach.
    // For production, consider using ErrorWidget.builder globally.
    return widget.child;
  }
}
