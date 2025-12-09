import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

import '../../../core/network/rfw_cache_manager.dart';
import '../../../core/network/rfw_repository.dart';
import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page showcasing Stage 7: Network Layer & Caching
///
/// Demonstrates:
/// - Loading widgets from network (simulated with bundled fallback)
/// - Cache status indicators
/// - Manual cache clearing
/// - Refresh functionality
class NetworkDemoPage extends StatefulWidget {
  const NetworkDemoPage({super.key});

  @override
  State<NetworkDemoPage> createState() => _NetworkDemoPageState();
}

class _NetworkDemoPageState extends State<NetworkDemoPage> {
  RfwCacheManager? _cacheManager;
  RfwRepository? _repository;
  bool _initialized = false;
  final List<String> _logEntries = [];

  // Store loaded widget data to avoid re-fetching
  final Map<String, _LoadedWidget> _loadedWidgets = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }

    _cacheManager = RfwCacheManager(
      defaultTtl: const Duration(minutes: 5),
      maxCacheSize: 10 * 1024 * 1024, // 10 MB for demo
    );
    await _cacheManager!.initialize();

    _repository = RfwRepository(
      // In production, this would be your widget server URL
      // For demo, network will fail and fall back to bundled assets
      baseUrl: 'https://example.com/rfw',
      cacheManager: _cacheManager!,
      timeout: const Duration(seconds: 3),
    );

    _repository!.onWidgetUpdated = (widgetId, data) {
      _addLogEntry('Widget updated: $widgetId (${data.length} bytes)');
    };

    _addLogEntry('Repository initialized');

    // Load all widgets
    await _loadAllWidgets();

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  Future<void> _loadAllWidgets() async {
    final widgets = [
      ('hello_world', 'Root'),
      ('info_card', 'InfoCard'),
      ('status_badge', 'StatusBadge'),
    ];

    for (final (widgetId, widgetName) in widgets) {
      await _loadWidget(widgetId, widgetName);
    }
  }

  Future<void> _loadWidget(String widgetId, String widgetName) async {
    try {
      final result = await _repository!.fetchWidget(widgetId);

      // Decode and register the widget
      final lib = decodeLibraryBlob(result.data);
      rfwEnvironment.runtime.update(
        LibraryName(<String>[widgetId]),
        lib,
      );

      _loadedWidgets[widgetId] = _LoadedWidget(
        widgetName: widgetName,
        source: result.source,
        error: null,
      );
      _addLogEntry('Loaded $widgetId from ${result.source.name}');
    } catch (e) {
      _loadedWidgets[widgetId] = _LoadedWidget(
        widgetName: widgetName,
        source: null,
        error: e.toString(),
      );
      _addLogEntry('Error loading $widgetId: $e');
    }
  }

  void _addLogEntry(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logEntries.insert(0, '[$timestamp] $message');
    if (_logEntries.length > 50) {
      _logEntries.removeLast();
    }
  }

  @override
  void dispose() {
    _repository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 7: Network & Caching'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Widgets',
            onPressed: _reloadWidgets,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Cache',
            onPressed: _clearCache,
          ),
        ],
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(),
                  const SizedBox(height: 16),
                  _buildCacheStatus(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Network Widget Loading'),
                  _buildWidgetDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Fetch Log'),
                  _buildLog(),
                ],
              ),
            ),
    );
  }

  Widget _buildDescription() {
    return Card(
      color: Colors.blue.shade50,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stage 7: Network Layer & Caching',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This demo showcases the network layer infrastructure for fetching '
              'RFW widgets over-the-air with robust fallback mechanisms.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Features Demonstrated:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '• Fallback Chain - Widgets are fetched using a 3-tier strategy: '
              'cache → network → bundled assets. Since no server exists, '
              'you\'ll see widgets load from "Bundled" source.\n\n'
              '• File-Based Caching - RfwCacheManager stores downloaded widgets '
              'on disk with TTL-based expiration and LRU eviction. Note: Only '
              'network-fetched widgets are cached; bundled assets are not cached '
              '(they\'re already available locally).\n\n'
              '• Atomic Downloads - Widgets are written to temp files first, '
              'then atomically renamed to prevent corruption.\n\n'
              '• Cache Status - Shows current cache entries and total size. '
              'Cache will show 0 entries when using bundled fallback (expected). '
              'With a real server, successful network fetches would populate the cache.\n\n'
              '• Prefetch - "Prefetch All" attempts to load widgets into cache. '
              'Without a server, this falls back to bundled assets (not cached).\n\n'
              '• Source Indicators - Orange "Bundled" badges show each widget\'s '
              'load source. With a real server: green = "Network", blue = "Cached".\n\n'
              '• Fetch Log - Displays timestamped fetch operations. '
              'Use the reload button in the app bar to refresh widgets.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatus() {
    final cacheCount = _cacheManager?.count ?? 0;
    final cacheSize = _cacheManager?.totalSize ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cache Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip('Entries', '$cacheCount'),
                const SizedBox(width: 8),
                _buildStatChip('Size', _formatBytes(cacheSize)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearCache,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Clear Cache'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prefetchWidgets,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Prefetch All'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Chip(
      label: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWidgetDemo() {
    return Column(
      children: [
        _buildWidgetCard('hello_world'),
        const SizedBox(height: 12),
        _buildWidgetCard('info_card'),
        const SizedBox(height: 12),
        _buildWidgetCard('status_badge'),
      ],
    );
  }

  Widget _buildWidgetCard(String widgetId) {
    final loaded = _loadedWidgets[widgetId];
    // Different heights for different widget types
    final height = widgetId == 'info_card' ? 160.0 : 80.0;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  widgetId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (loaded?.source != null)
                  _buildSourceBadge(loaded!.source!),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: height,
            child: loaded == null
                ? const Center(child: CircularProgressIndicator())
                : loaded.error != null
                    ? Center(
                        child: Text(
                          'Error: ${loaded.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      )
                    : _buildRemoteWidget(widgetId, loaded.widgetName),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteWidget(String widgetId, String widgetName) {
    // Set up data for the widget
    final content = DynamicContent();
    if (widgetId == 'info_card') {
      content.update('title', 'Network Loaded Card');
      content.update('description', 'This widget was loaded via RfwRepository');
    } else if (widgetId == 'status_badge') {
      content.update('status', 'active');
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: FullyQualifiedWidgetName(
          LibraryName(<String>[widgetId]),
          widgetName,
        ),
        onEvent: (name, args) {
          _addLogEntry('Event from $widgetId: $name');
          setState(() {}); // Refresh to show new log entry
        },
      ),
    );
  }

  Widget _buildSourceBadge(FetchSource source) {
    final (color, label) = switch (source) {
      FetchSource.network => (Colors.green, 'Network'),
      FetchSource.cache => (Colors.blue, 'Cached'),
      FetchSource.bundledAsset => (Colors.orange, 'Bundled'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLog() {
    return Card(
      color: Colors.grey.shade100,
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Text(
            _logEntries.isEmpty ? 'No log entries yet' : _logEntries.join('\n'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
          ),
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    await _cacheManager?.clear();
    _addLogEntry('Cache cleared');
    setState(() {});
  }

  Future<void> _reloadWidgets() async {
    setState(() => _initialized = false);
    _loadedWidgets.clear();
    _addLogEntry('Reloading widgets...');
    await _loadAllWidgets();
    _addLogEntry('Reload complete');
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  Future<void> _prefetchWidgets() async {
    _addLogEntry('Prefetching widgets...');
    await _repository?.prefetch([
      'hello_world',
      'info_card',
      'status_badge',
    ]);
    _addLogEntry('Prefetch complete');
    setState(() {});
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Helper class to store loaded widget state
class _LoadedWidget {
  final String widgetName;
  final FetchSource? source;
  final String? error;

  _LoadedWidget({
    required this.widgetName,
    required this.source,
    required this.error,
  });
}
