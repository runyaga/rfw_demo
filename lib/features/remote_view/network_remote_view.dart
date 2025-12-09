import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

import '../../core/network/rfw_cache_manager.dart';
import '../../core/network/rfw_repository.dart';
import '../../core/rfw/runtime/rfw_environment.dart';

/// A RemoteWidget that loads its definition from network with caching.
///
/// Features:
/// - Loads widget from network or cache
/// - Falls back to bundled asset on failure
/// - Shows loading indicator while fetching
/// - Shows error widget on failure
/// - Supports pull-to-refresh
class NetworkRemoteView extends StatefulWidget {
  /// The widget ID to load (without .rfw extension)
  final String widgetId;

  /// The widget name within the library
  final String widgetName;

  /// The repository to fetch widgets from
  final RfwRepository repository;

  /// Data to pass to the widget
  final DynamicContent? data;

  /// Event handler
  final void Function(String name, DynamicMap arguments)? onEvent;

  /// Widget to show while loading
  final Widget? loadingWidget;

  /// Builder for error widget
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Whether to show refresh indicator
  final bool enableRefresh;

  const NetworkRemoteView({
    super.key,
    required this.widgetId,
    required this.widgetName,
    required this.repository,
    this.data,
    this.onEvent,
    this.loadingWidget,
    this.errorBuilder,
    this.enableRefresh = true,
  });

  @override
  State<NetworkRemoteView> createState() => _NetworkRemoteViewState();
}

class _NetworkRemoteViewState extends State<NetworkRemoteView> {
  bool _loading = true;
  Object? _error;
  FetchSource? _source;

  @override
  void initState() {
    super.initState();
    _loadWidget();
  }

  @override
  void didUpdateWidget(NetworkRemoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.widgetId != widget.widgetId) {
      _loadWidget();
    }
  }

  Future<void> _loadWidget() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.fetchWidget(widget.widgetId);

      // Decode and register the widget library
      final lib = decodeLibraryBlob(result.data);
      rfwEnvironment.runtime.update(
        LibraryName(<String>[widget.widgetId]),
        lib,
      );

      setState(() {
        _loading = false;
        _source = result.source;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await widget.repository.refreshWidget(widget.widgetId);

      final lib = decodeLibraryBlob(result.data);
      rfwEnvironment.runtime.update(
        LibraryName(<String>[widget.widgetId]),
        lib,
      );

      setState(() {
        _source = result.source;
        _error = null;
      });
    } catch (e) {
      // Keep showing current widget, just show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingWidget ?? const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ?? _buildDefaultError();
    }

    final content = widget.data ?? rfwEnvironment.content;

    final remoteWidget = RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: FullyQualifiedWidgetName(
        LibraryName(<String>[widget.widgetId]),
        widget.widgetName,
      ),
      onEvent: widget.onEvent ?? (name, args) {
        debugPrint('NetworkRemoteView event: $name, args: $args');
      },
    );

    if (widget.enableRefresh) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              remoteWidget,
              if (_source != null) _buildSourceIndicator(),
            ],
          ),
        ),
      );
    }

    return remoteWidget;
  }

  Widget _buildDefaultError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load widget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadWidget,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIndicator() {
    final (icon, label, color) = switch (_source!) {
      FetchSource.network => (Icons.cloud_done, 'Network', Colors.green),
      FetchSource.cache => (Icons.save, 'Cached', Colors.blue),
      FetchSource.bundledAsset => (Icons.inventory, 'Bundled', Colors.orange),
    };

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Source: $label',
            style: TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }
}

/// Provider for RfwRepository singleton
class RfwRepositoryProvider {
  static RfwRepository? _instance;
  static RfwCacheManager? _cacheManager;

  static Future<RfwRepository> getInstance({
    required String baseUrl,
  }) async {
    if (_instance == null) {
      _cacheManager = RfwCacheManager();
      await _cacheManager!.initialize();

      _instance = RfwRepository(
        baseUrl: baseUrl,
        cacheManager: _cacheManager!,
      );
    }
    return _instance!;
  }

  static void dispose() {
    _instance?.dispose();
    _instance = null;
    _cacheManager = null;
  }
}
