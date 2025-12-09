import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/action_handler.dart';
import '../../../core/rfw/runtime/debouncer.dart';
import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page showcasing Stage 6: Event System Implementation
///
/// This demonstrates:
/// - ActionButton: Button presses fire events with action/source
/// - FeatureToggle: Toggle switch with stateless round-trip
/// - EmailInput: High-frequency text input with debouncing
class EventsDemoPage extends ConsumerStatefulWidget {
  const EventsDemoPage({super.key});

  @override
  ConsumerState<EventsDemoPage> createState() => _EventsDemoPageState();
}

class _EventsDemoPageState extends ConsumerState<EventsDemoPage> {
  late final ScopedActionHandler _actionHandler;
  late final Debouncer _emailDebouncer;

  // Widget loading state
  bool _actionButtonLoaded = false;
  bool _featureToggleLoaded = false;
  bool _emailInputLoaded = false;

  // Event log for demonstration
  final List<String> _eventLog = [];
  static const int _maxLogEntries = 10;

  // State for FeatureToggle (stateless round-trip pattern)
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  bool _analyticsEnabled = false;

  // State for EmailInput
  String _email = '';
  String? _emailError;
  String _validationState = 'none';

  @override
  void initState() {
    super.initState();
    _actionHandler = ScopedActionHandler();
    _emailDebouncer = Debouncer(milliseconds: 300);
    _registerEventHandlers();
    _loadWidgets();
  }

  @override
  void dispose() {
    _emailDebouncer.dispose();
    _actionHandler.dispose();
    super.dispose();
  }

  void _registerEventHandlers() {
    // ActionButton handler (Example 5)
    _actionHandler.registerHandler('button_pressed', (args) {
      final action = args['action'] as String? ?? 'unknown';
      final source = args['source'] as String? ?? 'unknown';
      _logEvent('button_pressed', 'action: $action, source: $source');

      // Handle specific actions
      if (action == 'refresh_data') {
        _showSnackBar('Refreshing data...');
      } else if (action == 'submit') {
        _showSnackBar('Form submitted!');
      }
    });

    // FeatureToggle handler (Example 6)
    _actionHandler.registerHandler('toggle_changed', (args) {
      final featureId = args['featureId'] as String? ?? 'unknown';
      final newValue = args['newValue'] as bool? ?? false;
      _logEvent('toggle_changed', 'featureId: $featureId, newValue: $newValue');

      // Stateless round-trip: update state and rebuild
      setState(() {
        switch (featureId) {
          case 'dark_mode':
            _darkModeEnabled = !_darkModeEnabled;
          case 'notifications':
            _notificationsEnabled = !_notificationsEnabled;
          case 'analytics':
            _analyticsEnabled = !_analyticsEnabled;
        }
        _updateToggleContent();
      });
    });

    // EmailInput handler (Example 7) - with debouncing
    _actionHandler.registerHandler('email_changed', (args) {
      // Raw handler logs immediately
      final value = args['value'] as String? ?? '';
      _logEvent('email_changed (raw)', 'value: "$value"');

      // Debounced validation
      _emailDebouncer.run(() {
        _validateEmail(value);
      });
    });

    _actionHandler.registerHandler('email_submitted', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('email_submitted', 'value: "$value"');

      // Cancel debouncer and validate immediately
      _emailDebouncer.cancel();
      _validateEmail(value);

      if (_emailError == null) {
        _showSnackBar('Email submitted: $value');
      }
    });

    // Generic text handlers
    _actionHandler.registerHandler('text_changed', (args) {
      final fieldId = args['fieldId'] as String? ?? 'unknown';
      final value = args['value'] as String? ?? '';
      _logEvent('text_changed', 'fieldId: $fieldId, value: "$value"');
    });

    _actionHandler.registerHandler('text_submitted', (args) {
      final fieldId = args['fieldId'] as String? ?? 'unknown';
      final value = args['value'] as String? ?? '';
      _logEvent('text_submitted', 'fieldId: $fieldId, value: "$value"');
    });

    // Set up event logging callback
    _actionHandler.onUnhandledEvent = (name, args) {
      _logEvent('UNHANDLED', '$name: $args');
    };
  }

  void _validateEmail(String value) {
    setState(() {
      _email = value;
      if (value.isEmpty) {
        _emailError = null;
        _validationState = 'none';
      } else if (!value.contains('@') || !value.contains('.')) {
        _emailError = 'Please enter a valid email address';
        _validationState = 'invalid';
      } else {
        _emailError = null;
        _validationState = 'valid';
      }
      _updateEmailContent();
    });
  }

  void _logEvent(String event, String details) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _eventLog.insert(0, '[$timestamp] $event: $details');
      if (_eventLog.length > _maxLogEntries) {
        _eventLog.removeLast();
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _loadWidgets() async {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }

    // Load ActionButton widget
    try {
      final data = await rootBundle.load('assets/rfw/defaults/action_button.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['actionButton']),
        lib,
      );
      _updateActionButtonContent();
      setState(() => _actionButtonLoaded = true);
    } catch (e) {
      debugPrint('Failed to load action_button.rfw: $e');
    }

    // Load FeatureToggle widget
    try {
      final data = await rootBundle.load('assets/rfw/defaults/feature_toggle.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['featureToggle']),
        lib,
      );
      _updateToggleContent();
      setState(() => _featureToggleLoaded = true);
    } catch (e) {
      debugPrint('Failed to load feature_toggle.rfw: $e');
    }

    // Load EmailInput widget
    try {
      final data = await rootBundle.load('assets/rfw/defaults/email_input.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['emailInput']),
        lib,
      );
      _updateEmailContent();
      setState(() => _emailInputLoaded = true);
    } catch (e) {
      debugPrint('Failed to load email_input.rfw: $e');
    }
  }

  void _updateActionButtonContent() {
    rfwEnvironment.content.update('buttonText', 'Refresh Data');
    rfwEnvironment.content.update('action', 'refresh_data');
    rfwEnvironment.content.update('source', 'events_demo');
    rfwEnvironment.content.update('iconCode', 0xE863); // refresh icon
  }

  void _updateToggleContent() {
    // For individual toggles
    rfwEnvironment.content.update('featureLabel', 'Dark Mode');
    rfwEnvironment.content.update('featureDescription', 'Enable dark theme for the app');
    rfwEnvironment.content.update('featureId', 'dark_mode');
    rfwEnvironment.content.update('isEnabled', _darkModeEnabled);
  }

  void _updateEmailContent() {
    rfwEnvironment.content.update('email', _email);
    rfwEnvironment.content.update('emailError', _emailError ?? '');
    rfwEnvironment.content.update('validationState', _validationState);

    // For EmailFormField variant
    rfwEnvironment.content.update('label', 'Email Address');
    rfwEnvironment.content.update('hintText', 'user@example.com');
    rfwEnvironment.content.update('errorText', _emailError ?? '');
    rfwEnvironment.content.update('helperText', 'Enter your work email');
    rfwEnvironment.content.update('fieldId', 'email');
    rfwEnvironment.content.update('currentValue', _email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 6: Event System'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ActionButton (Example 5)'),
            _buildDescription('Button press fires "button_pressed" event with action and source.'),
            if (_actionButtonLoaded) _buildActionButtons() else _buildLoading(),
            const SizedBox(height: 24),

            _buildSectionTitle('FeatureToggle (Example 6)'),
            _buildDescription('Toggle fires "toggle_changed" event. UI updates via stateless round-trip.'),
            if (_featureToggleLoaded) _buildFeatureToggles() else _buildLoading(),
            const SizedBox(height: 24),

            _buildSectionTitle('EmailInput (Example 7)'),
            _buildDescription('Text input fires "email_changed" with 300ms debounce.'),
            if (_emailInputLoaded) _buildEmailInput() else _buildLoading(),
            const SizedBox(height: 24),

            _buildSectionTitle('Event Log'),
            _buildEventLog(),
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

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Simple ActionButton
            SizedBox(
              height: 48,
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: rfwEnvironment.content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['actionButton']),
                  'ActionButton',
                ),
                onEvent: _actionHandler.handleEvent,
              ),
            ),
            const SizedBox(height: 16),
            // Native buttons for comparison
            const Text('Native buttons for comparison:',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _logEvent('native_button', 'Submit pressed (native)');
                      _showSnackBar('Native submit!');
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Submit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _logEvent('native_button', 'Cancel pressed (native)');
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggles() {
    return Card(
      child: Column(
        children: [
          _buildToggleRow('Dark Mode', 'dark_mode', _darkModeEnabled,
            'Enable dark theme for the app'),
          const Divider(height: 1),
          _buildToggleRow('Notifications', 'notifications', _notificationsEnabled,
            'Receive push notifications'),
          const Divider(height: 1),
          _buildToggleRow('Analytics', 'analytics', _analyticsEnabled,
            'Help improve the app with usage data'),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, String featureId, bool isEnabled, String description) {
    // Each toggle needs its own DynamicContent to avoid shared state issues
    final content = DynamicContent();
    content.update('featureLabel', label);
    content.update('featureDescription', description);
    content.update('featureId', featureId);
    content.update('isEnabled', isEnabled);

    return SizedBox(
      height: 80,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['featureToggle']),
          'FeatureToggle',
        ),
        onEvent: _actionHandler.handleEvent,
      ),
    );
  }

  Widget _buildEmailInput() {
    _updateEmailContent();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 80,
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: rfwEnvironment.content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['emailInput']),
                  'EmailInput',
                ),
                onEvent: _actionHandler.handleEvent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current value: "$_email"',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Validation: $_validationState',
              style: TextStyle(
                fontSize: 12,
                color: _validationState == 'valid' ? Colors.green :
                       _validationState == 'invalid' ? Colors.red :
                       Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: The TextField events fire from RFW, but the actual text '
              'is captured via native TextField\'s onChanged. This demonstrates '
              'the high-frequency round-trip pattern.',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLog() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Events',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() => _eventLog.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(),
            if (_eventLog.isEmpty)
              const Text('No events yet. Interact with the widgets above.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            else
              ..._eventLog.map((log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(log,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              )),
          ],
        ),
      ),
    );
  }
}
