import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw/formats.dart';

import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';
import 'package:rfw_spike/core/rfw/registry/core_registry.dart';
import 'package:rfw_spike/core/rfw/registry/material_registry.dart';

void main() {
  setUpAll(() {
    RfwEnvironment.resetForTesting();
    if (!rfwEnvironment.isInitialized) {
      rfwEnvironment.initialize();
    }
  });

  group('DateTimePicker', () {
    late WidgetLibrary lib;

    setUpAll(() {
      final bytes = File('assets/rfw/defaults/datetime_picker.rfw').readAsBytesSync();
      lib = decodeLibraryBlob(bytes);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['datetime_picker']),
        lib,
      );
    });

    testWidgets('SimpleDatePicker renders with label', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Select Date');
      content.update('selectedDate', '2024-12-09');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'SimpleDatePicker',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the label
      expect(find.text('Select Date'), findsOneWidget);

      // Should display the selected date
      expect(find.text('2024-12-09'), findsOneWidget);
    });

    testWidgets('SimpleTimePicker renders with time', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Select Time');
      content.update('selectedTime', '14:30');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'SimpleTimePicker',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the label
      expect(find.text('Select Time'), findsOneWidget);

      // Should display the selected time
      expect(find.text('14:30'), findsOneWidget);
    });

    testWidgets('SimpleDateTimePicker renders with date and time', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Appointment');
      content.update('selectedDate', '2024-12-09');
      content.update('selectedTime', '10:00');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'SimpleDateTimePicker',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the label
      expect(find.text('Appointment'), findsOneWidget);

      // Should display combined date and time
      expect(find.text('2024-12-09 10:00'), findsOneWidget);
    });

    testWidgets('SimpleDatePicker fires pick_datetime event on tap', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Select Date');
      content.update('selectedDate', '2024-12-09');

      String? eventName;
      Map<String, Object?>? eventArgs;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'SimpleDatePicker',
                ),
                onEvent: (name, args) {
                  eventName = name;
                  eventArgs = args;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the picker
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Should fire pick_datetime event
      expect(eventName, 'pick_datetime');
      expect(eventArgs?['mode'], 'date');
      expect(eventArgs?['currentDate'], '2024-12-09');
    });

    testWidgets('DatePickerCard renders with title and description', (tester) async {
      final content = DynamicContent();
      content.update('title', 'Schedule Meeting');
      content.update('description', 'Choose a date for your meeting');
      content.update('label', 'Meeting Date');
      content.update('mode', 'date');
      content.update('selectedDate', '2024-12-15');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'DatePickerCard',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display title
      expect(find.text('Schedule Meeting'), findsOneWidget);

      // Should display description
      expect(find.text('Choose a date for your meeting'), findsOneWidget);

      // Should display label
      expect(find.text('Meeting Date'), findsOneWidget);

      // Should display selected date
      expect(find.text('2024-12-15'), findsOneWidget);

      // Should have a Card
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('DateTimeRow renders date and time pickers side by side', (tester) async {
      final content = DynamicContent();
      content.update('dateLabel', 'Date');
      content.update('timeLabel', 'Time');
      content.update('selectedDate', '2024-12-09');
      content.update('selectedTime', '15:00');

      String? lastEventName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RemoteWidget(
                  runtime: rfwEnvironment.runtime,
                  data: content,
                  widget: const FullyQualifiedWidgetName(
                    LibraryName(<String>['datetime_picker']),
                    'DateTimeRow',
                  ),
                  onEvent: (name, args) {
                    lastEventName = name;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display both labels
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);

      // Should display both values
      expect(find.text('2024-12-09'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);

      // Should have Row layout
      expect(find.byType(Row), findsWidgets);

      // Tap the date picker (first InkWell)
      final inkWells = find.byType(InkWell);
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();
      expect(lastEventName, 'pick_date');

      // Tap the time picker (second InkWell)
      await tester.tap(inkWells.last);
      await tester.pumpAndSettle();
      expect(lastEventName, 'pick_time');
    });

    testWidgets('DateRangePicker renders start and end date pickers', (tester) async {
      final content = DynamicContent();
      content.update('title', 'Select Date Range');
      content.update('startLabel', 'From');
      content.update('endLabel', 'To');
      content.update('startDate', '2024-12-01');
      content.update('endDate', '2024-12-31');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RemoteWidget(
                  runtime: rfwEnvironment.runtime,
                  data: content,
                  widget: const FullyQualifiedWidgetName(
                    LibraryName(<String>['datetime_picker']),
                    'DateRangePicker',
                  ),
                  onEvent: (name, args) {},
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display title
      expect(find.text('Select Date Range'), findsOneWidget);

      // Should display "to" separator
      expect(find.text('to'), findsOneWidget);

      // Should display both labels
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);

      // Should display both dates
      expect(find.text('2024-12-01'), findsOneWidget);
      expect(find.text('2024-12-31'), findsOneWidget);
    });

    testWidgets('DateRangePicker fires correct events for start and end dates', (tester) async {
      final content = DynamicContent();
      content.update('title', 'Select Date Range');
      content.update('startLabel', 'From');
      content.update('endLabel', 'To');
      content.update('startDate', '2024-12-01');
      content.update('endDate', '2024-12-31');

      final firedEvents = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RemoteWidget(
                  runtime: rfwEnvironment.runtime,
                  data: content,
                  widget: const FullyQualifiedWidgetName(
                    LibraryName(<String>['datetime_picker']),
                    'DateRangePicker',
                  ),
                  onEvent: (name, args) {
                    firedEvents.add(name);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the InkWell widgets for the pickers
      final inkWells = find.byType(InkWell);

      // Tap start date picker
      await tester.tap(inkWells.first);
      await tester.pumpAndSettle();
      expect(firedEvents.contains('pick_start_date'), isTrue);

      // Tap end date picker
      await tester.tap(inkWells.last);
      await tester.pumpAndSettle();
      expect(firedEvents.contains('pick_end_date'), isTrue);
    });

    testWidgets('AppointmentPicker renders full scheduling UI', (tester) async {
      final content = DynamicContent();
      content.update('title', 'Book Appointment');
      content.update('appointmentDate', '2024-12-10');
      content.update('startTime', '09:00');
      content.update('endTime', '10:00');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'AppointmentPicker',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display title
      expect(find.text('Book Appointment'), findsOneWidget);

      // Should display date
      expect(find.text('2024-12-10'), findsOneWidget);

      // Should display start and end times
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);

      // Should have a Card
      expect(find.byType(Card), findsOneWidget);

      // Should display labels
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
    });

    testWidgets('DisabledDatePicker renders disabled state', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Fixed Date');
      content.update('mode', 'date');
      content.update('selectedDate', '2024-01-01');
      content.update('displayValue', 'January 1, 2024');

      String? eventName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'DisabledDatePicker',
                ),
                onEvent: (name, args) {
                  eventName = name;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the label
      expect(find.text('Fixed Date'), findsOneWidget);

      // Should display the formatted value
      expect(find.text('January 1, 2024'), findsOneWidget);

      // Tapping should not fire event (disabled)
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(eventName, isNull);
    });

    testWidgets('DatePickerWithDisplay shows custom display value', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Birthday');
      content.update('selectedDate', '1990-05-15');
      content.update('displayValue', 'May 15, 1990');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'DatePickerWithDisplay',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the label
      expect(find.text('Birthday'), findsOneWidget);

      // Should display the custom formatted value, not the raw date
      expect(find.text('May 15, 1990'), findsOneWidget);
      expect(find.text('1990-05-15'), findsNothing);
    });

    testWidgets('SimpleDatePicker shows "Not selected" when no date', (tester) async {
      final content = DynamicContent();
      content.update('label', 'Select Date');
      // No selectedDate provided

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: rfwEnvironment.runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['datetime_picker']),
                  'SimpleDatePicker',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display the label
      expect(find.text('Select Date'), findsOneWidget);

      // Should display placeholder text
      expect(find.text('Not selected'), findsOneWidget);
    });
  });

  group('DateTimePicker Native Widget', () {
    // Test the registered DateTimePicker widget directly

    testWidgets('renders with all properties', (tester) async {
      final runtime = Runtime();
      runtime.update(const LibraryName(<String>['core']), createAppCoreWidgets());
      runtime.update(const LibraryName(<String>['material']), createAppMaterialWidgets());

      // Create a simple RFW widget that uses DateTimePicker
      const source = '''
import core;
import material;

widget TestDateTimePicker = DateTimePicker(
  label: data.label,
  mode: data.mode,
  selectedDate: data.selectedDate,
  selectedTime: data.selectedTime,
  enabled: true,
  onTap: event "test_pick" { },
);
''';
      final lib = parseLibraryFile(source);
      runtime.update(const LibraryName(<String>['test']), lib);

      final content = DynamicContent();
      content.update('label', 'Test Label');
      content.update('mode', 'datetime');
      content.update('selectedDate', '2024-12-25');
      content.update('selectedTime', '12:00');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RemoteWidget(
                runtime: runtime,
                data: content,
                widget: const FullyQualifiedWidgetName(
                  LibraryName(<String>['test']),
                  'TestDateTimePicker',
                ),
                onEvent: (name, args) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render the label
      expect(find.text('Test Label'), findsOneWidget);

      // Should render combined display value
      expect(find.text('2024-12-25 12:00'), findsOneWidget);
    });
  });
}
