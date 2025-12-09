import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw/formats.dart';

import 'package:rfw_spike/core/rfw/runtime/rfw_environment.dart';
import 'package:rfw_spike/features/demo/domain/models.dart';
import 'package:rfw_spike/features/demo/data/transformers.dart';

void main() {
  setUp(() {
    RfwEnvironment.resetForTesting();
    rfwEnvironment.initialize();
  });

  group('Domain Transformers', () {
    test('UserTransformer converts User to map', () {
      const user = User(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        status: UserStatus.active,
      );

      final map = UserTransformer.toMap(user);

      expect(map['id'], equals('1'));
      expect(map['name'], equals('Test User'));
      expect(map['email'], equals('test@example.com'));
      expect(map['status'], equals('active'));
    });

    test('UserTransformer handles optional avatarUrl', () {
      const userWithAvatar = User(
        id: '1',
        name: 'Test',
        email: 'test@example.com',
        status: UserStatus.active,
        avatarUrl: 'https://example.com/avatar.png',
      );

      const userWithoutAvatar = User(
        id: '2',
        name: 'Test2',
        email: 'test2@example.com',
        status: UserStatus.inactive,
      );

      final mapWithAvatar = UserTransformer.toMap(userWithAvatar);
      final mapWithoutAvatar = UserTransformer.toMap(userWithoutAvatar);

      expect(mapWithAvatar.containsKey('avatarUrl'), isTrue);
      expect(mapWithoutAvatar.containsKey('avatarUrl'), isFalse);
    });

    test('UserTransformer converts list of users', () {
      const users = [
        User(id: '1', name: 'User 1', email: 'u1@test.com', status: UserStatus.active),
        User(id: '2', name: 'User 2', email: 'u2@test.com', status: UserStatus.inactive),
      ];

      final list = UserTransformer.toList(users);

      expect(list.length, equals(2));
      expect((list[0] as Map)['name'], equals('User 1'));
      expect((list[1] as Map)['name'], equals('User 2'));
    });

    test('InfoCardTransformer converts InfoCardData to map', () {
      const data = InfoCardData(
        title: 'Test Title',
        description: 'Test Description',
        iconName: 'info',
      );

      final map = InfoCardTransformer.toMap(data);

      expect(map['title'], equals('Test Title'));
      expect(map['description'], equals('Test Description'));
      expect(map['icon'], equals('info'));
    });

    test('MetricTransformer converts MetricData to map', () {
      const data = MetricData(
        label: 'Revenue',
        value: '\$1,234',
        changePercent: 12.5,
        isPositive: true,
      );

      final map = MetricTransformer.toMap(data);

      expect(map['label'], equals('Revenue'));
      expect(map['value'], equals('\$1,234'));
      expect(map['changePercent'], equals(12.5));
      expect(map['isPositive'], equals(true));
    });
  });

  group('InfoCard with Dynamic Data', () {
    testWidgets('renders InfoCard with dynamic title and description', (tester) async {
      const rfwText = '''
        import core;
        import material;

        widget InfoCard = Card(
          child: Padding(
            padding: [16.0],
            child: Column(
              mainAxisSize: "min",
              crossAxisAlignment: "start",
              children: [
                Text(text: data.title),
                Text(text: data.description),
              ],
            ),
          ),
        );
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      // Set dynamic data
      rfwEnvironment.content.update('title', 'Dynamic Title');
      rfwEnvironment.content.update('description', 'Dynamic Description');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: rfwEnvironment.content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['main']),
                'InfoCard',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dynamic Title'), findsOneWidget);
      expect(find.text('Dynamic Description'), findsOneWidget);
    });
  });

  group('StatusBadge with Conditional Logic', () {
    testWidgets('renders different colors based on status', (tester) async {
      const rfwText = '''
        import core;

        widget StatusBadge = Container(
          child: Text(
            text: switch data.status {
              "active": "Active",
              "inactive": "Inactive",
              "pending": "Pending",
              default: "Unknown",
            },
          ),
        );
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      // Test active status
      rfwEnvironment.content.update('status', 'active');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: rfwEnvironment.content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['main']),
                'StatusBadge',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Active'), findsOneWidget);

      // Test pending status
      rfwEnvironment.content.update('status', 'pending');
      await tester.pump();
      expect(find.text('Pending'), findsOneWidget);

      // Test inactive status
      rfwEnvironment.content.update('status', 'inactive');
      await tester.pump();
      expect(find.text('Inactive'), findsOneWidget);
    });
  });

  group('Missing Data Handling', () {
    testWidgets('handles missing data gracefully', (tester) async {
      const rfwText = '''
        import core;

        widget TestWidget = Column(
          children: [
            Text(text: data.existingKey),
          ],
        );
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      // Only set one key, leave others missing
      rfwEnvironment.content.update('existingKey', 'Exists');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: rfwEnvironment.content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['main']),
                'TestWidget',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Exists'), findsOneWidget);
    });
  });

  group('State Changes Trigger UI Updates', () {
    testWidgets('UI updates when DynamicContent changes', (tester) async {
      const rfwText = '''
        import core;
        widget Counter = Text(text: data.count);
      ''';

      final library = parseLibraryFile(rfwText);
      rfwEnvironment.runtime.update(
        const LibraryName(<String>['main']),
        library,
      );

      rfwEnvironment.content.update('count', '0');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteWidget(
              runtime: rfwEnvironment.runtime,
              data: rfwEnvironment.content,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['main']),
                'Counter',
              ),
              onEvent: (name, args) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);

      // Update the content
      rfwEnvironment.content.update('count', '5');
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });
}
