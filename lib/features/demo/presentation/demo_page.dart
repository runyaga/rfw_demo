import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/rfw_environment.dart';
import '../data/providers.dart';
import '../data/transformers.dart';
import '../domain/models.dart';

/// Demo page showcasing dynamic data binding with RFW
class DemoPage extends ConsumerStatefulWidget {
  const DemoPage({super.key});

  @override
  ConsumerState<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends ConsumerState<DemoPage> {
  bool _infoCardLoaded = false;
  bool _statusBadgeLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWidgets();
  }

  Future<void> _loadWidgets() async {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }

    // Load InfoCard widget
    try {
      final infoCardData = await rootBundle.load('assets/rfw/defaults/info_card.rfw');
      final infoCardLib = decodeLibraryBlob(infoCardData.buffer.asUint8List());
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['infoCard']),
        infoCardLib,
      );
      setState(() => _infoCardLoaded = true);
    } catch (e) {
      debugPrint('Failed to load info_card.rfw: $e');
    }

    // Load StatusBadge widget
    try {
      final statusData = await rootBundle.load('assets/rfw/defaults/status_badge.rfw');
      final statusLib = decodeLibraryBlob(statusData.buffer.asUint8List());
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['statusBadge']),
        statusLib,
      );
      setState(() => _statusBadgeLoaded = true);
    } catch (e) {
      debugPrint('Failed to load status_badge.rfw: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 5: Dynamic Data Binding'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDescription(
              'This demo shows RFW widgets receiving data from Riverpod state. '
              'When state changes, DynamicContent updates and widgets rebuild.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('InfoCard (Example 2)'),
            _buildDescription('A card displaying title and description from Riverpod state.'),
            if (_infoCardLoaded) _buildInfoCard() else _buildLoading(),
            const SizedBox(height: 24),
            _buildSectionTitle('StatusBadge (Example 3)'),
            _buildDescription('Badges showing user status. Each has its own DynamicContent.'),
            if (_statusBadgeLoaded) _buildStatusBadges() else _buildLoading(),
            const SizedBox(height: 24),
            _buildSectionTitle('Data Controls'),
            _buildDescription('Use these buttons to modify Riverpod state and see RFW widgets update.'),
            _buildDataControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
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

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildInfoCard() {
    final infoCard = ref.watch(infoCardProvider);
    final data = InfoCardTransformer.toMap(infoCard);

    // Sync data to DynamicContent
    rfwEnvironment.updateContentMap(data);

    return SizedBox(
      width: double.infinity,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: rfwEnvironment.content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['infoCard']),
          'InfoCard',
        ),
        onEvent: (name, args) {
          debugPrint('InfoCard event: $name, args: $args');
        },
      ),
    );
  }

  Widget _buildStatusBadges() {
    final users = ref.watch(usersProvider);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: users.map((user) {
        // Each badge needs its own DynamicContent to avoid shared state issues
        final content = DynamicContent();
        content.update('status', user.status.name);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.name, style: const TextStyle(fontSize: 12)),
            Text(user.status.name,
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['statusBadge']),
                  'StatusBadge',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDataControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update InfoCard:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(infoCardProvider.notifier).state = const InfoCardData(
                        title: 'Updated Title!',
                        description: 'The data was updated via Riverpod state management.',
                      );
                    },
                    child: const Text('Update Card'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(infoCardProvider.notifier).state = const InfoCardData(
                        title: 'Welcome to RFW',
                        description: 'This card demonstrates dynamic data binding with Remote Flutter Widgets.',
                      );
                    },
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Toggle User Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildStatusButton('Alice', UserStatus.active),
                _buildStatusButton('Bob', UserStatus.inactive),
                _buildStatusButton('Carol', UserStatus.pending),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String name, UserStatus currentStatus) {
    return ElevatedButton(
      onPressed: () {
        final users = ref.read(usersProvider);
        final updatedUsers = users.map((user) {
          if (user.name.startsWith(name)) {
            final nextStatus = UserStatus.values[
              (user.status.index + 1) % UserStatus.values.length
            ];
            return User(
              id: user.id,
              name: user.name,
              email: user.email,
              status: nextStatus,
            );
          }
          return user;
        }).toList();
        ref.read(usersProvider.notifier).state = updatedUsers;
      },
      child: Text('Cycle $name'),
    );
  }
}
