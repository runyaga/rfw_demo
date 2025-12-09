import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/action_handler.dart';
import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page for Stage 11: Advanced Forms (Forms 11-15)
class AdvancedFormsPage extends ConsumerStatefulWidget {
  const AdvancedFormsPage({super.key});

  @override
  ConsumerState<AdvancedFormsPage> createState() => _AdvancedFormsPageState();
}

class _AdvancedFormsPageState extends ConsumerState<AdvancedFormsPage> {
  late final ScopedActionHandler _actionHandler;

  // Widget loading state
  bool _ratingSliderLoaded = false;
  bool _autocompleteLoaded = false;
  bool _addressLoaded = false;

  // Event log
  final List<String> _eventLog = [];
  static const int _maxLogEntries = 15;

  // Form 11: Rating Slider state
  int? _selectedRating;
  String _ratingValidationError = '';
  final DynamicContent _ratingContent = DynamicContent();

  // Form 12: Autocomplete state (multi-select up to 3)
  String _searchQuery = '';
  final List<Map<String, String>> _selectedCities = [];
  static const int _maxCitySelections = 3;
  String _autocompleteValidationError = '';
  final DynamicContent _autocompleteContent = DynamicContent();

  // City data for autocomplete
  static const List<Map<String, String>> _cities = [
    {'id': 'nyc', 'label': 'New York City', 'subtitle': 'New York, USA'},
    {'id': 'la', 'label': 'Los Angeles', 'subtitle': 'California, USA'},
    {'id': 'chi', 'label': 'Chicago', 'subtitle': 'Illinois, USA'},
    {'id': 'hou', 'label': 'Houston', 'subtitle': 'Texas, USA'},
    {'id': 'phx', 'label': 'Phoenix', 'subtitle': 'Arizona, USA'},
    {'id': 'phi', 'label': 'Philadelphia', 'subtitle': 'Pennsylvania, USA'},
    {'id': 'san', 'label': 'San Antonio', 'subtitle': 'Texas, USA'},
    {'id': 'sd', 'label': 'San Diego', 'subtitle': 'California, USA'},
    {'id': 'dal', 'label': 'Dallas', 'subtitle': 'Texas, USA'},
    {'id': 'sj', 'label': 'San Jose', 'subtitle': 'California, USA'},
    {'id': 'aus', 'label': 'Austin', 'subtitle': 'Texas, USA'},
    {'id': 'jax', 'label': 'Jacksonville', 'subtitle': 'Florida, USA'},
    {'id': 'sf', 'label': 'San Francisco', 'subtitle': 'California, USA'},
    {'id': 'col', 'label': 'Columbus', 'subtitle': 'Ohio, USA'},
    {'id': 'ind', 'label': 'Indianapolis', 'subtitle': 'Indiana, USA'},
    {'id': 'sea', 'label': 'Seattle', 'subtitle': 'Washington, USA'},
    {'id': 'den', 'label': 'Denver', 'subtitle': 'Colorado, USA'},
    {'id': 'bos', 'label': 'Boston', 'subtitle': 'Massachusetts, USA'},
    {'id': 'nash', 'label': 'Nashville', 'subtitle': 'Tennessee, USA'},
    {'id': 'dc', 'label': 'Washington D.C.', 'subtitle': 'District of Columbia, USA'},
  ];

  // Form 13: Address state
  String _street = '';
  String _city = '';
  String? _stateValue;
  String? _stateLabel;
  String _zip = '';
  String _streetError = '';
  String _cityError = '';
  String _stateError = '';
  String _zipError = '';
  final DynamicContent _addressContent = DynamicContent();

  // US States for address form
  static const List<Map<String, String>> _usStates = [
    {'value': 'AL', 'label': 'Alabama'},
    {'value': 'AK', 'label': 'Alaska'},
    {'value': 'AZ', 'label': 'Arizona'},
    {'value': 'AR', 'label': 'Arkansas'},
    {'value': 'CA', 'label': 'California'},
    {'value': 'CO', 'label': 'Colorado'},
    {'value': 'CT', 'label': 'Connecticut'},
    {'value': 'DE', 'label': 'Delaware'},
    {'value': 'FL', 'label': 'Florida'},
    {'value': 'GA', 'label': 'Georgia'},
    {'value': 'HI', 'label': 'Hawaii'},
    {'value': 'ID', 'label': 'Idaho'},
    {'value': 'IL', 'label': 'Illinois'},
    {'value': 'IN', 'label': 'Indiana'},
    {'value': 'IA', 'label': 'Iowa'},
    {'value': 'KS', 'label': 'Kansas'},
    {'value': 'KY', 'label': 'Kentucky'},
    {'value': 'LA', 'label': 'Louisiana'},
    {'value': 'ME', 'label': 'Maine'},
    {'value': 'MD', 'label': 'Maryland'},
    {'value': 'MA', 'label': 'Massachusetts'},
    {'value': 'MI', 'label': 'Michigan'},
    {'value': 'MN', 'label': 'Minnesota'},
    {'value': 'MS', 'label': 'Mississippi'},
    {'value': 'MO', 'label': 'Missouri'},
    {'value': 'MT', 'label': 'Montana'},
    {'value': 'NE', 'label': 'Nebraska'},
    {'value': 'NV', 'label': 'Nevada'},
    {'value': 'NH', 'label': 'New Hampshire'},
    {'value': 'NJ', 'label': 'New Jersey'},
    {'value': 'NM', 'label': 'New Mexico'},
    {'value': 'NY', 'label': 'New York'},
    {'value': 'NC', 'label': 'North Carolina'},
    {'value': 'ND', 'label': 'North Dakota'},
    {'value': 'OH', 'label': 'Ohio'},
    {'value': 'OK', 'label': 'Oklahoma'},
    {'value': 'OR', 'label': 'Oregon'},
    {'value': 'PA', 'label': 'Pennsylvania'},
    {'value': 'RI', 'label': 'Rhode Island'},
    {'value': 'SC', 'label': 'South Carolina'},
    {'value': 'SD', 'label': 'South Dakota'},
    {'value': 'TN', 'label': 'Tennessee'},
    {'value': 'TX', 'label': 'Texas'},
    {'value': 'UT', 'label': 'Utah'},
    {'value': 'VT', 'label': 'Vermont'},
    {'value': 'VA', 'label': 'Virginia'},
    {'value': 'WA', 'label': 'Washington'},
    {'value': 'WV', 'label': 'West Virginia'},
    {'value': 'WI', 'label': 'Wisconsin'},
    {'value': 'WY', 'label': 'Wyoming'},
  ];

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
    // Form 11: Rating Slider handlers
    _actionHandler.registerHandler('rating_changed', (args) {
      final value = args['value'] as int? ?? 0;
      _logEvent('rating_changed', 'value: $value');

      setState(() {
        _selectedRating = value;
        _ratingValidationError = '';
        _updateRatingContent();
      });
    });

    _actionHandler.registerHandler('form_skip', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_skip', 'formId: $formId');
      _showSnackBar('Rating skipped');
    });

    // Form 12: Autocomplete handlers (multi-select)
    _actionHandler.registerHandler('search_typed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('search_typed', 'query: "$value"');

      setState(() {
        _searchQuery = value;
        _autocompleteValidationError = '';
        _updateAutocompleteContent();
      });
    });

    _actionHandler.registerHandler('suggestion_selected', (args) {
      final id = args['id'] as String? ?? '';
      final label = args['label'] as String? ?? '';
      _logEvent('suggestion_selected', 'id: $id, label: $label');

      setState(() {
        // Don't add duplicates
        if (!_selectedCities.any((c) => c['id'] == id)) {
          if (_selectedCities.length < _maxCitySelections) {
            _selectedCities.add({'id': id, 'label': label});
          }
        }
        _searchQuery = ''; // Clear search after selection
        _autocompleteValidationError = '';
        _updateAutocompleteContent();
      });
    });

    _actionHandler.registerHandler('selection_removed', (args) {
      final id = args['id'] as String? ?? '';
      _logEvent('selection_removed', 'id: $id');

      setState(() {
        _selectedCities.removeWhere((c) => c['id'] == id);
        _autocompleteValidationError = '';
        _updateAutocompleteContent();
      });
    });

    _actionHandler.registerHandler('form_clear', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_clear', 'formId: $formId');

      if (formId == 'autocomplete') {
        setState(() {
          _searchQuery = '';
          _selectedCities.clear();
          _autocompleteValidationError = '';
          _updateAutocompleteContent();
        });
      }
    });

    // Form 13: Address handlers
    _actionHandler.registerHandler('field_changed', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      final field = args['field'] as String? ?? '';
      final value = args['value'] as String? ?? '';
      _logEvent('field_changed', 'formId: $formId, field: $field');

      if (formId == 'address') {
        setState(() {
          switch (field) {
            case 'street':
              _street = value;
              _streetError = '';
            case 'city':
              _city = value;
              _cityError = '';
            case 'zip':
              _zip = value;
              _zipError = '';
          }
          _updateAddressContent();
        });
      }
    });

    _actionHandler.registerHandler('state_tap', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('state_tap', 'formId: $formId');

      if (formId == 'address') {
        _showStateSelector();
      }
    });

    _actionHandler.registerHandler('form_cancel', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_cancel', 'formId: $formId');

      if (formId == 'address') {
        setState(() {
          _street = '';
          _city = '';
          _stateValue = null;
          _stateLabel = null;
          _zip = '';
          _streetError = '';
          _cityError = '';
          _stateError = '';
          _zipError = '';
          _updateAddressContent();
        });
        _showSnackBar('Address form cleared');
      }
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

      if (formId == 'rating_slider' && reason == 'no_selection') {
        setState(() {
          _ratingValidationError = 'Please select a rating';
          _updateRatingContent();
        });
      } else if (formId == 'autocomplete' && reason == 'no_selection') {
        setState(() {
          _autocompleteValidationError = 'Please select a city from suggestions';
          _updateAutocompleteContent();
        });
      } else if (formId == 'address' && reason == 'incomplete') {
        setState(() {
          _validateAddress();
          _updateAddressContent();
        });
      }
      _showSnackBar('Submission denied: $reason');
    });

    _actionHandler.onUnhandledEvent = (name, args) {
      _logEvent('UNHANDLED', name);
    };
  }

  List<Map<String, String>> _getFilteredCities() {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    final selectedIds = _selectedCities.map((c) => c['id']).toSet();
    return _cities
        .where((city) =>
            !selectedIds.contains(city['id']) && // Exclude already selected
            (city['label']!.toLowerCase().contains(query) ||
            city['subtitle']!.toLowerCase().contains(query)))
        .take(5)
        .toList();
  }

  void _showStateSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        itemCount: _usStates.length,
        itemBuilder: (context, index) {
          final state = _usStates[index];
          final isSelected = state['value'] == _stateValue;
          return ListTile(
            leading: isSelected
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : const Icon(Icons.circle_outlined),
            title: Text(state['label']!),
            subtitle: Text(state['value']!),
            onTap: () {
              setState(() {
                _stateValue = state['value'];
                _stateLabel = state['label'];
                _stateError = '';
                _updateAddressContent();
              });
              Navigator.pop(context);
              _logEvent('state_selected', 'value: ${state['value']}, label: ${state['label']}');
            },
          );
        },
      ),
    );
  }

  void _validateAddress() {
    if (_street.isEmpty) {
      _streetError = 'Street address is required';
    }
    if (_city.isEmpty) {
      _cityError = 'City is required';
    }
    if (_stateValue == null) {
      _stateError = 'State is required';
    }
    if (_zip.isEmpty) {
      _zipError = 'ZIP code is required';
    } else if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(_zip)) {
      _zipError = 'Invalid ZIP format (e.g., 94102)';
    }
  }

  bool _isAddressValid() {
    return _street.isNotEmpty &&
        _city.isNotEmpty &&
        _stateValue != null &&
        _zip.isNotEmpty &&
        RegExp(r'^\d{5}(-\d{4})?$').hasMatch(_zip);
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

    // Load Form 11
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_rating_slider.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formRatingSlider']), lib);
      _updateRatingContent();
      setState(() => _ratingSliderLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_rating_slider.rfw: $e');
    }

    // Load Form 12
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_autocomplete.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formAutocomplete']), lib);
      _updateAutocompleteContent();
      setState(() => _autocompleteLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_autocomplete.rfw: $e');
    }

    // Load Form 13
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_address.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formAddress']), lib);
      _updateAddressContent();
      setState(() => _addressLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_address.rfw: $e');
    }
  }

  void _updateRatingContent() {
    final hasSelection = _selectedRating != null;
    final value = _selectedRating ?? 0;

    // Determine rating label and color
    String ratingLabel = '';
    int ratingColor = 0xFF9E9E9E;
    if (hasSelection) {
      if (value <= 2) {
        ratingLabel = 'Poor';
        ratingColor = 0xFFF44336; // Red
      } else if (value <= 4) {
        ratingLabel = 'Below Average';
        ratingColor = 0xFFFF9800; // Orange
      } else if (value <= 6) {
        ratingLabel = 'Average';
        ratingColor = 0xFFFFC107; // Amber
      } else if (value <= 8) {
        ratingLabel = 'Good';
        ratingColor = 0xFF8BC34A; // Light Green
      } else {
        ratingLabel = 'Excellent';
        ratingColor = 0xFF4CAF50; // Green
      }
    }

    _ratingContent.update('hasSelection', hasSelection);
    _ratingContent.update('selectedValue', value);
    _ratingContent.update('ratingLabel', ratingLabel);
    _ratingContent.update('ratingColor', ratingColor);
    _ratingContent.update('validationError', _ratingValidationError);

    // Individual rating selection states
    _ratingContent.update('is1Selected', value == 1);
    _ratingContent.update('is2Selected', value == 2);
    _ratingContent.update('is3Selected', value == 3);
    _ratingContent.update('is4Selected', value == 4);
    _ratingContent.update('is5Selected', value == 5);
    _ratingContent.update('is6Selected', value == 6);
    _ratingContent.update('is7Selected', value == 7);
    _ratingContent.update('is8Selected', value == 8);
    _ratingContent.update('is9Selected', value == 9);
    _ratingContent.update('is10Selected', value == 10);
  }

  void _updateAutocompleteContent() {
    final hasQuery = _searchQuery.isNotEmpty;
    final selectionCount = _selectedCities.length;
    final hasSelections = selectionCount > 0;
    final canAddMore = selectionCount < _maxCitySelections;
    final suggestions = _getFilteredCities();
    final showSuggestions = hasQuery && canAddMore && (suggestions.isNotEmpty || suggestions.isEmpty);
    final noResults = hasQuery && canAddMore && suggestions.isEmpty;

    // Selection count display and color
    final selectionCountDisplay = '$selectionCount / $_maxCitySelections';
    int selectionCountColor;
    if (selectionCount == 0) {
      selectionCountColor = 0xFF9E9E9E; // Grey
    } else if (selectionCount < _maxCitySelections) {
      selectionCountColor = 0xFF1976D2; // Blue
    } else {
      selectionCountColor = 0xFF4CAF50; // Green
    }

    _autocompleteContent.update('searchQuery', _searchQuery);
    _autocompleteContent.update('hasQuery', hasQuery);
    _autocompleteContent.update('hasSelections', hasSelections);
    _autocompleteContent.update('canAddMore', canAddMore);
    _autocompleteContent.update('selectionCount', selectionCount);
    _autocompleteContent.update('selectionCountDisplay', selectionCountDisplay);
    _autocompleteContent.update('selectionCountColor', selectionCountColor);
    _autocompleteContent.update('showSuggestions', showSuggestions);
    _autocompleteContent.update('noResults', noResults);
    _autocompleteContent.update('suggestionsHeader',
        suggestions.isEmpty ? '' : '${suggestions.length} result${suggestions.length == 1 ? '' : 's'}');
    _autocompleteContent.update('validationError', _autocompleteValidationError);

    // Submit button text
    final submitButtonText = selectionCount == 1
        ? 'Select City'
        : 'Select $selectionCount Cities';
    _autocompleteContent.update('submitButtonText', submitButtonText);

    // Selected cities summary for submission
    _autocompleteContent.update('selectedCitiesSummary',
        _selectedCities.map((c) => c['label']).join(', '));

    // Update individual selected cities (up to 3)
    for (int i = 1; i <= _maxCitySelections; i++) {
      final hasSelection = i <= selectionCount;
      _autocompleteContent.update('hasSelection$i', hasSelection);
      if (hasSelection) {
        final city = _selectedCities[i - 1];
        _autocompleteContent.update('selected${i}Id', city['id']!);
        _autocompleteContent.update('selected${i}Label', city['label']!);
      } else {
        _autocompleteContent.update('selected${i}Id', '');
        _autocompleteContent.update('selected${i}Label', '');
      }
    }

    // Update individual suggestions (up to 5)
    for (int i = 1; i <= 5; i++) {
      final hasSuggestion = i <= suggestions.length;
      _autocompleteContent.update('hasSuggestion$i', hasSuggestion);
      if (hasSuggestion) {
        final suggestion = suggestions[i - 1];
        _autocompleteContent.update('suggestion${i}Id', suggestion['id']!);
        _autocompleteContent.update('suggestion${i}Label', suggestion['label']!);
        _autocompleteContent.update('suggestion${i}Subtitle', suggestion['subtitle']!);
      } else {
        _autocompleteContent.update('suggestion${i}Id', '');
        _autocompleteContent.update('suggestion${i}Label', '');
        _autocompleteContent.update('suggestion${i}Subtitle', '');
      }
    }
  }

  void _updateAddressContent() {
    final hasState = _stateValue != null;
    final isValid = _isAddressValid();
    final isComplete = isValid && _streetError.isEmpty && _cityError.isEmpty &&
        _stateError.isEmpty && _zipError.isEmpty;

    // Calculate validation summary
    String validationSummary = '';
    if (_streetError.isNotEmpty || _cityError.isNotEmpty ||
        _stateError.isNotEmpty || _zipError.isNotEmpty) {
      final errors = <String>[];
      if (_streetError.isNotEmpty) errors.add('street');
      if (_cityError.isNotEmpty) errors.add('city');
      if (_stateError.isNotEmpty) errors.add('state');
      if (_zipError.isNotEmpty) errors.add('ZIP');
      validationSummary = 'Please fix: ${errors.join(', ')}';
    }

    _addressContent.update('street', _street);
    _addressContent.update('city', _city);
    _addressContent.update('stateValue', _stateValue ?? '');
    _addressContent.update('stateLabel', _stateLabel ?? '');
    _addressContent.update('zip', _zip);
    _addressContent.update('hasState', hasState);
    _addressContent.update('stateDisplay', hasState ? _stateLabel! : 'Select state');
    _addressContent.update('stateTextColor', hasState ? 0xFF212121 : 0xFF9E9E9E);
    _addressContent.update('stateBorderColor', _stateError.isEmpty ? 0xFF9E9E9E : 0xFFF44336);
    _addressContent.update('streetError', _streetError);
    _addressContent.update('cityError', _cityError);
    _addressContent.update('stateError', _stateError);
    _addressContent.update('zipError', _zipError);
    _addressContent.update('isValid', isValid);
    _addressContent.update('isComplete', isComplete);
    _addressContent.update('validationSummary', validationSummary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Forms (11-15)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Form 11: Rating Slider with Labels'),
            if (_ratingSliderLoaded)
              _buildForm(_ratingContent, 'formRatingSlider', 'RatingSliderForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 12: Autocomplete Search Field'),
            if (_autocompleteLoaded)
              _buildForm(_autocompleteContent, 'formAutocomplete', 'AutocompleteForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 13: Address Form'),
            if (_addressLoaded)
              _buildForm(_addressContent, 'formAddress', 'AddressForm')
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
