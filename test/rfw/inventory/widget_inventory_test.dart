import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';

import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';

void main() {
  setUpAll(() {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }
  });

  group('ProductCard (Example 8)', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/product_card.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    test('decodes without error', () {
      expect(lib, isNotNull);
    });

    testWidgets('renders with all data fields', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['product_card']), lib);

      final content = DynamicContent();
      content.update('imageLabel', 'Test Image');
      content.update('title', 'Test Product');
      content.update('subtitle', 'Test subtitle');
      content.update('price', '\$99.99');
      content.update('productId', 'test-001');
      content.update('actionType', 'buy');
      content.update('actionLabel', 'Buy Now');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['product_card']),
                'ProductCard',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('Test subtitle'), findsOneWidget);
      expect(find.text('\$99.99'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
    });

    testWidgets('fires product_action event', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['product_card']), lib);

      final content = DynamicContent();
      content.update('imageLabel', 'Image');
      content.update('title', 'Product');
      content.update('subtitle', 'Desc');
      content.update('price', '\$10');
      content.update('productId', 'prod-xyz');
      content.update('actionType', 'add_to_cart');
      content.update('actionLabel', 'Add');

      String? eventName;
      DynamicMap? eventArgs;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['product_card']),
                'ProductCard',
              ),
              onEvent: (name, args) {
                eventName = name;
                eventArgs = args;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add'));
      await tester.pump();

      expect(eventName, equals('product_action'));
      expect(eventArgs?['productId'], equals('prod-xyz'));
      expect(eventArgs?['action'], equals('add_to_cart'));
    });
  });

  group('FeedItemPost (Example 9)', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/feed_item_post.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    test('decodes without error', () {
      expect(lib, isNotNull);
    });

    testWidgets('renders post content', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['feed_item_post']), lib);

      final content = DynamicContent();
      content.update('authorInitial', 'A');
      content.update('authorName', 'Alice');
      content.update('timestamp', '1h ago');
      content.update('content', 'Hello world post content');
      content.update('postId', 'post-1');
      content.update('likeCount', '10');
      content.update('commentCount', '5');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['feed_item_post']),
                  'FeedItemPost',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Hello world post content'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('fires post_like event', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['feed_item_post']), lib);

      final content = DynamicContent();
      content.update('authorInitial', 'B');
      content.update('authorName', 'Bob');
      content.update('timestamp', '2h ago');
      content.update('content', 'Test post');
      content.update('postId', 'post-like-test');
      content.update('likeCount', '0');
      content.update('commentCount', '0');

      String? eventName;
      DynamicMap? eventArgs;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['feed_item_post']),
                  'FeedItemPost',
                ),
                onEvent: (name, args) {
                  eventName = name;
                  eventArgs = args;
                },
              ),
            ),
          ),
        ),
      );

      // Find and tap the like button (first TextButton with '0')
      await tester.tap(find.text('0').first);
      await tester.pump();

      expect(eventName, equals('post_like'));
      expect(eventArgs?['postId'], equals('post-like-test'));
    });
  });

  group('FeedItemAd (Example 9)', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/feed_item_ad.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    test('decodes without error', () {
      expect(lib, isNotNull);
    });

    testWidgets('renders ad content with sponsored label', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['feed_item_ad']), lib);

      final content = DynamicContent();
      content.update('headline', 'Great Deal!');
      content.update('description', 'Save 50% today');
      content.update('ctaText', 'Learn More');
      content.update('adId', 'ad-test');
      content.update('campaign', 'test-campaign');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['feed_item_ad']),
                  'FeedItemAd',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Great Deal!'), findsOneWidget);
      expect(find.text('Save 50% today'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);
    });
  });

  group('FeedItemPromo (Example 9)', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/feed_item_promo.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    test('decodes without error', () {
      expect(lib, isNotNull);
    });

    testWidgets('renders promo with code', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['feed_item_promo']), lib);

      final content = DynamicContent();
      content.update('title', 'Special Promo');
      content.update('subtitle', 'Limited time only');
      content.update('code', 'SAVE50');
      content.update('promoId', 'promo-test');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['feed_item_promo']),
                  'FeedItemPromo',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Special Promo'), findsOneWidget);
      expect(find.text('Limited time only'), findsOneWidget);
      expect(find.text('SAVE50'), findsOneWidget);
      expect(find.text('Claim Now'), findsOneWidget);
    });

    testWidgets('fires promo_claim event', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['feed_item_promo']), lib);

      final content = DynamicContent();
      content.update('title', 'Promo');
      content.update('subtitle', 'Get it now');
      content.update('code', 'CODE123');
      content.update('promoId', 'promo-event-test');

      String? eventName;
      DynamicMap? eventArgs;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['feed_item_promo']),
                  'FeedItemPromo',
                ),
                onEvent: (name, args) {
                  eventName = name;
                  eventArgs = args;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Claim Now'));
      await tester.pump();

      expect(eventName, equals('promo_claim'));
      expect(eventArgs?['promoId'], equals('promo-event-test'));
      expect(eventArgs?['code'], equals('CODE123'));
    });
  });

  group('MetricCard (Example 10)', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/metric_card.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    test('decodes without error', () {
      expect(lib, isNotNull);
    });

    testWidgets('renders metric with up trend', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['metric_card']), lib);

      final content = DynamicContent();
      content.update('iconCode', 0xe8cc);
      content.update('iconColor', 0xFFFFFFFF);
      content.update('iconBackgroundColor', 0xFF2196F3);
      content.update('value', '1,234');
      content.update('label', 'Users');
      content.update('change', '+15%');
      content.update('trend', 'up');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['metric_card']),
                'MetricCard',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('+15%'), findsOneWidget);
    });

    testWidgets('renders metric with down trend', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['metric_card']), lib);

      final content = DynamicContent();
      content.update('iconCode', 0xe8d1);
      content.update('iconColor', 0xFFFFFFFF);
      content.update('iconBackgroundColor', 0xFFF44336);
      content.update('value', '856');
      content.update('label', 'Orders');
      content.update('change', '-5%');
      content.update('trend', 'down');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['metric_card']),
                'MetricCard',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      expect(find.text('856'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('-5%'), findsOneWidget);
    });
  });

  group('OfferBanner (Example 10)', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/offer_banner.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
    });

    test('decodes without error', () {
      expect(lib, isNotNull);
    });

    testWidgets('renders offer content', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['offer_banner']), lib);

      final content = DynamicContent();
      content.update('title', 'Special Offer');
      content.update('description', 'Save 30% with code FLUTTER');
      content.update('offerId', 'offer-1');
      content.update('code', 'FLUTTER');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['offer_banner']),
                'OfferBanner',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      expect(find.text('Special Offer'), findsOneWidget);
      expect(find.text('Save 30% with code FLUTTER'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);
    });

    testWidgets('fires offer_claim event', (WidgetTester tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
      runtime.update(const LibraryName(<String>['offer_banner']), lib);

      final content = DynamicContent();
      content.update('title', 'Offer');
      content.update('description', 'Description');
      content.update('offerId', 'offer-event-test');
      content.update('code', 'TESTCODE');

      String? eventName;
      DynamicMap? eventArgs;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: runtime,
              data: content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['offer_banner']),
                'OfferBanner',
              ),
              onEvent: (name, args) {
                eventName = name;
                eventArgs = args;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Claim'));
      await tester.pump();

      expect(eventName, equals('offer_claim'));
      expect(eventArgs?['offerId'], equals('offer-event-test'));
      expect(eventArgs?['code'], equals('TESTCODE'));
    });
  });
}
