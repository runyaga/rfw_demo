// Domain models for RFW demo feature
//
// These models represent the application's domain entities that will
// be transformed into DynamicContent for remote widgets.

/// User model for demonstrating data binding
class User {
  final String id;
  final String name;
  final String email;
  final UserStatus status;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    this.avatarUrl,
  });
}

/// User status for conditional rendering (Example 3)
enum UserStatus {
  active,
  inactive,
  pending,
}

/// Info card data model (Example 2)
class InfoCardData {
  final String title;
  final String description;
  final String? iconName;

  const InfoCardData({
    required this.title,
    required this.description,
    this.iconName,
  });
}

/// Metric data for dashboard examples
class MetricData {
  final String label;
  final String value;
  final double? changePercent;
  final bool isPositive;

  const MetricData({
    required this.label,
    required this.value,
    this.changePercent,
    this.isPositive = true,
  });
}
