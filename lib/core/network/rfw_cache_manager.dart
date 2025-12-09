import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cache entry metadata
class CacheEntry {
  final String widgetId;
  final DateTime cachedAt;
  final DateTime? expiresAt;
  final String? etag;
  final int size;

  CacheEntry({
    required this.widgetId,
    required this.cachedAt,
    this.expiresAt,
    this.etag,
    required this.size,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
    'widgetId': widgetId,
    'cachedAt': cachedAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'etag': etag,
    'size': size,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    widgetId: json['widgetId'] as String,
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    expiresAt: json['expiresAt'] != null
        ? DateTime.parse(json['expiresAt'] as String)
        : null,
    etag: json['etag'] as String?,
    size: json['size'] as int,
  );
}

/// File-based cache manager for RFW widget binaries.
///
/// Per DESIGN.md Section 3 Phase 4 Step 2:
/// "Cache downloaded .rfw files using flutter_cache_manager or raw file I/O"
///
/// This implementation uses raw file I/O for simplicity and control.
class RfwCacheManager {
  final Duration defaultTtl;
  final int maxCacheSize;

  Directory? _cacheDir;
  final Map<String, CacheEntry> _entries = {};
  bool _initialized = false;

  RfwCacheManager({
    this.defaultTtl = const Duration(hours: 24),
    this.maxCacheSize = 50 * 1024 * 1024, // 50 MB default
  });

  /// Initialize the cache manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationCacheDirectory();
      _cacheDir = Directory('${appDir.path}/rfw_widgets');

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      // Load existing cache entries
      await _loadCacheIndex();
      _initialized = true;
      debugPrint('RfwCacheManager initialized at: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('Failed to initialize RfwCacheManager: $e');
      // Continue without caching on web or if initialization fails
      _initialized = true;
    }
  }

  /// Get cached widget binary by ID
  Future<Uint8List?> get(String widgetId) async {
    if (!_initialized) await initialize();
    if (_cacheDir == null) return null;

    final entry = _entries[widgetId];
    if (entry == null) {
      debugPrint('Cache miss: $widgetId');
      return null;
    }

    if (entry.isExpired) {
      debugPrint('Cache expired: $widgetId');
      await remove(widgetId);
      return null;
    }

    final file = _getFile(widgetId);
    if (!await file.exists()) {
      debugPrint('Cache file missing: $widgetId');
      _entries.remove(widgetId);
      return null;
    }

    debugPrint('Cache hit: $widgetId');
    return file.readAsBytes();
  }

  /// Store widget binary in cache
  Future<void> put(
    String widgetId,
    Uint8List data, {
    Duration? ttl,
    String? etag,
  }) async {
    if (!_initialized) await initialize();
    if (_cacheDir == null) return;

    final effectiveTtl = ttl ?? defaultTtl;
    final now = DateTime.now();

    // Atomic write: write to temp file then rename
    final tempFile = _getTempFile(widgetId);
    final targetFile = _getFile(widgetId);

    try {
      // Write to temp file
      await tempFile.writeAsBytes(data, flush: true);

      // Atomic rename
      await tempFile.rename(targetFile.path);

      // Update cache entry
      _entries[widgetId] = CacheEntry(
        widgetId: widgetId,
        cachedAt: now,
        expiresAt: now.add(effectiveTtl),
        etag: etag,
        size: data.length,
      );

      // Save cache index
      await _saveCacheIndex();

      // Evict if over size limit
      await _evictIfNeeded();

      debugPrint('Cached: $widgetId (${data.length} bytes, ttl: $effectiveTtl)');
    } catch (e) {
      debugPrint('Failed to cache $widgetId: $e');
      // Clean up temp file if it exists
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Remove a widget from cache
  Future<void> remove(String widgetId) async {
    if (!_initialized) await initialize();
    if (_cacheDir == null) return;

    final file = _getFile(widgetId);
    if (await file.exists()) {
      await file.delete();
    }

    _entries.remove(widgetId);
    await _saveCacheIndex();
    debugPrint('Removed from cache: $widgetId');
  }

  /// Clear all cached widgets
  Future<void> clear() async {
    if (!_initialized) await initialize();
    if (_cacheDir == null) return;

    try {
      await _cacheDir!.delete(recursive: true);
      await _cacheDir!.create(recursive: true);
      _entries.clear();
      debugPrint('Cache cleared');
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Check if widget is cached (and not expired)
  Future<bool> contains(String widgetId) async {
    if (!_initialized) await initialize();

    final entry = _entries[widgetId];
    if (entry == null || entry.isExpired) return false;

    final file = _getFile(widgetId);
    return file.exists();
  }

  /// Get ETag for cached widget (for conditional requests)
  String? getEtag(String widgetId) {
    return _entries[widgetId]?.etag;
  }

  /// Get total cache size in bytes
  int get totalSize {
    return _entries.values.fold(0, (sum, entry) => sum + entry.size);
  }

  /// Get number of cached widgets
  int get count => _entries.length;

  // Private helpers

  File _getFile(String widgetId) {
    return File('${_cacheDir!.path}/$widgetId.rfw');
  }

  File _getTempFile(String widgetId) {
    return File('${_cacheDir!.path}/$widgetId.rfw.tmp');
  }

  File get _indexFile => File('${_cacheDir!.path}/_index.json');

  Future<void> _loadCacheIndex() async {
    try {
      final indexFile = _indexFile;
      if (!await indexFile.exists()) return;

      final content = await indexFile.readAsString();
      // Simple JSON parsing without importing dart:convert in multiple places
      // For production, use proper JSON encoding
      final lines = content.split('\n').where((l) => l.isNotEmpty);

      for (final line in lines) {
        try {
          // Parse simple key=value format for portability
          final parts = line.split('|');
          if (parts.length >= 4) {
            final entry = CacheEntry(
              widgetId: parts[0],
              cachedAt: DateTime.parse(parts[1]),
              expiresAt: parts[2].isNotEmpty ? DateTime.parse(parts[2]) : null,
              etag: parts[3].isNotEmpty ? parts[3] : null,
              size: parts.length > 4 ? int.parse(parts[4]) : 0,
            );
            _entries[entry.widgetId] = entry;
          }
        } catch (e) {
          debugPrint('Failed to parse cache entry: $line');
        }
      }

      debugPrint('Loaded ${_entries.length} cache entries');
    } catch (e) {
      debugPrint('Failed to load cache index: $e');
    }
  }

  Future<void> _saveCacheIndex() async {
    if (_cacheDir == null) return;

    try {
      final lines = _entries.values.map((e) {
        return '${e.widgetId}|${e.cachedAt.toIso8601String()}|'
            '${e.expiresAt?.toIso8601String() ?? ''}|${e.etag ?? ''}|${e.size}';
      }).join('\n');

      await _indexFile.writeAsString(lines);
    } catch (e) {
      debugPrint('Failed to save cache index: $e');
    }
  }

  Future<void> _evictIfNeeded() async {
    if (totalSize <= maxCacheSize) return;

    // Sort entries by cachedAt (oldest first)
    final sortedEntries = _entries.values.toList()
      ..sort((a, b) => a.cachedAt.compareTo(b.cachedAt));

    // Remove oldest entries until under limit
    for (final entry in sortedEntries) {
      if (totalSize <= maxCacheSize * 0.8) break; // Keep 20% headroom

      await remove(entry.widgetId);
      debugPrint('Evicted: ${entry.widgetId} (cache size: $totalSize)');
    }
  }
}
