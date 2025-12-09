import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rfw_spike/core/network/rfw_cache_manager.dart';
import 'package:rfw_spike/core/network/rfw_repository.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}

class MockRfwCacheManager extends Mock implements RfwCacheManager {}

class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(Uint8List(0));
  });

  group('FetchResult', () {
    test('creates correctly with all fields', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final expiresAt = DateTime.now().add(const Duration(hours: 1));

      final result = FetchResult(
        data: data,
        source: FetchSource.network,
        etag: '"abc123"',
        expiresAt: expiresAt,
      );

      expect(result.data, equals(data));
      expect(result.source, equals(FetchSource.network));
      expect(result.etag, equals('"abc123"'));
      expect(result.expiresAt, equals(expiresAt));
    });

    test('creates correctly with minimal fields', () {
      final data = Uint8List.fromList([1, 2, 3]);

      final result = FetchResult(
        data: data,
        source: FetchSource.bundledAsset,
      );

      expect(result.data, equals(data));
      expect(result.source, equals(FetchSource.bundledAsset));
      expect(result.etag, isNull);
      expect(result.expiresAt, isNull);
    });
  });

  group('FetchSource', () {
    test('has expected values', () {
      expect(FetchSource.values.length, equals(3));
      expect(FetchSource.values, contains(FetchSource.network));
      expect(FetchSource.values, contains(FetchSource.cache));
      expect(FetchSource.values, contains(FetchSource.bundledAsset));
    });
  });

  group('WidgetFetchException', () {
    test('toString includes widget ID and message', () {
      final exception = WidgetFetchException(
        'test_widget',
        'Failed to load',
      );

      expect(
        exception.toString(),
        contains('test_widget'),
      );
      expect(
        exception.toString(),
        contains('Failed to load'),
      );
    });

    test('stores cause when provided', () {
      final cause = Exception('Root cause');
      final exception = WidgetFetchException(
        'test_widget',
        'Failed to load',
        cause,
      );

      expect(exception.widgetId, equals('test_widget'));
      expect(exception.message, equals('Failed to load'));
      expect(exception.cause, equals(cause));
    });
  });

  group('RfwRepository', () {
    late MockHttpClient mockHttpClient;
    late MockRfwCacheManager mockCacheManager;
    late RfwRepository repository;

    setUp(() {
      mockHttpClient = MockHttpClient();
      mockCacheManager = MockRfwCacheManager();
      repository = RfwRepository(
        baseUrl: 'https://example.com/rfw',
        cacheManager: mockCacheManager,
        httpClient: mockHttpClient,
        timeout: const Duration(seconds: 5),
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('fetchWidget', () {
      test('returns cached data when cache hit', () async {
        final cachedData = Uint8List.fromList([1, 2, 3, 4]);

        when(() => mockCacheManager.get('hello_world'))
            .thenAnswer((_) async => cachedData);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn('"etag"');

        final result = await repository.fetchWidget('hello_world');

        expect(result.source, equals(FetchSource.cache));
        expect(result.data, equals(cachedData));
        expect(result.etag, equals('"etag"'));

        // Verify network was not called
        verifyNever(() => mockHttpClient.get(any(), headers: any(named: 'headers')));
      });

      test('fetches from network on cache miss', () async {
        final networkData = Uint8List.fromList([5, 6, 7, 8]);

        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response.bytes(
              networkData,
              200,
              headers: {'etag': '"new_etag"'},
            ));
        when(() => mockCacheManager.put(
              any(),
              any(),
              etag: any(named: 'etag'),
              ttl: any(named: 'ttl'),
            )).thenAnswer((_) async {});

        final result = await repository.fetchWidget('hello_world');

        expect(result.source, equals(FetchSource.network));
        expect(result.data, equals(networkData));
        expect(result.etag, equals('"new_etag"'));

        // Verify cache was updated
        verify(() => mockCacheManager.put(
              'hello_world',
              networkData,
              etag: '"new_etag"',
              ttl: any(named: 'ttl'),
            )).called(1);
      });

      test('handles 304 Not Modified response', () async {
        final cachedData = Uint8List.fromList([1, 2, 3, 4]);

        // First call returns cache miss
        when(() => mockCacheManager.get('hello_world'))
            .thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn('"old_etag"');

        // Server returns 304
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response('', 304));

        // On 304, we fetch from cache again
        when(() => mockCacheManager.get('hello_world'))
            .thenAnswer((_) async => cachedData);

        final result = await repository.fetchWidget('hello_world');

        expect(result.source, equals(FetchSource.cache));
        expect(result.data, equals(cachedData));
      });

      test('handles network timeout gracefully', () async {
        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenThrow(TimeoutException('Request timed out'));

        // Should fall back to bundled asset, but in test this will throw
        // because rootBundle is not available
        expect(
          () => repository.fetchWidget('hello_world'),
          throwsA(isA<WidgetFetchException>()),
        );
      });

      test('handles HTTP errors gracefully', () async {
        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response('Error', 500));

        // Should fall back to bundled asset
        expect(
          () => repository.fetchWidget('hello_world'),
          throwsA(isA<WidgetFetchException>()),
        );
      });

      test('handles 404 Not Found', () async {
        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response('Not Found', 404));

        // Should fall back to bundled asset
        expect(
          () => repository.fetchWidget('hello_world'),
          throwsA(isA<WidgetFetchException>()),
        );
      });
    });

    group('refreshWidget', () {
      test('removes from cache before fetching', () async {
        when(() => mockCacheManager.remove('hello_world'))
            .thenAnswer((_) async {});
        when(() => mockCacheManager.get('hello_world'))
            .thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response.bytes(
              Uint8List.fromList([1, 2, 3]),
              200,
            ));
        when(() => mockCacheManager.put(
              any(),
              any(),
              etag: any(named: 'etag'),
              ttl: any(named: 'ttl'),
            )).thenAnswer((_) async {});

        await repository.refreshWidget('hello_world');

        verify(() => mockCacheManager.remove('hello_world')).called(1);
      });
    });

    group('prefetch', () {
      test('fetches multiple widgets', () async {
        final widgetData = Uint8List.fromList([1, 2, 3]);

        when(() => mockCacheManager.get(any())).thenAnswer((_) async => widgetData);
        when(() => mockCacheManager.getEtag(any())).thenReturn(null);

        await repository.prefetch(['widget1', 'widget2', 'widget3']);

        verify(() => mockCacheManager.get('widget1')).called(1);
        verify(() => mockCacheManager.get('widget2')).called(1);
        verify(() => mockCacheManager.get('widget3')).called(1);
      });

      test('continues on individual widget failure', () async {
        when(() => mockCacheManager.get('widget1'))
            .thenThrow(Exception('Cache error'));
        when(() => mockCacheManager.get('widget2'))
            .thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
        when(() => mockCacheManager.getEtag(any())).thenReturn(null);

        // Should not throw even if one widget fails
        await repository.prefetch(['widget1', 'widget2']);

        verify(() => mockCacheManager.get('widget2')).called(1);
      });
    });

    group('onWidgetUpdated callback', () {
      test('is called when widget is fetched from network', () async {
        final networkData = Uint8List.fromList([5, 6, 7, 8]);
        String? updatedWidgetId;
        Uint8List? updatedData;

        repository.onWidgetUpdated = (widgetId, data) {
          updatedWidgetId = widgetId;
          updatedData = data;
        };

        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response.bytes(
              networkData,
              200,
            ));
        when(() => mockCacheManager.put(
              any(),
              any(),
              etag: any(named: 'etag'),
              ttl: any(named: 'ttl'),
            )).thenAnswer((_) async {});

        await repository.fetchWidget('hello_world');

        expect(updatedWidgetId, equals('hello_world'));
        expect(updatedData, equals(networkData));
      });

      test('is not called on cache hit', () async {
        final cachedData = Uint8List.fromList([1, 2, 3, 4]);
        var callbackCalled = false;

        repository.onWidgetUpdated = (widgetId, data) {
          callbackCalled = true;
        };

        when(() => mockCacheManager.get('hello_world'))
            .thenAnswer((_) async => cachedData);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn('"etag"');

        await repository.fetchWidget('hello_world');

        expect(callbackCalled, isFalse);
      });
    });

    group('HTTP headers', () {
      test('includes capability handshake headers', () async {
        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn(null);
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response.bytes(
              Uint8List.fromList([1, 2, 3]),
              200,
            ));
        when(() => mockCacheManager.put(
              any(),
              any(),
              etag: any(named: 'etag'),
              ttl: any(named: 'ttl'),
            )).thenAnswer((_) async {});

        await repository.fetchWidget('hello_world');

        final captured = verify(() => mockHttpClient.get(
              any(),
              headers: captureAny(named: 'headers'),
            )).captured.single as Map<String, String>;

        expect(captured['X-Client-Version'], isNotNull);
        expect(captured['X-Client-Widget-Version'], equals('1.0.0'));
        expect(captured['Accept'], equals('application/octet-stream'));
      });

      test('includes If-None-Match when etag exists', () async {
        when(() => mockCacheManager.get('hello_world')).thenAnswer((_) async => null);
        when(() => mockCacheManager.getEtag('hello_world')).thenReturn('"existing_etag"');
        when(() => mockHttpClient.get(
              any(),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => http.Response.bytes(
              Uint8List.fromList([1, 2, 3]),
              200,
            ));
        when(() => mockCacheManager.put(
              any(),
              any(),
              etag: any(named: 'etag'),
              ttl: any(named: 'ttl'),
            )).thenAnswer((_) async {});

        await repository.fetchWidget('hello_world');

        final captured = verify(() => mockHttpClient.get(
              any(),
              headers: captureAny(named: 'headers'),
            )).captured.single as Map<String, String>;

        expect(captured['If-None-Match'], equals('"existing_etag"'));
      });
    });
  });
}
