import 'package:flutter/material.dart';

/// About page explaining RFW, Dart vs JS, and pros/cons
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('About This Spike'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview section
          _buildSection(
            context,
            icon: Icons.widgets_outlined,
            title: 'Server-Driven UI Exploration',
            content:
                'This spike explores Remote Flutter Widgets (RFW) for server-driven UI architecture. '
                'The goal is to enable over-the-air (OTA) widget updates without requiring app store releases.\n\n'
                'Widget definitions are written in a declarative DSL (.rfwtxt), compiled to binary (.rfw), '
                'and rendered at runtime by the Flutter app. The host app provides data binding, event handling, '
                'and widget registration while the server controls layout and presentation.',
          ),
          const SizedBox(height: 16),
          // Dart vs JS section
          _buildSection(
            context,
            icon: Icons.code,
            title: 'Why This Is Harder in Dart',
            content:
                'Unlike JavaScript where JSON can be directly evaluated as code, Dart is ahead-of-time (AOT) '
                'compiled with no runtime eval() capability. This means we cannot simply send arbitrary Dart code '
                'from a server.\n\n'
                'RFW solves this by defining a safe, sandboxed DSL that gets interpreted at runtime. '
                'The tradeoff is that every widget and handler must be pre-registered in the host app. '
                'You cannot use widgets that aren\'t explicitly registered, and complex logic must live in the host.',
          ),
          const SizedBox(height: 16),
          // How it works section
          _buildSection(
            context,
            icon: Icons.architecture,
            title: 'How RFW Works',
            content:
                '1. Write widget definitions in .rfwtxt (declarative DSL)\n'
                '2. Compile to .rfw binary using the RFW compiler\n'
                '3. Host app registers available widgets and event handlers\n'
                '4. Load .rfw from bundled assets, cache, or network\n'
                '5. RFW runtime interprets and renders the widgets\n'
                '6. Host provides DynamicContent for data binding\n'
                '7. Events flow back to host for state management',
          ),
          const SizedBox(height: 16),
          // Pros and Cons
          _buildProsConsTable(context),
          const SizedBox(height: 16),
          // Use cases section
          _buildSection(
            context,
            icon: Icons.lightbulb_outline,
            title: 'Ideal Use Cases',
            content:
                '• Marketing banners and promotional content\n'
                '• Feature flags with UI variations\n'
                '• A/B testing different layouts\n'
                '• Rapidly iterating on form designs\n'
                '• Personalized UI per user segment\n'
                '• Fixing UI bugs without app store delays\n'
                '• Seasonal or event-specific UI updates',
          ),
          const SizedBox(height: 16),
          // Limitations section
          _buildSection(
            context,
            icon: Icons.warning_amber_outlined,
            title: 'Limitations to Consider',
            content:
                '• Cannot add new widget types without app update\n'
                '• Complex business logic stays in host code\n'
                '• Debugging requires both source and binary\n'
                '• DSL syntax is verbose for complex forms\n'
                '• No access to platform APIs from RFW\n'
                '• Performance overhead for very complex UIs\n'
                '• Learning curve for the RFW DSL',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProsConsTable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.balance,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Pros vs Cons',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up,
                              size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text('Pros',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.thumb_down,
                              size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text('Cons',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildTableRow('OTA updates without app store',
                    'Limited to pre-registered widgets'),
                _buildTableRow(
                    'A/B testing UI layouts', 'No arbitrary Dart execution'),
                _buildTableRow(
                    'Fix UI bugs instantly', 'Complex logic stays in host'),
                _buildTableRow(
                    'Sandboxed and safe', 'Verbose DSL for forms'),
                _buildTableRow(
                    'Personalized UI per segment', 'Debugging is harder'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String pro, String con) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(pro, style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(con, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
