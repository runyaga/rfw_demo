import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'transformers.dart';

/// Users state notifier for Riverpod 3.0
class UsersNotifier extends Notifier<List<User>> {
  @override
  List<User> build() {
    return const [
      User(
        id: '1',
        name: 'Alice Johnson',
        email: 'alice@example.com',
        status: UserStatus.active,
      ),
      User(
        id: '2',
        name: 'Bob Smith',
        email: 'bob@example.com',
        status: UserStatus.inactive,
      ),
      User(
        id: '3',
        name: 'Carol Williams',
        email: 'carol@example.com',
        status: UserStatus.pending,
      ),
    ];
  }

  void update(List<User> users) => state = users;
}

/// Sample user data provider
final usersProvider = NotifierProvider<UsersNotifier, List<User>>(UsersNotifier.new);

/// Info card state notifier for Riverpod 3.0
class InfoCardNotifier extends Notifier<InfoCardData> {
  @override
  InfoCardData build() {
    return const InfoCardData(
      title: 'Welcome to RFW',
      description: 'This card demonstrates dynamic data binding with Remote Flutter Widgets.',
      iconName: 'info',
    );
  }

  void update(InfoCardData data) => state = data;
}

/// Sample info card data provider
final infoCardProvider = NotifierProvider<InfoCardNotifier, InfoCardData>(InfoCardNotifier.new);

/// Metrics state notifier for Riverpod 3.0
class MetricsNotifier extends Notifier<List<MetricData>> {
  @override
  List<MetricData> build() {
    return const [
      MetricData(label: 'Users', value: '1,234', changePercent: 12.5, isPositive: true),
      MetricData(label: 'Revenue', value: '\$45.6K', changePercent: -3.2, isPositive: false),
      MetricData(label: 'Orders', value: '892', changePercent: 8.1, isPositive: true),
    ];
  }

  void update(List<MetricData> metrics) => state = metrics;
}

/// Sample metrics provider
final metricsProvider = NotifierProvider<MetricsNotifier, List<MetricData>>(MetricsNotifier.new);

/// Provider that transforms users to DynamicContent format
final usersContentProvider = Provider<List<Object>>((ref) {
  final users = ref.watch(usersProvider);
  return UserTransformer.toList(users);
});

/// Provider that transforms info card to DynamicContent format
final infoCardContentProvider = Provider<Map<String, Object>>((ref) {
  final infoCard = ref.watch(infoCardProvider);
  return InfoCardTransformer.toMap(infoCard);
});

/// Provider that transforms metrics to DynamicContent format
final metricsContentProvider = Provider<List<Object>>((ref) {
  final metrics = ref.watch(metricsProvider);
  return MetricTransformer.toList(metrics);
});

/// Combined content provider for full page data
final pageContentProvider = Provider<Map<String, Object>>((ref) {
  return {
    'users': ref.watch(usersContentProvider),
    'infoCard': ref.watch(infoCardContentProvider),
    'metrics': ref.watch(metricsContentProvider),
  };
});
