import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import 'transformers.dart';

/// Sample user data provider
final usersProvider = StateProvider<List<User>>((ref) {
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
});

/// Sample info card data provider
final infoCardProvider = StateProvider<InfoCardData>((ref) {
  return const InfoCardData(
    title: 'Welcome to RFW',
    description: 'This card demonstrates dynamic data binding with Remote Flutter Widgets.',
    iconName: 'info',
  );
});

/// Sample metrics provider
final metricsProvider = StateProvider<List<MetricData>>((ref) {
  return const [
    MetricData(label: 'Users', value: '1,234', changePercent: 12.5, isPositive: true),
    MetricData(label: 'Revenue', value: '\$45.6K', changePercent: -3.2, isPositive: false),
    MetricData(label: 'Orders', value: '892', changePercent: 8.1, isPositive: true),
  ];
});

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
