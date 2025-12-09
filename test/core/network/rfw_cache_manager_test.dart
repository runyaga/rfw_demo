import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_spike/core/network/rfw_cache_manager.dart';

void main() {
  group('CacheEntry', () {
    test('isExpired returns false when expiresAt is null', () {
      final entry = CacheEntry(
        widgetId: 'test',
        cachedAt: DateTime.now(),
        size: 100,
      );
      expect(entry.isExpired, isFalse);
    });

    test('isExpired returns false when not expired', () {
      final entry = CacheEntry(
        widgetId: 'test',
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        size: 100,
      );
      expect(entry.isExpired, isFalse);
    });

    test('isExpired returns true when expired', () {
      final entry = CacheEntry(
        widgetId: 'test',
        cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        size: 100,
      );
      expect(entry.isExpired, isTrue);
    });

    test('toJson and fromJson round-trip correctly', () {
      final original = CacheEntry(
        widgetId: 'test_widget',
        cachedAt: DateTime(2024, 1, 15, 10, 30),
        expiresAt: DateTime(2024, 1, 16, 10, 30),
        etag: '"abc123"',
        size: 1024,
      );

      final json = original.toJson();
      final restored = CacheEntry.fromJson(json);

      expect(restored.widgetId, equals(original.widgetId));
      expect(restored.cachedAt, equals(original.cachedAt));
      expect(restored.expiresAt, equals(original.expiresAt));
      expect(restored.etag, equals(original.etag));
      expect(restored.size, equals(original.size));
    });
  });

  group('RfwCacheManager (unit tests)', () {
    late Directory tempDir;
    late RfwCacheManager cacheManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rfw_cache_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('totalSize calculates correctly with no entries', () {
      cacheManager = RfwCacheManager();
      expect(cacheManager.totalSize, equals(0));
    });

    test('count returns 0 for new cache manager', () {
      cacheManager = RfwCacheManager();
      expect(cacheManager.count, equals(0));
    });

    test('getEtag returns null for unknown widget', () {
      cacheManager = RfwCacheManager();
      expect(cacheManager.getEtag('unknown'), isNull);
    });

    test('default TTL is 24 hours', () {
      cacheManager = RfwCacheManager();
      expect(cacheManager.defaultTtl, equals(const Duration(hours: 24)));
    });

    test('default max cache size is 50 MB', () {
      cacheManager = RfwCacheManager();
      expect(cacheManager.maxCacheSize, equals(50 * 1024 * 1024));
    });

    test('custom TTL and max size are respected', () {
      cacheManager = RfwCacheManager(
        defaultTtl: const Duration(minutes: 30),
        maxCacheSize: 10 * 1024 * 1024,
      );
      expect(cacheManager.defaultTtl, equals(const Duration(minutes: 30)));
      expect(cacheManager.maxCacheSize, equals(10 * 1024 * 1024));
    });
  });

  group('RfwCacheManager (behavior tests)', () {
    test('cache operations handle uninitialized state gracefully', () async {
      // This test verifies the cache manager handles being used
      // before explicit initialization (it auto-initializes)
      final cacheManager = RfwCacheManager();

      // These should not throw even before initialization
      expect(cacheManager.count, equals(0));
      expect(cacheManager.totalSize, equals(0));
      expect(cacheManager.getEtag('test'), isNull);
    });

    test('contains returns false for non-existent widget', () async {
      final cacheManager = RfwCacheManager();
      // Will auto-initialize, but should still return false
      // Note: In test environment without proper path_provider setup,
      // this may fail gracefully
      final exists = await cacheManager.contains('nonexistent');
      expect(exists, isFalse);
    });
  });
}
