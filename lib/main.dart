import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/rfw/runtime/rfw_environment.dart';
import 'features/demo/presentation/demo_page.dart';
import 'features/events/presentation/events_demo_page.dart';
import 'features/inventory/presentation/inventory_demo_page.dart';
import 'features/network/presentation/network_demo_page.dart';
import 'features/remote_view/remote_view.dart';
import 'features/widgets_extended/presentation/extended_widgets_demo_page.dart';

void main() {
  // Initialize RFW environment before running the app
  rfwEnvironment.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RFW Spike',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('RFW Spike'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavCard(
            title: 'Stage 3: Static Rendering',
            description: 'Hello World remote widget from bundled asset',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Stage3Page()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 5: Dynamic Data Binding',
            description: 'InfoCard, StatusBadge with Riverpod state',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 6: Event System',
            description: 'ActionButton, FeatureToggle, EmailInput with events',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 7: Network & Caching',
            description: 'Load widgets from network with fallback chain',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetworkDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 8: Widget Inventory',
            description: 'ProductCard, Feed items, MetricCard, OfferBanner',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 9: Extended Widgets',
            description: 'Accordion, Tabs, Breadcrumbs, Dropdown, Map, etc.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExtendedWidgetsDemoPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class Stage3Page extends StatelessWidget {
  const Stage3Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Stage 3: Static Rendering'),
      ),
      body: const RemoteView(
        assetPath: 'assets/rfw/defaults/hello_world.rfw',
      ),
    );
  }
}
