import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page showcasing Stage 8: Widget Inventory Expansion
///
/// Demonstrates:
/// - ProductCard with slot pattern (Example 8)
/// - Feed items: Post, Ad, Promo (Example 9)
/// - MetricCard and OfferBanner (Example 10 components)
class InventoryDemoPage extends StatefulWidget {
  const InventoryDemoPage({super.key});

  @override
  State<InventoryDemoPage> createState() => _InventoryDemoPageState();
}

class _InventoryDemoPageState extends State<InventoryDemoPage> {
  bool _initialized = false;
  String _lastEvent = '';
  final List<String> _loadedWidgets = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }

    // Load all Stage 8 widgets
    final widgets = [
      'product_card',
      'feed_item_post',
      'feed_item_ad',
      'feed_item_promo',
      'metric_card',
      'offer_banner',
    ];

    for (final widgetId in widgets) {
      try {
        final data = await rootBundle.load('assets/rfw/defaults/$widgetId.rfw');
        final lib = decodeLibraryBlob(data.buffer.asUint8List());
        rfwEnvironment.runtime.update(
          LibraryName(<String>[widgetId]),
          lib,
        );
        _loadedWidgets.add(widgetId);
      } catch (e) {
        debugPrint('Failed to load $widgetId: $e');
      }
    }

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  void _handleEvent(String name, DynamicMap args) {
    final argsStr = args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    setState(() {
      _lastEvent = '$name($argsStr)';
    });
    debugPrint('Event: $name, args: $args');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 8: Widget Inventory'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                  if (_lastEvent.isNotEmpty) _buildEventDisplay(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('ProductCard (Example 8)'),
                  _buildProductCardDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Feed Items (Example 9)'),
                  _buildFeedItemsDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Dashboard Components (Example 10)'),
                  _buildDashboardComponentsDemo(),
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
              'Stage 8: Widget Inventory Expansion',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This demo showcases a production-grade widget catalog with '
              'complex composition patterns.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Features Demonstrated:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '• ProductCard - Composite card with image placeholder, '
              'title/subtitle, price, and action button. Demonstrates '
              'the slot pattern for reusable components.\n\n'
              '• Feed Items - Polymorphic list items (Post, Ad, Promo) '
              'that would be rendered in a server-driven feed. Each type '
              'has different layouts and events.\n\n'
              '• MetricCard - Dashboard metric display with icon, value, '
              'label, trend indicator, and change percentage.\n\n'
              '• OfferBanner - Conditional promotional banner with '
              'claim action.\n\n'
              '• Events - Each widget emits specific events (product_action, '
              'post_like, ad_click, etc.) shown in the event display below.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDisplay() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last Event: $_lastEvent',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildProductCardDemo() {
    final content = DynamicContent();
    content.update('imageLabel', 'Product Image');
    content.update('title', 'Wireless Headphones');
    content.update('subtitle', 'Premium noise-canceling');
    content.update('price', '\$299.99');
    content.update('productId', 'prod-001');
    content.update('actionType', 'add_to_cart');
    content.update('actionLabel', 'Add to Cart');

    return SizedBox(
      height: 280,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['product_card']),
          'ProductCard',
        ),
        onEvent: _handleEvent,
      ),
    );
  }

  Widget _buildFeedItemsDemo() {
    return Column(
      children: [
        // Post item
        _buildFeedPost(),
        const SizedBox(height: 8),
        // Ad item
        _buildFeedAd(),
        const SizedBox(height: 8),
        // Promo item
        _buildFeedPromo(),
      ],
    );
  }

  Widget _buildFeedPost() {
    final content = DynamicContent();
    content.update('authorInitial', 'J');
    content.update('authorName', 'Jane Smith');
    content.update('timestamp', '2 hours ago');
    content.update('content', 'Just launched our new product! Check it out and let me know what you think. Really excited about this one.');
    content.update('postId', 'post-123');
    content.update('likeCount', '42');
    content.update('commentCount', '12');

    return SizedBox(
      height: 200,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['feed_item_post']),
          'FeedItemPost',
        ),
        onEvent: _handleEvent,
      ),
    );
  }

  Widget _buildFeedAd() {
    final content = DynamicContent();
    content.update('headline', 'Summer Sale!');
    content.update('description', 'Get 50% off on all electronics. Limited time offer.');
    content.update('ctaText', 'Shop Now');
    content.update('adId', 'ad-456');
    content.update('campaign', 'summer-2024');

    return SizedBox(
      height: 200,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['feed_item_ad']),
          'FeedItemAd',
        ),
        onEvent: _handleEvent,
      ),
    );
  }

  Widget _buildFeedPromo() {
    final content = DynamicContent();
    content.update('title', 'Exclusive Offer');
    content.update('subtitle', 'Use this code for 20% off your next order');
    content.update('code', 'SAVE20');
    content.update('promoId', 'promo-789');

    return SizedBox(
      height: 180,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['feed_item_promo']),
          'FeedItemPromo',
        ),
        onEvent: _handleEvent,
      ),
    );
  }

  Widget _buildDashboardComponentsDemo() {
    return Column(
      children: [
        // Metric cards in a row
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(child: _buildMetricCard(
                iconCode: 0xe8cc,  // people
                iconColor: 0xFFFFFFFF,
                iconBackgroundColor: 0xFF2196F3,
                value: '1,234',
                label: 'Total Users',
                change: '+12.5%',
                trend: 'up',
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard(
                iconCode: 0xe227,  // attach_money
                iconColor: 0xFFFFFFFF,
                iconBackgroundColor: 0xFF4CAF50,
                value: '\$45.2K',
                label: 'Revenue',
                change: '+8.3%',
                trend: 'up',
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(child: _buildMetricCard(
                iconCode: 0xe8d1,  // shopping_cart
                iconColor: 0xFFFFFFFF,
                iconBackgroundColor: 0xFFFF9800,
                value: '856',
                label: 'Orders',
                change: '-2.1%',
                trend: 'down',
              )),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricCard(
                iconCode: 0xe8e8,  // star
                iconColor: 0xFFFFFFFF,
                iconBackgroundColor: 0xFF9C27B0,
                value: '4.8',
                label: 'Rating',
                change: '0.0%',
                trend: 'neutral',
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Offer banner
        _buildOfferBanner(),
      ],
    );
  }

  Widget _buildMetricCard({
    required int iconCode,
    required int iconColor,
    required int iconBackgroundColor,
    required String value,
    required String label,
    required String change,
    required String trend,
  }) {
    final content = DynamicContent();
    content.update('iconCode', iconCode);
    content.update('iconColor', iconColor);
    content.update('iconBackgroundColor', iconBackgroundColor);
    content.update('value', value);
    content.update('label', label);
    content.update('change', change);
    content.update('trend', trend);

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['metric_card']),
        'MetricCard',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildOfferBanner() {
    final content = DynamicContent();
    content.update('title', 'Special Offer!');
    content.update('description', 'Get 30% off your next purchase with code FLUTTER30');
    content.update('offerId', 'offer-001');
    content.update('code', 'FLUTTER30');

    return SizedBox(
      height: 100,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['offer_banner']),
          'OfferBanner',
        ),
        onEvent: _handleEvent,
      ),
    );
  }
}
