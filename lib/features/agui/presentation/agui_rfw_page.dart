import 'package:flutter/material.dart';

/// Page explaining AG-UI protocol integration with RFW
class AguiRfwPage extends StatelessWidget {
  const AguiRfwPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('AG-UI + RFW'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Part 1: Conceptual Overview
          _buildSectionHeader(context, 'Conceptual Overview'),
          const SizedBox(height: 12),
          _buildSection(
            context,
            icon: Icons.smart_toy_outlined,
            title: 'What is AG-UI?',
            content:
                'AG-UI (Agent User Interaction) is a protocol specification from the CopilotKit team '
                'that standardizes how AI agents communicate UI intentions to clients.\n\n'
                'Rather than agents being limited to text responses, AG-UI enables agents to render '
                'rich, interactive UI components - forms, visualizations, dashboards - as part of '
                'the conversation flow.',
            linkText: 'ag-ui.com',
            linkUrl: 'https://ag-ui.com',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            icon: Icons.psychology_outlined,
            title: 'The Problem',
            content:
                'LLMs are powerful at understanding intent and generating structured data, but they '
                'output text. When an agent needs to:\n\n'
                '• Collect structured input (shipping address, payment info)\n'
                '• Display complex data (charts, tables, maps)\n'
                '• Guide multi-step workflows (wizards, onboarding)\n\n'
                '...text-only responses fall short. The agent needs a way to render real UI widgets '
                'that the user can interact with.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            icon: Icons.widgets_outlined,
            title: 'Why RFW Fits',
            content:
                'Remote Flutter Widgets (RFW) provides exactly what agent-generated UI needs:\n\n'
                '• Sandboxed execution - no arbitrary code eval, safe by design\n'
                '• Declarative DSL - LLMs can generate or parameterize widget definitions\n'
                '• Pre-registered widgets - client controls what\'s allowed\n'
                '• Runtime parsing - no compilation required for dynamic content\n'
                '• Data binding - server provides data, client renders and captures input\n\n'
                'RFW\'s constraints (no arbitrary Dart, pre-registered widgets) are features '
                'in the AG-UI context - they provide guardrails for agent-generated UI.',
          ),
          const SizedBox(height: 16),
          _buildRenderingContexts(context),
          const SizedBox(height: 24),

          // Part 2: Technical Patterns
          _buildSectionHeader(context, 'Technical Patterns'),
          const SizedBox(height: 12),
          _buildSection(
            context,
            icon: Icons.key_outlined,
            title: 'Widget Identity & Slots',
            content:
                'Widgets that persist across conversation turns need stable identifiers. '
                'We use a slot-based mechanism:\n\n'
                'state.widgets = {\n'
                '  "slot:shipping_form": { widget: "AddressForm", data: {...} },\n'
                '  "slot:order_summary": { widget: "OrderCard", visible: false },\n'
                '  "slot:progress": { widget: "StepIndicator", data: { step: 2 } }\n'
                '}\n\n'
                'Slots are stable keys. StateDeltaEvents can:\n'
                '• Update data within a slot (form field values)\n'
                '• Toggle visibility (show/hide widgets)\n'
                '• Replace the widget type entirely\n'
                '• Add or remove slots',
          ),
          const SizedBox(height: 16),
          _buildDataFlowTable(context),
          const SizedBox(height: 16),
          _buildSection(
            context,
            icon: Icons.sync_alt,
            title: 'StateDeltaEvent Flow',
            content:
                'As conversation evolves, the server sends StateDeltaEvents to update the widget tree:\n\n'
                '1. User: "I want to order a pizza"\n'
                '   → Server adds slot:menu_picker (MenuWidget)\n\n'
                '2. User selects items from menu\n'
                '   → Client sends selection, server adds slot:cart_summary\n\n'
                '3. User: "Checkout"\n'
                '   → Server hides menu_picker, adds slot:payment_form\n\n'
                '4. User completes payment\n'
                '   → Server removes payment_form, adds slot:confirmation\n\n'
                'The chat continues while widgets appear, update, and disappear alongside it.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            icon: Icons.code,
            title: 'Raw RFW Generation',
            content:
                'Can an LLM generate RFW widget definitions on the fly? Yes.\n\n'
                'RFW\'s parseLibraryFile() can parse .rfwtxt source at runtime - no compilation '
                'needed. This means an LLM could theoretically generate:\n\n'
                '• Complete widget definitions for novel layouts\n'
                '• Parameterized templates with dynamic content\n'
                '• Composed widgets from pre-registered primitives\n\n'
                'However, the practical approach is likely:\n'
                '1. Pre-register a library of useful widgets\n'
                '2. LLM selects widget + provides data bindings\n'
                '3. Raw generation reserved for advanced/custom cases\n\n'
                'This balances flexibility with predictability and performance.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            icon: Icons.security_outlined,
            title: 'Security Model',
            content:
                'RFW\'s constraints make it safe for agent-generated UI:\n\n'
                '• No eval() - widget DSL cannot execute arbitrary code\n'
                '• Pre-registration - only explicitly allowed widgets render\n'
                '• Sandboxed events - handlers are defined client-side\n'
                '• Data validation - host validates all input before processing\n\n'
                'An adversarial LLM cannot escape the sandbox - it can only '
                'compose pre-approved widgets with data the client accepts.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    String? linkText,
    String? linkUrl,
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
                    fontFamily: content.contains('state.widgets')
                        ? 'monospace'
                        : null,
                  ),
            ),
            if (linkText != null && linkUrl != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                linkUrl,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRenderingContexts(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.view_quilt_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Two Rendering Contexts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContextCard(
              context,
              title: 'In-Chat Widgets',
              subtitle: 'genui_render tool calls',
              icon: Icons.chat_bubble_outline,
              color: Colors.blue,
              points: [
                'Appear inline within conversation',
                'Bound to specific message/turn',
                'Scroll with chat history',
                'Good for: confirmations, quick inputs, contextual cards',
              ],
            ),
            const SizedBox(height: 12),
            _buildContextCard(
              context,
              title: 'Persistent Widgets',
              subtitle: 'StateDeltaEvent updates',
              icon: Icons.dashboard_outlined,
              color: Colors.green,
              points: [
                'Live alongside chat (sidebar, panel, overlay)',
                'Persist and update across conversation turns',
                'Controlled via state deltas from server',
                'Good for: dashboards, forms, wizards, visualizations',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          ...points.map((point) => Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(
                        point,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDataFlowTable(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Client → Server Data Flow',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'When users interact with widgets, data flows back to the server via two patterns:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
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
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Pattern',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Flow',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Use Case',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                _buildFlowRow(
                  'Chat Response',
                  'Form data → new AG-UI run → LLM sees data in context → responds',
                  'Natural conversation: "Here\'s the address you entered, shall I proceed?"',
                ),
                _buildFlowRow(
                  'State Snapshot',
                  'Form data → client tool responds with STATE_SNAPSHOT → widget tree updates',
                  'Fast feedback: wizard advances to next step without LLM round-trip',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildFlowRow(String pattern, String flow, String useCase) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(pattern,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(flow, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(useCase,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ),
      ],
    );
  }
}

extension on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0)).toColor();
  }
}
