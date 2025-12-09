import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import '../../../core/rfw/runtime/rfw_environment.dart';

/// Demo page showcasing Stage 9: Extended Widget Library
///
/// Demonstrates:
/// - Accordion/ExpansionTile widgets
/// - More widgets to be added as Stage 9 progresses
class ExtendedWidgetsDemoPage extends StatefulWidget {
  const ExtendedWidgetsDemoPage({super.key});

  @override
  State<ExtendedWidgetsDemoPage> createState() => _ExtendedWidgetsDemoPageState();
}

class _ExtendedWidgetsDemoPageState extends State<ExtendedWidgetsDemoPage> {
  bool _initialized = false;
  String _lastEvent = '';
  final List<String> _loadedWidgets = [];

  // Track accordion expansion state
  final Map<String, bool> _expandedSections = {
    'faq-1': false,
    'faq-2': true,
    'faq-3': false,
  };

  // Track tab selection state
  int _selectedTabIndex = 0;
  final List<String> _tabContents = [
    'This is the content for Tab 1. It shows information about the first topic.',
    'This is the content for Tab 2. It displays details about the second topic.',
    'This is the content for Tab 3. Here you can find the third topic information.',
  ];

  // Track dropdown selection state
  String _selectedDropdownValue = 'option1';
  final List<Map<String, String>> _dropdownOptions = [
    {'value': 'option1', 'label': 'Option 1'},
    {'value': 'option2', 'label': 'Option 2'},
    {'value': 'option3', 'label': 'Option 3'},
  ];

  // Track bottom nav selection state
  int _selectedNavIndex = 0;
  final List<String> _navPageContents = [
    'Welcome to the Home page! This is where you start.',
    'Search for anything here. Find what you need.',
    'Your profile settings and preferences.',
  ];

  // Track composite bottom nav state
  int _compositeNavIndex = 0;
  String _selectedOption = 'option1';
  bool _checkbox1 = false;
  bool _checkbox2 = true;
  bool _checkbox3 = false;

  // Track datetime picker state
  String _selectedDate = '2024-12-09';
  String _selectedTime = '14:30';
  String _appointmentDate = '2024-12-15';
  String _appointmentStartTime = '09:00';
  String _appointmentEndTime = '10:00';

  // Track map viewer state
  double _mapLatitude = 37.7749;
  double _mapLongitude = -122.4194;
  double _mapZoom = 13.0;
  String _selectedLocationName = 'San Francisco';
  String _selectedLocationDetails = 'California, USA';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }

    // Load Stage 9 widgets
    final widgets = [
      'accordion',
      'tabbed_content',
      'breadcrumbs',
      'skeleton_loader',
      'dropdown_selector',
      'bottom_nav',
      'datetime_picker',
      'map_viewer',
    ];

    for (final widgetId in widgets) {
      try {
        final data = await rootBundle.load('assets/rfw/defaults/$widgetId.rfw');
        final lib = decodeLibraryBlob(data.buffer.asUint8List());
        rfwEnvironment.runtime.update(
          LibraryName(<String>[widgetId]),
          lib,
        );
        _loadedWidgets.add(widgetId);
      } catch (e) {
        debugPrint('Failed to load $widgetId: $e');
      }
    }

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  void _handleEvent(String name, DynamicMap args) {
    final argsStr = args.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    setState(() {
      _lastEvent = '$name($argsStr)';

      // Handle accordion expansion events
      if (name == 'accordion_expand' || name == 'panel_expand') {
        final sectionId = args['sectionId']?.toString() ?? args['panelId']?.toString();
        if (sectionId != null) {
          _expandedSections[sectionId] = !(args['expanded'] as bool? ?? false);
        }
      }

      // Handle tab selection events
      if (name == 'tab_selected') {
        final index = args['index'];
        // RFW may send numbers as int or double
        if (index is int) {
          _selectedTabIndex = index;
        } else if (index is double) {
          _selectedTabIndex = index.toInt();
        } else if (index is num) {
          _selectedTabIndex = index.toInt();
        }
      }

      // Handle dropdown selection events
      if (name == 'dropdown_selected') {
        final value = args['value']?.toString();
        if (value != null) {
          _selectedDropdownValue = value;
        }
      }

      // Handle bottom nav events
      if (name == 'nav_item_tapped') {
        final index = args['index'];
        if (index is int) {
          _selectedNavIndex = index;
        } else if (index is num) {
          _selectedNavIndex = index.toInt();
        }
      }

      // Handle composite nav events
      if (name == 'composite_nav_tapped') {
        final index = args['index'];
        if (index is int) {
          _compositeNavIndex = index;
        } else if (index is num) {
          _compositeNavIndex = index.toInt();
        }
      }

      // Handle option selection
      if (name == 'option_selected') {
        final optionId = args['optionId']?.toString();
        if (optionId != null) {
          _selectedOption = optionId;
        }
      }

      // Handle checkbox toggle
      if (name == 'checkbox_toggled') {
        final checkboxId = args['checkboxId']?.toString();
        final currentValue = args['currentValue'];
        final newValue = !(currentValue == true);
        if (checkboxId == 'checkbox1') {
          _checkbox1 = newValue;
        } else if (checkboxId == 'checkbox2') {
          _checkbox2 = newValue;
        } else if (checkboxId == 'checkbox3') {
          _checkbox3 = newValue;
        }
      }

      // Handle submit events (just log for demo)
      if (name == 'options_submit') {
        debugPrint('Options submitted: ${args['selectedOption']}');
      }
      if (name == 'checkboxes_submit') {
        debugPrint('Checkboxes submitted: ${args['checkbox1']}, ${args['checkbox2']}, ${args['checkbox3']}');
      }

      // Handle datetime picker events
      if (name == 'pick_datetime' || name == 'pick_date') {
        // In a real app, show native date picker and update _selectedDate
        _showDatePickerDemo();
      }
      if (name == 'pick_time') {
        // In a real app, show native time picker and update _selectedTime
        _showTimePickerDemo();
      }
      if (name == 'pick_appointment_date') {
        _showAppointmentDatePicker();
      }
      if (name == 'pick_start_time') {
        _showStartTimePicker();
      }
      if (name == 'pick_end_time') {
        _showEndTimePicker();
      }

      // Handle map events
      if (name == 'map_tap' || name == 'location_selected') {
        final lat = args['lat'];
        final lng = args['lng'];
        if (lat is num && lng is num) {
          _mapLatitude = lat.toDouble();
          _mapLongitude = lng.toDouble();
          _selectedLocationName = 'Selected Location';
          _selectedLocationDetails = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      }
      if (name == 'marker_tap' || name == 'store_selected') {
        final label = args['label']?.toString() ?? 'Unknown';
        final lat = args['lat'];
        final lng = args['lng'];
        _selectedLocationName = label;
        if (lat is num && lng is num) {
          _selectedLocationDetails = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      }
      if (name == 'zoom_in') {
        _mapZoom = (_mapZoom + 1).clamp(1.0, 18.0);
      }
      if (name == 'zoom_out') {
        _mapZoom = (_mapZoom - 1).clamp(1.0, 18.0);
      }
      if (name == 'center_location') {
        // Reset to default location
        _mapLatitude = 37.7749;
        _mapLongitude = -122.4194;
      }
      if (name == 'get_directions') {
        debugPrint('Get directions requested');
      }
    });
    debugPrint('Event: $name, args: $args');
  }

  Future<void> _showDatePickerDemo() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        _selectedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _showTimePickerDemo() async {
    final parts = _selectedTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 12,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null && mounted) {
      setState(() {
        _selectedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _showAppointmentDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_appointmentDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null && mounted) {
      setState(() {
        _appointmentDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _showStartTimePicker() async {
    final parts = _appointmentStartTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null && mounted) {
      setState(() {
        _appointmentStartTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _showEndTimePicker() async {
    final parts = _appointmentEndTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (time != null && mounted) {
      setState(() {
        _appointmentEndTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage 9: Extended Widgets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDescription(),
                  const SizedBox(height: 16),
                  if (_lastEvent.isNotEmpty) _buildEventDisplay(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Accordion / ExpansionTile'),
                  _buildAccordionDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Expandable Panel with Icon'),
                  _buildExpandablePanelDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Tabs'),
                  _buildTabsDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Breadcrumbs'),
                  _buildBreadcrumbsDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Skeleton Loaders'),
                  _buildSkeletonDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Dropdown Selector'),
                  _buildDropdownDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Bottom Navigation'),
                  _buildBottomNavDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Composite Bottom Nav (Options & Checkboxes)'),
                  _buildCompositeBottomNavDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('DateTime Picker'),
                  _buildDateTimePickerDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Appointment Picker'),
                  _buildAppointmentPickerDemo(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('GIS Map Viewer'),
                  _buildMapViewerDemo(),
                ],
              ),
            ),
    );
  }

  Widget _buildDescription() {
    return Card(
      color: Colors.deepPurple.shade50,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stage 9: Extended Widget Library',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This demo showcases additional high-value UX patterns that '
              'demonstrate RFW\'s versatility and identify architectural boundaries.',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              'Widgets:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '• Accordion - Collapsible sections using ExpansionTile\n'
              '• Expandable Panel - Single expandable content area\n'
              '• Tabs - Horizontal tab bar with switchable content\n'
              '• Breadcrumbs - Navigation path display\n'
              '• Skeleton Loader - Loading placeholders\n'
              '• Dropdown Selector - Selection from options\n'
              '• Bottom Navigation - App-level navigation\n'
              '• DateTime Picker - Date/time selection with native dialogs\n'
              '• GIS Map Viewer - OpenStreetMap with markers and events',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDisplay() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last Event: $_lastEvent',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
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

  Widget _buildAccordionDemo() {
    // Build FAQ-style accordion with multiple sections
    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildAccordionSection(
            title: 'What is Remote Flutter Widgets?',
            content: 'Remote Flutter Widgets (RFW) is a Flutter package that '
                'enables server-driven UI. It allows you to define widget trees '
                'in a declarative format that can be fetched from a server and '
                'rendered by the client without app updates.',
            sectionId: 'faq-1',
            sectionIndex: 0,
            expanded: _expandedSections['faq-1'] ?? false,
          ),
          const Divider(height: 1),
          _buildAccordionSection(
            title: 'How does event handling work?',
            content: 'RFW widgets are stateless. When a user interacts with a '
                'widget, it fires an event with associated data. The host app '
                'catches these events, updates local state, and refreshes the '
                'DynamicContent which triggers a rebuild.',
            sectionId: 'faq-2',
            sectionIndex: 1,
            expanded: _expandedSections['faq-2'] ?? false,
          ),
          const Divider(height: 1),
          _buildAccordionSection(
            title: 'Can I use custom widgets?',
            content: 'Yes! You can register custom Flutter widgets in your '
                'LocalWidgetLibrary. This allows RFW to reference your design '
                'system components, third-party packages, or any custom widgets '
                'you\'ve built.',
            sectionId: 'faq-3',
            sectionIndex: 2,
            expanded: _expandedSections['faq-3'] ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required String content,
    required String sectionId,
    required int sectionIndex,
    required bool expanded,
  }) {
    final dynamicContent = DynamicContent();
    dynamicContent.update('title', title);
    dynamicContent.update('content', content);
    dynamicContent.update('sectionId', sectionId);
    dynamicContent.update('sectionIndex', sectionIndex);
    dynamicContent.update('expanded', expanded);

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: dynamicContent,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['accordion']),
        'AccordionSection',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildExpandablePanelDemo() {
    final content = DynamicContent();
    content.update('title', 'Advanced Settings');
    content.update('content', 'Here you can configure advanced settings for your '
        'application. These settings are typically used by power users who need '
        'fine-grained control over behavior. Changes may require an app restart.');
    content.update('panelId', 'advanced-settings');
    content.update('expanded', false);
    content.update('iconCode', 0xe8b8); // settings icon

    return Card(
      elevation: 1,
      child: RemoteWidget(
        runtime: rfwEnvironment.runtime,
        data: content,
        widget: const FullyQualifiedWidgetName(
          LibraryName(<String>['accordion']),
          'ExpandablePanelWithIcon',
        ),
        onEvent: _handleEvent,
      ),
    );
  }

  Widget _buildTabsDemo() {
    final content = DynamicContent();
    content.update('selectedIndex', _selectedTabIndex);
    content.update('tab1Label', 'Overview');
    content.update('tab1Icon', 0xe88a); // home icon
    content.update('tab2Label', 'Details');
    content.update('tab2Icon', 0xe8b8); // settings icon
    content.update('tab3Label', 'Reviews');
    content.update('tab3Icon', 0xe8e8); // star icon
    content.update('content', _tabContents[_selectedTabIndex]);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: RemoteWidget(
          runtime: rfwEnvironment.runtime,
          data: content,
          widget: const FullyQualifiedWidgetName(
            LibraryName(<String>['tabbed_content']),
            'ThreeTabLayout',
          ),
          onEvent: _handleEvent,
        ),
      ),
    );
  }

  Widget _buildBreadcrumbsDemo() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Three-level breadcrumb:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildThreeLevelBreadcrumb(),
            const SizedBox(height: 16),
            const Text(
              'Breadcrumb with home icon:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildBreadcrumbWithIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildThreeLevelBreadcrumb() {
    final content = DynamicContent();
    content.update('item1Label', 'Home');
    content.update('item1Route', '/');
    content.update('item2Label', 'Products');
    content.update('item2Route', '/products');
    content.update('item3Label', 'Widget Details');
    content.update('separator', ' > ');

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['breadcrumbs']),
        'ThreeLevelBreadcrumb',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildBreadcrumbWithIcon() {
    final content = DynamicContent();
    content.update('item1Label', 'Dashboard');
    content.update('item1Route', '/dashboard');
    content.update('item2Label', 'Settings');
    content.update('separator', ' / ');

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['breadcrumbs']),
        'BreadcrumbWithIcon',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildSkeletonDemo() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'List Item Skeleton:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildSkeletonListItem(),
            const Divider(height: 24),
            const Text(
              'Card Skeleton:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildSkeletonCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonListItem() {
    final content = DynamicContent();
    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['skeleton_loader']),
        'SkeletonListItem',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildSkeletonCard() {
    final content = DynamicContent();
    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['skeleton_loader']),
        'SkeletonCard',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildDropdownDemo() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected: $_selectedDropdownValue',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildDropdownSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSelector() {
    final content = DynamicContent();
    content.update('selectedValue', _selectedDropdownValue);
    content.update('label', 'Choose an option');
    content.update('optionCount', _dropdownOptions.length);
    content.update('options', _dropdownOptions);
    content.update('width', 250.0);

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['dropdown_selector']),
        'DropdownSelector',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildBottomNavDemo() {
    final content = DynamicContent();
    content.update('selectedIndex', _selectedNavIndex);
    content.update('item0Label', 'Home');
    content.update('item0Icon', 0xe88a); // home icon
    content.update('item1Label', 'Search');
    content.update('item1Icon', 0xe8b6); // search icon
    content.update('item2Label', 'Profile');
    content.update('item2Icon', 0xe7fd); // person icon
    content.update('pageContent', _navPageContents[_selectedNavIndex]);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: RemoteWidget(
          runtime: rfwEnvironment.runtime,
          data: content,
          widget: const FullyQualifiedWidgetName(
            LibraryName(<String>['bottom_nav']),
            'BottomNavScaffold',
          ),
          onEvent: _handleEvent,
        ),
      ),
    );
  }

  Widget _buildCompositeBottomNavDemo() {
    final content = DynamicContent();
    content.update('selectedIndex', _compositeNavIndex);

    // Options page data
    content.update('selectedOption', _selectedOption);
    content.update('option1Value', 'fast');
    content.update('option1Label', 'Fast');
    content.update('option1Icon', 0xe8b5); // flash icon
    content.update('option2Value', 'balanced');
    content.update('option2Label', 'Balanced');
    content.update('option2Icon', 0xe8b8); // settings icon
    content.update('option3Value', 'thorough');
    content.update('option3Label', 'Thorough');
    content.update('option3Icon', 0xe8b6); // search icon

    // Checkboxes page data
    content.update('checkbox1Label', 'Enable notifications');
    content.update('checkbox1Checked', _checkbox1);
    content.update('checkbox2Label', 'Auto-save drafts');
    content.update('checkbox2Checked', _checkbox2);
    content.update('checkbox3Label', 'Dark mode');
    content.update('checkbox3Checked', _checkbox3);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 320,
        child: RemoteWidget(
          runtime: rfwEnvironment.runtime,
          data: content,
          widget: const FullyQualifiedWidgetName(
            LibraryName(<String>['bottom_nav']),
            'CompositeBottomNav',
          ),
          onEvent: _handleEvent,
        ),
      ),
    );
  }

  Widget _buildDateTimePickerDemo() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: $_selectedDate  |  Time: $_selectedTime',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildDateTimeRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow() {
    final content = DynamicContent();
    content.update('dateLabel', 'Date');
    content.update('timeLabel', 'Time');
    content.update('selectedDate', _selectedDate);
    content.update('selectedTime', _selectedTime);

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['datetime_picker']),
        'DateTimeRow',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildAppointmentPickerDemo() {
    final content = DynamicContent();
    content.update('title', 'Schedule Meeting');
    content.update('appointmentDate', _appointmentDate);
    content.update('startTime', _appointmentStartTime);
    content.update('endTime', _appointmentEndTime);

    return RemoteWidget(
      runtime: rfwEnvironment.runtime,
      data: content,
      widget: const FullyQualifiedWidgetName(
        LibraryName(<String>['datetime_picker']),
        'AppointmentPicker',
      ),
      onEvent: _handleEvent,
    );
  }

  Widget _buildMapViewerDemo() {
    final content = DynamicContent();
    content.update('title', 'Location');
    content.update('height', 250.0);
    content.update('mapHeight', 200.0);
    content.update('latitude', _mapLatitude);
    content.update('longitude', _mapLongitude);
    content.update('zoom', _mapZoom);
    content.update('locationName', _selectedLocationName);
    content.update('locationDetails', _selectedLocationDetails);
    content.update('markerCount', 2);
    content.update('markers', <Object>[
      <String, Object>{
        'lat': 37.7749,
        'lng': -122.4194,
        'label': 'San Francisco',
        'id': 'sf',
      },
      <String, Object>{
        'lat': 37.8044,
        'lng': -122.2712,
        'label': 'Oakland',
        'id': 'oak',
      },
    ]);
    content.update('enableTapToSelect', true);

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 350,
        child: RemoteWidget(
          runtime: rfwEnvironment.runtime,
          data: content,
          widget: const FullyQualifiedWidgetName(
            LibraryName(<String>['map_viewer']),
            'MapWithInfoPanel',
          ),
          onEvent: _handleEvent,
        ),
      ),
    );
  }
}
