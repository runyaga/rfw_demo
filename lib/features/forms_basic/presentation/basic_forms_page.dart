import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/action_handler.dart';
import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page for Stage 11: Basic Forms (Forms 1-5)
class BasicFormsPage extends ConsumerStatefulWidget {
  const BasicFormsPage({super.key});

  @override
  ConsumerState<BasicFormsPage> createState() => _BasicFormsPageState();
}

class _BasicFormsPageState extends ConsumerState<BasicFormsPage> {
  late final ScopedActionHandler _actionHandler;

  // Widget loading state
  bool _simpleTextLoaded = false;
  bool _emailValidationLoaded = false;
  bool _passwordLoaded = false;
  bool _phoneLoaded = false;
  bool _numericLoaded = false;

  // Event log
  final List<String> _eventLog = [];
  static const int _maxLogEntries = 15;

  // Form 1: Simple Text state
  String _simpleTextValue = '';
  final DynamicContent _simpleTextContent = DynamicContent();

  // Form 2: Email Validation state
  String _emailValue = '';
  String? _emailError;
  bool _emailIsValid = false;
  final DynamicContent _emailContent = DynamicContent();

  // Form 3: Password state
  String _passwordValue = '';
  bool _obscureText = true;
  String _passwordStrength = '';
  final DynamicContent _passwordContent = DynamicContent();

  // Form 4: Phone state
  String _phoneValue = '';
  final String _countryCode = '+1';
  String? _phoneError;
  bool _phoneIsValid = false;
  final DynamicContent _phoneContent = DynamicContent();

  // Form 5: Numeric state
  int _quantity = 1;
  static const int _minQuantity = 1;
  static const int _maxQuantity = 99;
  final DynamicContent _numericContent = DynamicContent();

  @override
  void initState() {
    super.initState();
    _actionHandler = ScopedActionHandler();
    _registerEventHandlers();
    _loadWidgets();
  }

  @override
  void dispose() {
    _actionHandler.dispose();
    super.dispose();
  }

  void _registerEventHandlers() {
    // Form 1: Simple Text handlers
    _actionHandler.registerHandler('text_changed', (args) {
      final field = args['field'] as String? ?? 'unknown';
      final value = args['value'] as String? ?? '';
      _logEvent('text_changed', 'field: $field');

      if (field == 'name') {
        setState(() {
          _simpleTextValue = value;
          _updateSimpleTextContent();
        });
      }
    });

    _actionHandler.registerHandler('form_submit', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      final data = args['data'] as Map<Object?, Object?>?;
      _logEvent('form_submit', 'formId: $formId, data: $data');
      _showSnackBar('Form "$formId" submitted!');
    });

    _actionHandler.registerHandler('form_submit_denied', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      final reason = args['reason'] as String? ?? 'unknown';
      _logEvent('form_submit_denied', 'formId: $formId, reason: $reason');
      _showSnackBar('Submission denied: $reason');
    });

    _actionHandler.registerHandler('form_clear', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_clear', 'formId: $formId');

      if (formId == 'simple_text') {
        setState(() {
          _simpleTextValue = '';
          _updateSimpleTextContent();
        });
        _showSnackBar('Form cleared');
      } else if (formId == 'phone_input') {
        setState(() {
          _phoneValue = '';
          _phoneError = null;
          _phoneIsValid = false;
          _updatePhoneContent();
        });
        _showSnackBar('Phone form cleared');
      }
    });

    _actionHandler.registerHandler('form_cancel', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_cancel', 'formId: $formId');
      _showSnackBar('Form "$formId" cancelled');
    });

    // Form 2: Email Validation handlers
    _actionHandler.registerHandler('email_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('email_changed', 'value: "$value"');

      setState(() {
        _emailValue = value;
        _validateEmail(value);
        _updateEmailContent();
      });
    });

    // Form 3: Password handlers
    _actionHandler.registerHandler('password_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('password_changed', 'length: ${value.length}');

      setState(() {
        _passwordValue = value;
        _passwordStrength = _calculatePasswordStrength(value);
        _updatePasswordContent();
      });
    });

    _actionHandler.registerHandler('visibility_toggled', (args) {
      _logEvent('visibility_toggled', 'visible: ${!_obscureText}');

      setState(() {
        _obscureText = !_obscureText;
        _updatePasswordContent();
      });
    });

    _actionHandler.registerHandler('form_reset', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_reset', 'formId: $formId');

      if (formId == 'password_input') {
        setState(() {
          _passwordValue = '';
          _passwordStrength = '';
          _obscureText = true;
          _updatePasswordContent();
        });
        _showSnackBar('Password form reset');
      } else if (formId == 'numeric_input') {
        setState(() {
          _quantity = 1;
          _updateNumericContent();
        });
        _showSnackBar('Quantity reset');
      }
    });

    // Form 4: Phone handlers
    _actionHandler.registerHandler('phone_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('phone_changed', 'value: "$value"');

      setState(() {
        _phoneValue = value;
        _validatePhone(value);
        _updatePhoneContent();
      });
    });

    _actionHandler.registerHandler('country_selector_tap', (args) {
      _logEvent('country_selector_tap', 'tapped');
      _showSnackBar('Country selector not yet implemented');
    });

    // Form 5: Numeric handlers
    _actionHandler.registerHandler('increment', (args) {
      _logEvent('increment', 'current: $_quantity');

      if (_quantity < _maxQuantity) {
        setState(() {
          _quantity++;
          _updateNumericContent();
        });
      }
    });

    _actionHandler.registerHandler('decrement', (args) {
      _logEvent('decrement', 'current: $_quantity');

      if (_quantity > _minQuantity) {
        setState(() {
          _quantity--;
          _updateNumericContent();
        });
      }
    });

    _actionHandler.registerHandler('quantity_changed', (args) {
      _logEvent('quantity_changed', 'value changed');
      // Direct input parsing would happen here
    });

    _actionHandler.registerHandler('increment_disabled', (args) {
      _logEvent('increment_disabled', 'max reached');
    });

    _actionHandler.registerHandler('decrement_disabled', (args) {
      _logEvent('decrement_disabled', 'min reached');
    });

    _actionHandler.onUnhandledEvent = (name, args) {
      _logEvent('UNHANDLED', name);
    };
  }

  void _validateEmail(String value) {
    if (value.isEmpty) {
      _emailError = null;
      _emailIsValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      _emailError = 'Please enter a valid email address';
      _emailIsValid = false;
    } else {
      _emailError = null;
      _emailIsValid = true;
    }
  }

  String _calculatePasswordStrength(String value) {
    if (value.isEmpty) return '';

    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) score++;

    if (score >= 4) return 'strong';
    if (score >= 2) return 'medium';
    return 'weak';
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      _phoneError = null;
      _phoneIsValid = false;
    } else {
      // Simple US phone validation: expects 10 digits
      final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length == 10) {
        _phoneError = null;
        _phoneIsValid = true;
      } else {
        _phoneError = 'Enter 10 digits';
        _phoneIsValid = false;
      }
    }
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

    // Load Form 1
    try {
      final data = await rootBundle.load('assets/rfw/defaults/form_simple_text.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(const LibraryName(<String>['formSimpleText']), lib);
      _updateSimpleTextContent();
      setState(() => _simpleTextLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_simple_text.rfw: $e');
    }

    // Load Form 2
    try {
      final data = await rootBundle.load('assets/rfw/defaults/form_email_validation.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(const LibraryName(<String>['formEmailValidation']), lib);
      _updateEmailContent();
      setState(() => _emailValidationLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_email_validation.rfw: $e');
    }

    // Load Form 3
    try {
      final data = await rootBundle.load('assets/rfw/defaults/form_password.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(const LibraryName(<String>['formPassword']), lib);
      _updatePasswordContent();
      setState(() => _passwordLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_password.rfw: $e');
    }

    // Load Form 4
    try {
      final data = await rootBundle.load('assets/rfw/defaults/form_phone.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(const LibraryName(<String>['formPhone']), lib);
      _updatePhoneContent();
      setState(() => _phoneLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_phone.rfw: $e');
    }

    // Load Form 5
    try {
      final data = await rootBundle.load('assets/rfw/defaults/form_numeric.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime.update(const LibraryName(<String>['formNumeric']), lib);
      _updateNumericContent();
      setState(() => _numericLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_numeric.rfw: $e');
    }
  }

  void _updateSimpleTextContent() {
    _simpleTextContent.update('name', _simpleTextValue);
  }

  void _updateEmailContent() {
    _emailContent.update('email', _emailValue);
    _emailContent.update('emailError', _emailError ?? '');
    _emailContent.update('isValid', _emailIsValid);
  }

  void _updatePasswordContent() {
    _passwordContent.update('password', _passwordValue);
    _passwordContent.update('obscureText', _obscureText);
    _passwordContent.update('strength', _passwordStrength);
  }

  void _updatePhoneContent() {
    _phoneContent.update('phone', _phoneValue);
    _phoneContent.update('countryCode', _countryCode);
    _phoneContent.update('phoneError', _phoneError ?? '');
    _phoneContent.update('isValid', _phoneIsValid);
  }

  void _updateNumericContent() {
    _numericContent.update('quantity', _quantity);
    _numericContent.update('quantityDisplay', _quantity.toString());
    _numericContent.update('canIncrement', _quantity < _maxQuantity);
    _numericContent.update('canDecrement', _quantity > _minQuantity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Forms (1-5)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Form 1: Simple Text Input'),
            if (_simpleTextLoaded) _buildForm(_simpleTextContent, 'formSimpleText', 'SimpleTextForm') else _buildLoading(),
            const SizedBox(height: 16),

            _buildSectionTitle('Form 2: Email with Validation'),
            if (_emailValidationLoaded) _buildForm(_emailContent, 'formEmailValidation', 'EmailValidationForm') else _buildLoading(),
            const SizedBox(height: 16),

            _buildSectionTitle('Form 3: Password Input'),
            if (_passwordLoaded) _buildForm(_passwordContent, 'formPassword', 'PasswordForm') else _buildLoading(),
            const SizedBox(height: 16),

            _buildSectionTitle('Form 4: Phone Number'),
            if (_phoneLoaded) _buildForm(_phoneContent, 'formPhone', 'PhoneForm') else _buildLoading(),
            const SizedBox(height: 16),

            _buildSectionTitle('Form 5: Numeric Input'),
            if (_numericLoaded) _buildForm(_numericContent, 'formNumeric', 'NumericForm') else _buildLoading(),
            const SizedBox(height: 16),

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
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLoading() {
    return const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())));
  }

  Widget _buildForm(DynamicContent content, String library, String widget) {
    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: FullyQualifiedWidgetName(LibraryName(<String>[library]), widget),
      onEvent: _actionHandler.handleEvent,
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
                const Text('Recent Events', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => setState(() => _eventLog.clear()), child: const Text('Clear')),
              ],
            ),
            const Divider(),
            if (_eventLog.isEmpty)
              const Text('No events yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
            else
              ..._eventLog.map((log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(log, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              )),
          ],
        ),
      ),
    );
  }
}
