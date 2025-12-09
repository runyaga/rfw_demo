import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/rfw_environment.dart';

/// A widget that syncs Riverpod state to RFW DynamicContent and renders remote widgets.
///
/// Per DESIGN.md Section 3 Phase 3 Step 3:
/// "Ensure Runtime.update called on state changes"
class RfwDataWidget extends ConsumerStatefulWidget {
  /// The asset path to the .rfw binary file
  final String assetPath;

  /// The name of the widget to render
  final String widgetName;

  /// Provider that supplies the data for DynamicContent
  final Provider<Map<String, Object>> dataProvider;

  /// Optional callback when an event is fired
  final void Function(String name, DynamicMap arguments)? onEvent;

  const RfwDataWidget({
    required this.assetPath,
    required this.dataProvider,
    this.widgetName = 'Root',
    this.onEvent,
    super.key,
  });

  @override
  ConsumerState<RfwDataWidget> createState() => _RfwDataWidgetState();
}

class _RfwDataWidgetState extends ConsumerState<RfwDataWidget> {
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _ensureInitialized();
    _loadAsset();
  }

  @override
  void didUpdateWidget(RfwDataWidget oldWidget) {
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
      final ByteData data = await rootBundle.load(widget.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final library = decodeLibraryBlob(bytes);

      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      if (mounted) {
        setState(() {
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

  void _syncDataToContent(Map<String, Object> data) {
    // Update DynamicContent with the latest data from Riverpod
    rfwEnvironment.updateContentMap(data);
  }

  void _handleEvent(String name, DynamicMap arguments) {
    widget.onEvent?.call(name, arguments);
  }

  @override
  Widget build(BuildContext context) {
    // Watch the data provider and sync to DynamicContent
    final data = ref.watch(widget.dataProvider);
    _syncDataToContent(data);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
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

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 48),
          const SizedBox(height: 16),
          const Text('Unable to load content'),
          const SizedBox(height: 8),
          Text(_error.toString(), style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAsset,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
