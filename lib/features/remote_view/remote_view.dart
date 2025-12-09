import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import '../../core/rfw/runtime/rfw_environment.dart';

/// A widget that renders remote widget definitions from bundled assets.
///
/// Per DESIGN.md Section 3 Phase 2:
/// "Prove the rendering pipeline using bundled assets before adding
/// network complexity."
class RemoteView extends StatefulWidget {
  /// The asset path to the .rfw binary file
  final String assetPath;

  /// The name of the widget to render (defaults to 'Root')
  final String widgetName;

  /// Optional callback when an event is fired from the remote widget
  final void Function(String name, DynamicMap arguments)? onEvent;

  /// Optional widget to show while loading
  final Widget? loadingWidget;

  /// Optional widget to show on error
  final Widget Function(Object error)? errorBuilder;

  const RemoteView({
    required this.assetPath,
    this.widgetName = 'Root',
    this.onEvent,
    this.loadingWidget,
    this.errorBuilder,
    super.key,
  });

  @override
  State<RemoteView> createState() => _RemoteViewState();
}

class _RemoteViewState extends State<RemoteView> {
  bool _loading = true;
  Object? _error;
  RemoteWidgetLibrary? _library;

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
    _loadAsset();
  }

  @override
  void didUpdateWidget(RemoteView oldWidget) {
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
    });

    try {
      // Load binary asset from bundle
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();

      // Decode the binary format
      final library = decodeLibraryBlob(bytes);

      // Update the runtime with the loaded library
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      if (mounted) {
        setState(() {
          _library = library;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _handleEvent(String name, DynamicMap arguments) {
    widget.onEvent?.call(name, arguments);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          _buildDefaultError(_error!);
    }

    if (_library == null) {
      return widget.errorBuilder?.call('Library not loaded') ??
          _buildDefaultError('Library not loaded');
    }

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: rfwEnvironment.content,
      widget: FullyQualifiedWidgetName(
        const LibraryName(<String>['main']),
        widget.widgetName,
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildDefaultError(Object error) {
    // Layer 3: Screen-Level Recovery (QUESTIONS.md Section 4)
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
              error.toString(),
              style: const TextStyle(color: Colors.grey),
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
