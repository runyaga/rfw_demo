import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../rfw/runtime/rfw_environment.dart';
import 'rfw_cache_manager.dart';

/// Result of a widget fetch operation
class FetchResult {
  final Uint8List data;
  final FetchSource source;
  final String? etag;
  final DateTime? expiresAt;

  FetchResult({
    required this.data,
    required this.source,
    this.etag,
    this.expiresAt,
  });
}

/// Source of the fetched widget
enum FetchSource {
  network,
  cache,
  bundledAsset,
}

/// Exception thrown when widget fetch fails completely
class WidgetFetchException implements Exception {
  final String widgetId;
  final String message;
  final Object? cause;

  WidgetFetchException(this.widgetId, this.message, [this.cause]);

  @override
  String toString() => 'WidgetFetchException: $message (widgetId: $widgetId)';
}

/// Repository for fetching RFW widget binaries from network with caching.
///
/// Per DESIGN.md Section 3 Phase 4:
/// - Fetches widgets from server
/// - Caches successfully downloaded widgets
/// - Falls back to bundled assets on failure
/// - Implements capability handshake via version headers
class RfwRepository {
  final String baseUrl;
  final RfwCacheManager cacheManager;
  final http.Client _httpClient;
  final Duration timeout;

  /// Callback when a widget is updated from network
  void Function(String widgetId, Uint8List data)? onWidgetUpdated;

  RfwRepository({
    required this.baseUrl,
    required this.cacheManager,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _httpClient = httpClient ?? http.Client();

  /// Fetch a widget by ID with fallback chain:
  /// 1. Check cache (if not expired)
  /// 2. Fetch from network
  /// 3. Fall back to bundled asset
  Future<FetchResult> fetchWidget(String widgetId) async {
    // 1. Check cache first
    final cached = await cacheManager.get(widgetId);
    if (cached != null) {
      debugPrint('RfwRepository: Cache hit for $widgetId');
      return FetchResult(
        data: cached,
        source: FetchSource.cache,
        etag: cacheManager.getEtag(widgetId),
      );
    }

    // 2. Try network fetch
    try {
      final result = await _fetchFromNetwork(widgetId);
      if (result != null) {
        debugPrint('RfwRepository: Network fetch succeeded for $widgetId');
        return result;
      }
    } catch (e) {
      debugPrint('RfwRepository: Network fetch failed for $widgetId: $e');
    }

    // 3. Fall back to bundled asset
    debugPrint('RfwRepository: Falling back to bundled asset for $widgetId');
    return _loadBundledAsset(widgetId);
  }

  /// Fetch from network with version handshake
  Future<FetchResult?> _fetchFromNetwork(String widgetId) async {
    final uri = Uri.parse('$baseUrl/widgets/$widgetId.rfw');
    final etag = cacheManager.getEtag(widgetId);

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          // Capability handshake (DESIGN.md Section 5.1)
          'X-Client-Version': kClientVersion,
          'X-Client-Widget-Version': '1.0.0',
          // Conditional request for cache validation
          if (etag != null) 'If-None-Match': etag,
          'Accept': 'application/octet-stream',
        },
      ).timeout(timeout);

      switch (response.statusCode) {
        case 200:
          // Success - cache and return
          final data = response.bodyBytes;
          final newEtag = response.headers['etag'];
          final cacheControl = response.headers['cache-control'];
          final maxAge = _parseMaxAge(cacheControl);

          await cacheManager.put(
            widgetId,
            data,
            etag: newEtag,
            ttl: maxAge,
          );

          // Notify listeners
          onWidgetUpdated?.call(widgetId, data);

          return FetchResult(
            data: data,
            source: FetchSource.network,
            etag: newEtag,
            expiresAt: maxAge != null ? DateTime.now().add(maxAge) : null,
          );

        case 304:
          // Not modified - use cached version
          debugPrint('RfwRepository: 304 Not Modified for $widgetId');
          final cached = await cacheManager.get(widgetId);
          if (cached != null) {
            return FetchResult(
              data: cached,
              source: FetchSource.cache,
              etag: etag,
            );
          }
          return null;

        case 404:
          // Widget not found on server - use bundled
          debugPrint('RfwRepository: 404 Not Found for $widgetId');
          return null;

        case 426:
          // Upgrade required - client version too old
          debugPrint('RfwRepository: 426 Upgrade Required for $widgetId');
          // Could trigger app update prompt here
          return null;

        default:
          // Server error or unexpected response
          debugPrint('RfwRepository: HTTP ${response.statusCode} for $widgetId');
          return null;
      }
    } on TimeoutException {
      debugPrint('RfwRepository: Timeout fetching $widgetId');
      return null;
    } on http.ClientException catch (e) {
      debugPrint('RfwRepository: Client error fetching $widgetId: $e');
      return null;
    }
  }

  /// Load widget from bundled assets
  Future<FetchResult> _loadBundledAsset(String widgetId) async {
    try {
      final data = await rootBundle.load('assets/rfw/defaults/$widgetId.rfw');
      return FetchResult(
        data: data.buffer.asUint8List(),
        source: FetchSource.bundledAsset,
      );
    } catch (e) {
      throw WidgetFetchException(
        widgetId,
        'Widget not found in bundled assets',
        e,
      );
    }
  }

  /// Parse max-age from Cache-Control header
  Duration? _parseMaxAge(String? cacheControl) {
    if (cacheControl == null) return null;

    final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
    if (match != null) {
      final seconds = int.tryParse(match.group(1)!);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }
    return null;
  }

  /// Force refresh a widget from network (bypass cache)
  Future<FetchResult> refreshWidget(String widgetId) async {
    // Remove from cache first
    await cacheManager.remove(widgetId);

    // Then fetch fresh
    return fetchWidget(widgetId);
  }

  /// Prefetch widgets in background
  Future<void> prefetch(List<String> widgetIds) async {
    for (final widgetId in widgetIds) {
      try {
        await fetchWidget(widgetId);
      } catch (e) {
        debugPrint('RfwRepository: Prefetch failed for $widgetId: $e');
      }
    }
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
