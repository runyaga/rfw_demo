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
  bool _creditCardLoaded = false;
  bool _registrationLoaded = false;

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

  // Form 14: Credit Card state
  String _cardNumber = '';
  String _cardNumberRaw = '';
  String _cardType = '';
  String _expiry = '';
  String _cvv = '';
  String _cardholderName = '';
  String _cardNumberError = '';
  String _expiryError = '';
  String _cvvError = '';
  String _nameError = '';
  final DynamicContent _creditCardContent = DynamicContent();

  // Form 15: Registration state
  int _currentSection = 1;
  // Section 1: Personal
  String _firstName = '';
  String _lastName = '';
  String _dob = '';
  String _regPhone = '';
  String _firstNameError = '';
  String _lastNameError = '';
  String _dobError = '';
  String _regPhoneError = '';
  // Section 2: Account
  String _regEmail = '';
  String _password = '';
  String _confirmPassword = '';
  String _regEmailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  // Section 3: Preferences
  bool _newsletter = false;
  String _contactMethod = 'email';
  final Set<String> _interests = {};
  String _sectionError = '';
  final DynamicContent _registrationContent = DynamicContent();

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
      } else if (formId == 'registration') {
        setState(() {
          _sectionError = '';
          switch (field) {
            // Section 1
            case 'firstName':
              _firstName = value;
              _firstNameError = '';
            case 'lastName':
              _lastName = value;
              _lastNameError = '';
            case 'dob':
              _dob = _formatDob(value);
              _dobError = '';
            case 'phone':
              _regPhone = _formatPhoneNumber(value);
              _regPhoneError = '';
            // Section 2
            case 'email':
              _regEmail = value;
              _regEmailError = '';
            case 'password':
              _password = value;
              _passwordError = '';
            case 'confirmPassword':
              _confirmPassword = value;
              _confirmPasswordError = '';
          }
          _updateRegistrationContent();
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
      } else if (formId == 'credit_card') {
        setState(() {
          _cardNumber = '';
          _cardNumberRaw = '';
          _cardType = '';
          _expiry = '';
          _cvv = '';
          _cardholderName = '';
          _cardNumberError = '';
          _expiryError = '';
          _cvvError = '';
          _nameError = '';
          _updateCreditCardContent();
        });
        _showSnackBar('Payment form cleared');
      }
    });

    // Form 14: Credit Card handlers
    _actionHandler.registerHandler('card_number_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('card_number_changed', 'length: ${value.length}');

      setState(() {
        _cardNumberRaw = value.replaceAll(RegExp(r'\D'), '');
        _cardNumber = _formatCardNumber(_cardNumberRaw);
        _cardType = _detectCardType(_cardNumberRaw);
        _cardNumberError = '';
        _updateCreditCardContent();
      });
    });

    _actionHandler.registerHandler('expiry_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('expiry_changed', 'value: $value');

      setState(() {
        _expiry = _formatExpiry(value);
        _expiryError = '';
        _updateCreditCardContent();
      });
    });

    _actionHandler.registerHandler('cvv_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('cvv_changed', 'length: ${value.length}');

      setState(() {
        _cvv = value.replaceAll(RegExp(r'\D'), '');
        _cvvError = '';
        _updateCreditCardContent();
      });
    });

    _actionHandler.registerHandler('name_changed', (args) {
      final value = args['value'] as String? ?? '';
      _logEvent('name_changed', 'value: $value');

      setState(() {
        _cardholderName = value.toUpperCase();
        _nameError = '';
        _updateCreditCardContent();
      });
    });

    // Form 15: Registration handlers
    _actionHandler.registerHandler('preference_changed', (args) {
      final field = args['field'] as String? ?? '';
      final value = args['value'];
      _logEvent('preference_changed', 'field: $field');

      setState(() {
        switch (field) {
          case 'newsletter':
            _newsletter = !_newsletter;
          case 'contactMethod':
            _contactMethod = value as String? ?? 'email';
        }
        _updateRegistrationContent();
      });
    });

    _actionHandler.registerHandler('interest_toggled', (args) {
      final interestId = args['interestId'] as String? ?? '';
      _logEvent('interest_toggled', 'interestId: $interestId');

      setState(() {
        if (_interests.contains(interestId)) {
          _interests.remove(interestId);
        } else {
          _interests.add(interestId);
        }
        _updateRegistrationContent();
      });
    });

    _actionHandler.registerHandler('form_next_section', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_next_section', 'formId: $formId, section: $_currentSection');

      if (formId == 'registration') {
        setState(() {
          _sectionError = '';
          if (_currentSection == 1) {
            if (_isSection1Valid()) {
              _currentSection = 2;
            } else {
              _validateSection1();
              _sectionError = 'Please complete all required fields';
            }
          } else if (_currentSection == 2) {
            if (_isSection2Valid()) {
              _currentSection = 3;
            } else {
              _validateSection2();
              _sectionError = 'Please complete all required fields';
            }
          }
          _updateRegistrationContent();
        });
      }
    });

    _actionHandler.registerHandler('form_prev_section', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_prev_section', 'formId: $formId, section: $_currentSection');

      if (formId == 'registration' && _currentSection > 1) {
        setState(() {
          _currentSection--;
          _sectionError = '';
          _updateRegistrationContent();
        });
      }
    });

    _actionHandler.registerHandler('form_start_over', (args) {
      final formId = args['formId'] as String? ?? 'unknown';
      _logEvent('form_start_over', 'formId: $formId');

      if (formId == 'registration') {
        setState(() {
          _currentSection = 1;
          _firstName = '';
          _lastName = '';
          _dob = '';
          _regPhone = '';
          _firstNameError = '';
          _lastNameError = '';
          _dobError = '';
          _regPhoneError = '';
          _regEmail = '';
          _password = '';
          _confirmPassword = '';
          _regEmailError = '';
          _passwordError = '';
          _confirmPasswordError = '';
          _newsletter = false;
          _contactMethod = 'email';
          _interests.clear();
          _sectionError = '';
          _updateRegistrationContent();
        });
        _showSnackBar('Registration form reset');
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
      } else if (formId == 'credit_card' && reason == 'invalid') {
        setState(() {
          _validateCreditCard();
          _updateCreditCardContent();
        });
      } else if (formId == 'registration' && reason == 'incomplete') {
        setState(() {
          _validateSection1();
          _validateSection2();
          _sectionError = 'Please complete all sections';
          _updateRegistrationContent();
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

  // Form 14: Credit Card helpers
  String _formatCardNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) {
      return '${digits.substring(0, 2)}/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
    }
    return digits;
  }

  String _detectCardType(String cardNumber) {
    if (cardNumber.isEmpty) return '';
    if (cardNumber.startsWith('4')) return 'visa';
    if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) return 'amex';
    final prefix = int.tryParse(cardNumber.substring(0, cardNumber.length >= 2 ? 2 : cardNumber.length)) ?? 0;
    if (prefix >= 51 && prefix <= 55) return 'mastercard';
    if (cardNumber.length >= 4) {
      final prefix4 = int.tryParse(cardNumber.substring(0, 4)) ?? 0;
      if (prefix4 >= 2221 && prefix4 <= 2720) return 'mastercard';
    }
    return '';
  }

  bool _luhnValidate(String cardNumber) {
    if (cardNumber.length < 13) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  bool _isExpiryValid(String expiry) {
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse(parts[1]) ?? 0;
    if (month < 1 || month > 12) return false;
    final now = DateTime.now();
    final currentYear = now.year % 100;
    final currentMonth = now.month;
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    return true;
  }

  int _getExpectedCvvLength() {
    return _cardType == 'amex' ? 4 : 3;
  }

  void _validateCreditCard() {
    if (_cardNumberRaw.isEmpty) {
      _cardNumberError = 'Card number is required';
    } else if (_cardNumberRaw.length < 13 || _cardNumberRaw.length > 16) {
      _cardNumberError = 'Invalid card number length';
    } else if (!_luhnValidate(_cardNumberRaw)) {
      _cardNumberError = 'Invalid card number';
    }

    if (_expiry.isEmpty) {
      _expiryError = 'Expiry is required';
    } else if (!_isExpiryValid(_expiry)) {
      _expiryError = 'Invalid or expired';
    }

    final expectedCvv = _getExpectedCvvLength();
    if (_cvv.isEmpty) {
      _cvvError = 'CVV required';
    } else if (_cvv.length != expectedCvv) {
      _cvvError = '$expectedCvv digits';
    }

    if (_cardholderName.isEmpty) {
      _nameError = 'Name is required';
    }
  }

  bool _isCreditCardValid() {
    if (_cardNumberRaw.length < 13 || _cardNumberRaw.length > 16) return false;
    if (!_luhnValidate(_cardNumberRaw)) return false;
    if (!_isExpiryValid(_expiry)) return false;
    final expectedCvv = _getExpectedCvvLength();
    if (_cvv.length != expectedCvv) return false;
    if (_cardholderName.isEmpty) return false;
    return true;
  }

  // Form 15: Registration helpers
  String _formatDob(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      final mm = digits.substring(0, 2);
      final dd = digits.substring(2, 4);
      final yyyy = digits.length > 4 ? digits.substring(4, digits.length > 8 ? 8 : digits.length) : '';
      return '$mm/$dd${yyyy.isNotEmpty ? '/$yyyy' : ''}';
    } else if (digits.length >= 2) {
      return '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return digits;
  }

  String _formatPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
    } else if (digits.length >= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length >= 3) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    return digits;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidDob(String dob) {
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dob)) return false;
    final parts = dob.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final day = int.tryParse(parts[1]) ?? 0;
    final year = int.tryParse(parts[2]) ?? 0;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 1900 || year > DateTime.now().year) return false;
    return true;
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  void _validateSection1() {
    if (_firstName.isEmpty) _firstNameError = 'First name is required';
    if (_lastName.isEmpty) _lastNameError = 'Last name is required';
    if (_dob.isEmpty) {
      _dobError = 'Date of birth is required';
    } else if (!_isValidDob(_dob)) {
      _dobError = 'Invalid date (MM/DD/YYYY)';
    }
    if (_regPhone.isEmpty) {
      _regPhoneError = 'Phone is required';
    } else if (!_isValidPhone(_regPhone)) {
      _regPhoneError = 'Invalid phone number';
    }
  }

  bool _isSection1Valid() {
    return _firstName.isNotEmpty &&
        _lastName.isNotEmpty &&
        _isValidDob(_dob) &&
        _isValidPhone(_regPhone);
  }

  void _validateSection2() {
    if (_regEmail.isEmpty) {
      _regEmailError = 'Email is required';
    } else if (!_isValidEmail(_regEmail)) {
      _regEmailError = 'Invalid email address';
    }
    if (_password.isEmpty) {
      _passwordError = 'Password is required';
    } else if (_password.length < 8) {
      _passwordError = 'Min 8 characters';
    }
    if (_confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm password';
    } else if (_confirmPassword != _password) {
      _confirmPasswordError = 'Passwords do not match';
    }
  }

  bool _isSection2Valid() {
    return _isValidEmail(_regEmail) &&
        _password.length >= 8 &&
        _confirmPassword == _password;
  }

  bool _canSubmitRegistration() {
    return _isSection1Valid() && _isSection2Valid();
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

    // Load Form 14
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_credit_card.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formCreditCard']), lib);
      _updateCreditCardContent();
      setState(() => _creditCardLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_credit_card.rfw: $e');
    }

    // Load Form 15
    try {
      final data =
          await rootBundle.load('assets/rfw/defaults/form_registration.rfw');
      final lib = decodeLibraryBlob(data.buffer.asUint8List());
      rfwEnvironment.runtime
          .update(const LibraryName(<String>['formRegistration']), lib);
      _updateRegistrationContent();
      setState(() => _registrationLoaded = true);
    } catch (e) {
      debugPrint('Failed to load form_registration.rfw: $e');
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

  void _updateCreditCardContent() {
    final isValid = _isCreditCardValid();

    // Calculate validation summary
    String validationSummary = '';
    if (_cardNumberError.isNotEmpty || _expiryError.isNotEmpty ||
        _cvvError.isNotEmpty || _nameError.isNotEmpty) {
      final errors = <String>[];
      if (_cardNumberError.isNotEmpty) errors.add('card number');
      if (_expiryError.isNotEmpty) errors.add('expiry');
      if (_cvvError.isNotEmpty) errors.add('CVV');
      if (_nameError.isNotEmpty) errors.add('name');
      validationSummary = 'Please fix: ${errors.join(', ')}';
    }

    _creditCardContent.update('cardNumber', _cardNumber);
    _creditCardContent.update('cardNumberRaw', _cardNumberRaw);
    _creditCardContent.update('cardType', _cardType);
    _creditCardContent.update('expiry', _expiry);
    _creditCardContent.update('cvv', _cvv);
    _creditCardContent.update('cardholderName', _cardholderName);
    _creditCardContent.update('cvvHint', _cardType == 'amex' ? '1234' : '123');
    _creditCardContent.update('cardNumberError', _cardNumberError);
    _creditCardContent.update('expiryError', _expiryError);
    _creditCardContent.update('cvvError', _cvvError);
    _creditCardContent.update('nameError', _nameError);
    _creditCardContent.update('isFormValid', isValid);
    _creditCardContent.update('validationSummary', validationSummary);
  }

  void _updateRegistrationContent() {
    final isSection1 = _currentSection == 1;
    final isSection2 = _currentSection == 2;
    final isSection3 = _currentSection == 3;
    final section1Valid = _isSection1Valid();
    final section2Valid = _isSection2Valid();
    final canSubmit = _canSubmitRegistration();

    // Current section validity for "Next" button
    bool canProceed = false;
    if (isSection1) canProceed = section1Valid;
    if (isSection2) canProceed = section2Valid;

    _registrationContent.update('currentSection', _currentSection);
    _registrationContent.update('isSection1', isSection1);
    _registrationContent.update('isSection2', isSection2);
    _registrationContent.update('isSection3', isSection3);
    _registrationContent.update('section1Complete', section1Valid);
    _registrationContent.update('section2Complete', section2Valid);
    _registrationContent.update('section3Complete', canSubmit);
    _registrationContent.update('canProceed', canProceed);
    _registrationContent.update('canSubmit', canSubmit);

    // Section 1 fields
    _registrationContent.update('firstName', _firstName);
    _registrationContent.update('lastName', _lastName);
    _registrationContent.update('dob', _dob);
    _registrationContent.update('phone', _regPhone);
    _registrationContent.update('firstNameError', _firstNameError);
    _registrationContent.update('lastNameError', _lastNameError);
    _registrationContent.update('dobError', _dobError);
    _registrationContent.update('phoneError', _regPhoneError);

    // Section 2 fields
    _registrationContent.update('email', _regEmail);
    _registrationContent.update('password', _password);
    _registrationContent.update('confirmPassword', _confirmPassword);
    _registrationContent.update('emailError', _regEmailError);
    _registrationContent.update('passwordError', _passwordError);
    _registrationContent.update('confirmPasswordError', _confirmPasswordError);

    // Section 3 fields
    _registrationContent.update('newsletter', _newsletter);
    _registrationContent.update('contactMethod', _contactMethod);
    _registrationContent.update('contactEmail', _contactMethod == 'email');
    _registrationContent.update('contactPhone', _contactMethod == 'phone');
    _registrationContent.update('contactSms', _contactMethod == 'sms');

    // Interests checkboxes
    _registrationContent.update('techChecked', _interests.contains('tech'));
    _registrationContent.update('sportsChecked', _interests.contains('sports'));
    _registrationContent.update('musicChecked', _interests.contains('music'));
    _registrationContent.update('travelChecked', _interests.contains('travel'));
    _registrationContent.update('foodChecked', _interests.contains('food'));
    _registrationContent.update('artChecked', _interests.contains('art'));
    _registrationContent.update('selectedInterests', _interests.toList().join(', '));

    // Error message
    _registrationContent.update('sectionError', _sectionError);
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
            _buildSectionTitle('Form 14: Credit Card Form'),
            if (_creditCardLoaded)
              _buildForm(_creditCardContent, 'formCreditCard', 'CreditCardForm')
            else
              _buildLoading(),
            const SizedBox(height: 16),
            _buildSectionTitle('Form 15: Registration Form'),
            if (_registrationLoaded)
              _buildForm(_registrationContent, 'formRegistration', 'RegistrationForm')
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
