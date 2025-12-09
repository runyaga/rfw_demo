import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/rfw/runtime/rfw_environment.dart';
import 'features/about/presentation/about_page.dart';
import 'features/agui/presentation/agui_rfw_page.dart';
import 'features/demo/presentation/demo_page.dart';
import 'features/events/presentation/events_demo_page.dart';
import 'features/inventory/presentation/inventory_demo_page.dart';
import 'features/network/presentation/network_demo_page.dart';
import 'features/remote_view/remote_view.dart';
import 'features/widgets_extended/presentation/extended_widgets_demo_page.dart';
import 'features/forms_basic/presentation/basic_forms_page.dart';
import 'features/forms_intermediate/presentation/intermediate_forms_page.dart';
import 'features/forms_advanced/presentation/advanced_forms_page.dart';

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
          // Documentation section
          Text(
            'Documentation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _DocCard(
            icon: Icons.info_outline,
            title: 'About This Spike',
            subtitle: 'RFW overview, Dart vs JS, pros/cons',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          const SizedBox(height: 8),
          _DocCard(
            icon: Icons.smart_toy_outlined,
            title: 'AG-UI + RFW',
            subtitle: 'Agent-generated UI with Remote Flutter Widgets',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AguiRfwPage()),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Experiments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 3: Static Rendering',
            bullets: const [
              'Load compiled .rfw from bundled assets',
              'Render basic "Hello World" remote widget',
              'Verify RFW runtime initialization',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Stage3Page()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 5: Dynamic Data Binding',
            bullets: const [
              'Bind Riverpod state to DynamicContent',
              'InfoCard with live-updating metrics',
              'StatusBadge with conditional styling',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 6: Event System',
            bullets: const [
              'Button press events with arguments',
              'Toggle switch state round-trip',
              'Text input with debounced events',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventsDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 7: Network & Caching',
            bullets: const [
              'Fetch widgets from remote server',
              'Cache with TTL and ETag support',
              'Fallback chain: cache -> network -> bundled',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NetworkDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 8: Widget Inventory',
            bullets: const [
              'ProductCard, FeedItem, MetricCard components',
              'OfferBanner with gradients and CTAs',
              'Reusable widget composition patterns',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InventoryDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 9: Extended Widgets',
            bullets: const [
              'Accordion, Tabs, Breadcrumbs navigation',
              'DropdownMenu with selection handling',
              'Interactive map with markers',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExtendedWidgetsDemoPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 11: Basic Forms',
            bullets: const [
              'Text, email, password field validation',
              'Phone input with country code formatting',
              'Numeric stepper with min/max constraints',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicFormsPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 11: Intermediate Forms',
            bullets: const [
              'Multi-line textarea with character count',
              'Radio groups and checkbox groups',
              'Date range picker with validation',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IntermediateFormsPage()),
            ),
          ),
          const SizedBox(height: 12),
          _NavCard(
            title: 'Stage 11: Advanced Forms',
            bullets: const [
              'Rating slider (1-10) with semantic labels',
              'Autocomplete search with multi-select (up to 3)',
              'Composite address form with cross-validation',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdvancedFormsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DocCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final List<String> bullets;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.bullets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...bullets.map((bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('  \u2022 ', style: TextStyle(color: Colors.grey)),
                          Expanded(
                            child: Text(
                              bullet,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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
