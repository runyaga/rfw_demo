import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/action_handler.dart';
import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page for Stage 11: Intermediate Forms (Forms 6-10)
class IntermediateFormsPage extends ConsumerStatefulWidget {
  const IntermediateFormsPage({super.key});

  @override
  ConsumerState<IntermediateFormsPage> createState() =>
      _IntermediateFormsPageState();
}

class _IntermediateFormsPageState extends ConsumerState<IntermediateFormsPage> {
  late final ScopedActionHandler _actionHandler;

  // Widget loading state
  bool _textareaLoaded = false;
  bool _dropdownSelectLoaded = false;
  bool _radioGroupLoaded = false;
  bool _checkboxGroupLoaded = false;
  bool _dateRangeLoaded = false;

  // Event log
  final List<String> _eventLog = [];
  static const int _maxLogEntries = 15;

  // Form 6: Textarea state
  String _textareaContent = '';
  static const int _maxChars = 500;
  final DynamicContent _textareaContentData = DynamicContent();

  // Form 7: Dropdown Select state
  String? _selectedStateValue;
  String? _selectedStateLabel;
  String _dropdownValidationError = '';
  final DynamicContent _dropdownContent = DynamicContent();

  // US States for dropdown
  static const List<Map<String, String>> _usStates = [
    {'value': 'AL', 'label': 'Alabama'},
    {'value': 'AK', 'label': 'Alaska'},
    {'value': 'AZ', 'label': 'Arizona'},
    {'value': 'CA', 'label': 'California'},
    {'value': 'CO', 'label': 'Colorado'},
    {'value': 'FL', 'label': 'Florida'},
    {'value': 'GA', 'label': 'Georgia'},
    {'value': 'NY', 'label': 'New York'},
    {'value': 'TX', 'label': 'Texas'},
    {'value': 'WA', 'label': 'Washington'},
  ];

  // Form 8: Radio Group state
  String _selectedContactMethod = '';
  String _otherContactValue = '';
  String _radioValidationError = '';
  final DynamicContent _radioContent = DynamicContent();

  // Form 9: Checkbox Group state
  final Set<String> _selectedInterests = {};
  static const int _minSelections = 2;
  static const int _maxSelections = 4;
  final DynamicContent _checkboxContent = DynamicContent();

  // Form 10: Date Range state
  DateTime? _startDate;
  DateTime? _endDate;
  String _dateValidationError = '';
  final DynamicContent _dateRangeContent = DynamicContent();

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
    // Form 6: Textarea handlers
    _actionHandler.registerHandler('content_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('content_changed', 'length: ${value.length}');

      setState(() {
        _textareaContent = value;
        _updateTextareaContent();
      });
    });

    _actionHandler.registerHandler('form_save_draft', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_save_draft', 'formId: $formId');
      _showSnackBar('Draft saved!');
    });

    _actionHandler.registerHandler('form_discard', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_discard', 'formId: $formId');

      if (formId == 'textarea') {
        setState(() {
          _textareaContent = '';
          _updateTextareaContent();
        });
        _showSnackBar('Draft discarded');
      }
    });

    // Form 7: Dropdown handlers
    _actionHandler.registerHandler('dropdown_tap', (args) {
      _logEvent('dropdown_tap', 'showing state selector');
      _showStateSelector();
    });

    _actionHandler.registerHandler('form_clear_selection', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_clear_selection', 'formId: $formId');

      if (formId == 'dropdown_select') {
        setState(() {
          _selectedStateValue = null;
          _selectedStateLabel = null;
          _dropdownValidationError = '';
          _updateDropdownContent();
        });
      }
    });

    // Form 8: Radio Group handlers
    _actionHandler.registerHandler('option_selected', (args) {
      final groupId = args['groupId'] as String? ?? 'unknown';
      final value = args['value'] as String? ?? '';
      _logEvent('option_selected', 'groupId: $groupId, value: $value');

      if (groupId == 'contact_method') {
        setState(() {
          _selectedContactMethod = value;
          if (value != 'other') {
            _otherContactValue = '';
          }
          _radioValidationError = '';
          _updateRadioContent();
        });
      }
    });

    _actionHandler.registerHandler('other_specified', (args) {
      // TextField onChanged sends {value: "newtext"}, not customValue
      final value = args['value'] as String? ?? '';
      _logEvent('other_specified', 'value: "$value"');

      setState(() {
        _otherContactValue = value;
        _radioValidationError = '';
        _updateRadioContent();
      });
    });

    _actionHandler.registerHandler('form_back', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_back', 'formId: $formId');
      _showSnackBar('Back pressed (would navigate to previous step)');
    });

    // Form 9: Checkbox Group handlers
    _actionHandler.registerHandler('selection_changed', (args) {
      final groupId = args['groupId'] as String? ?? 'unknown';
      final itemId = args['itemId'] as String? ?? '';

      if (groupId == 'interests') {
        // Toggle the selection
        final isCurrentlyChecked = _selectedInterests.contains(itemId);
        _logEvent('selection_changed', '$itemId: ${!isCurrentlyChecked}');

        setState(() {
          if (isCurrentlyChecked) {
            _selectedInterests.remove(itemId);
          } else {
            _selectedInterests.add(itemId);
          }
          _updateCheckboxContent();
        });
      }
    });

    // Form 10: Date Range handlers
    _actionHandler.registerHandler('pick_start_date', (args) {
      _logEvent('pick_start_date', 'showing date picker');
      _showDatePicker(isStart: true);
    });

    _actionHandler.registerHandler('pick_end_date', (args) {
      _logEvent('pick_end_date', 'showing date picker');
      _showDatePicker(isStart: false);
    });

    _actionHandler.registerHandler('form_clear_dates', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_clear_dates', 'formId: $formId');

      setState(() {
        _startDate = null;
        _endDate = null;
        _dateValidationError = '';
        _updateDateRangeContent();
      });
    });

    // Common handlers
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

    _actionHandler.registerHandler('form_reset', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_reset', 'formId: $formId');

      if (formId == 'checkbox_group') {
        setState(() {
          _selectedInterests.clear();
          _updateCheckboxContent();
        });
        _showSnackBar('Selections cleared');
      }
    });

    _actionHandler.onUnhandledEvent = (name, args) {
      _logEvent('UNHANDLED', name);
    };
  }

  void _showStateSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _usStates.length,
        itemBuilder: (context, index) {
          final state = _usStates[index];
          final isSelected = state['value'] == _selectedStateValue;
          return ListTile(
            leading: isSelected
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : const Icon(Icons.circle_outlined),
            title: Text(state['label']!),
            subtitle: Text(state['value']!),
            onTap: () {
              setState(() {
                _selectedStateValue = state['value'];
                _selectedStateLabel = state['label'];
                _dropdownValidationError = '';
                _updateDropdownContent();
              });
              Navigator.pop(context);
              _logEvent('option_selected',
                  'id: ${state['value']}, label: ${state['label']}');
            },
          );
        },
      ),
    );
  }

  Future<void> _showDatePicker({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = isStart ? now : (_startDate ?? now);
    final initialDate = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate?.add(const Duration(days: 1)) ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Reset end date if it's now invalid
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
        _validateDateRange();
        _updateDateRangeContent();
      });
      _logEvent(
        isStart ? 'date_selected' : 'date_selected',
        'field: ${isStart ? "start" : "end"}, date: ${DateFormat('yyyy-MM-dd').format(picked)}',
      );
    }
  }

  void _validateDateRange() {
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        _dateValidationError = 'Check-out must be after check-in';
      } else {
        _dateValidationError = '';
      }
    } else {
      _dateValidationError = '';
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

    // Load Form 6
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_textarea.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formTextarea']), lib);
      _updateTextareaContent();
      setState(() => _textareaLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_textarea.rfw: $e');
    }

    // Load Form 7
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_dropdown_select.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formDropdownSelect']), lib);
      _updateDropdownContent();
      setState(() => _dropdownSelectLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_dropdown_select.rfw: $e');
    }

    // Load Form 8
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_radio_group.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formRadioGroup']), lib);
      _updateRadioContent();
      setState(() => _radioGroupLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_radio_group.rfw: $e');
    }

    // Load Form 9
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_checkbox_group.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formCheckboxGroup']), lib);
      _updateCheckboxContent();
      setState(() => _checkboxGroupLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_checkbox_group.rfw: $e');
    }

    // Load Form 10
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_date_range.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formDateRange']), lib);
      _updateDateRangeContent();
      setState(() => _dateRangeLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_date_range.rfw: $e');
    }
  }

  void _updateTextareaContent() {
    final length = _textareaContent.length;
    final remaining = _maxChars - length;
    _textareaContentData.update('content', _textareaContent);
    _textareaContentData.update('length', length);
    _textareaContentData.update('remaining', remaining);
    _textareaContentData.update('charCountDisplay', '$length / $_maxChars');
    _textareaContentData.update('nearLimit', remaining <= 50);
    _textareaContentData.update('limitReached', remaining <= 0);
    _textareaContentData.update('hasContent', _textareaContent.isNotEmpty);
  }

  void _updateDropdownContent() {
    _dropdownContent.update('hasSelection', _selectedStateValue != null);
    _dropdownContent.update('selectedValue', _selectedStateValue ?? '');
    _dropdownContent.update('selectedLabel', _selectedStateLabel ?? '');
    _dropdownContent.update('validationError', _dropdownValidationError);
  }

  void _updateRadioContent() {
    final showOther = _selectedContactMethod == 'other';
    final isValid = _selectedContactMethod.isNotEmpty &&
        (_selectedContactMethod != 'other' || _otherContactValue.isNotEmpty);

    String validationReason = '';
    if (_selectedContactMethod.isEmpty) {
      validationReason = 'no_selection';
    } else if (_selectedContactMethod == 'other' &&
        _otherContactValue.isEmpty) {
      validationReason = 'other_not_specified';
    }

    _radioContent.update('selectedValue', _selectedContactMethod);
    _radioContent.update('otherValue', _otherContactValue);
    _radioContent.update('showOtherInput', showOther);
    _radioContent.update('isValid', isValid);
    _radioContent.update('validationError', _radioValidationError);
    _radioContent.update('validationReason', validationReason);

    // Individual radio selection states
    _radioContent.update('emailSelected', _selectedContactMethod == 'email');
    _radioContent.update('phoneSelected', _selectedContactMethod == 'phone');
    _radioContent.update('smsSelected', _selectedContactMethod == 'sms');
    _radioContent.update('otherSelected', _selectedContactMethod == 'other');
  }

  void _updateCheckboxContent() {
    final count = _selectedInterests.length;
    String status;
    int statusColor;
    if (count < _minSelections) {
      status = 'too_few';
      statusColor = 0xFFFF9800; // Orange
    } else if (count > _maxSelections) {
      status = 'too_many';
      statusColor = 0xFFF44336; // Red
    } else {
      status = 'valid';
      statusColor = 0xFF4CAF50; // Green
    }

    final isValid = count >= _minSelections && count <= _maxSelections;
    String validationError = '';
    if (count < _minSelections) {
      validationError = 'Please select at least $_minSelections options';
    } else if (count > _maxSelections) {
      validationError = 'Please select no more than $_maxSelections options';
    }

    _checkboxContent.update('selectionCount', count);
    _checkboxContent.update('selectionCountDisplay', '$count selected');
    _checkboxContent.update('selectionStatus', status);
    _checkboxContent.update('statusColor', statusColor);
    _checkboxContent.update('isValid', isValid);
    _checkboxContent.update('validationError', validationError);
    _checkboxContent.update(
        'selectedInterests', _selectedInterests.toList().join(','));

    // Individual checkbox states
    _checkboxContent.update(
        'sportsChecked', _selectedInterests.contains('sports'));
    _checkboxContent.update(
        'musicChecked', _selectedInterests.contains('music'));
    _checkboxContent.update(
        'technologyChecked', _selectedInterests.contains('technology'));
    _checkboxContent.update(
        'travelChecked', _selectedInterests.contains('travel'));
    _checkboxContent.update('foodChecked', _selectedInterests.contains('food'));
    _checkboxContent.update('artChecked', _selectedInterests.contains('art'));
  }

  void _updateDateRangeContent() {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasStart = _startDate != null;
    final hasEnd = _endDate != null;
    final hasRange = hasStart && hasEnd;

    int nights = 0;
    if (hasRange) {
      nights = _endDate!.difference(_startDate!).inDays;
    }

    final isValid = hasRange && nights > 0 && _dateValidationError.isEmpty;

    _dateRangeContent.update('hasStartDate', hasStart);
    _dateRangeContent.update('hasEndDate', hasEnd);
    _dateRangeContent.update('hasDateRange', hasRange);
    _dateRangeContent.update(
      'startDate',
      hasStart ? DateFormat('yyyy-MM-dd').format(_startDate!) : '',
    );
    _dateRangeContent.update(
      'endDate',
      hasEnd ? DateFormat('yyyy-MM-dd').format(_endDate!) : '',
    );
    _dateRangeContent.update(
      'startDateDisplay',
      hasStart ? dateFormat.format(_startDate!) : '',
    );
    _dateRangeContent.update(
      'endDateDisplay',
      hasEnd ? dateFormat.format(_endDate!) : '',
    );
    _dateRangeContent.update('nights', nights);
    _dateRangeContent.update(
      'nightsDisplay',
      nights == 1 ? '1 night' : '$nights nights',
    );
    _dateRangeContent.update('isValid', isValid);
    _dateRangeContent.update('validationError', _dateValidationError);
    _dateRangeContent.update('startDateError', '');
    _dateRangeContent.update('endDateError', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intermediate Forms (6-10)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Form 6: Multi-line Text Area'),
            if (_textareaLoaded)
              _buildForm(
                  _textareaContentData, 'formTextarea', 'TextAreaForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 7: Dropdown Select'),
            if (_dropdownSelectLoaded)
              _buildForm(
                  _dropdownContent, 'formDropdownSelect', 'DropdownSelectForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 8: Radio Button Group'),
            if (_radioGroupLoaded)
              _buildForm(_radioContent, 'formRadioGroup', 'RadioGroupForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 9: Checkbox Group'),
            if (_checkboxGroupLoaded)
              _buildForm(
                  _checkboxContent, 'formCheckboxGroup', 'CheckboxGroupForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 10: Date Range Picker'),
            if (_dateRangeLoaded)
              _buildForm(_dateRangeContent, 'formDateRange', 'DateRangeForm')
            else
              _buildLoading(),
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
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLoading() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
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
              const Text(
                'No events yet.',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            else
              ..._eventLog.map(
                (log) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    log,
                    style:
                        const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
