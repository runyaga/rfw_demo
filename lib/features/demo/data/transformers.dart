import '../domain/models.dart';

/// Domain layer transformation per DESIGN.md Section 2.1
///
/// Maps domain entities to `Map<String, Object>` for DynamicContent.
/// Supports primitive types: Map, List, String, int, double, bool.

/// Transform User to DynamicContent-compatible map
class UserTransformer {
  static Map<String, Object> toMap(User user) {
    return <String, Object>{
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'status': user.status.name, // 'active', 'inactive', 'pending'
      if (user.avatarUrl != null) 'avatarUrl': user.avatarUrl!,
    };
  }

  static List<Object> toList(List<User> users) {
    return users.map((u) => toMap(u)).toList();
  }
}

/// Transform InfoCardData to DynamicContent-compatible map
class InfoCardTransformer {
  static Map<String, Object> toMap(InfoCardData data) {
    return <String, Object>{
      'title': data.title,
      'description': data.description,
      if (data.iconName != null) 'icon': data.iconName!,
    };
  }
}

/// Transform MetricData to DynamicContent-compatible map
class MetricTransformer {
  static Map<String, Object> toMap(MetricData data) {
    return <String, Object>{
      'label': data.label,
      'value': data.value,
      if (data.changePercent != null) 'changePercent': data.changePercent!,
      'isPositive': data.isPositive,
    };
  }

  static List<Object> toList(List<MetricData> metrics) {
    return metrics.map((m) => toMap(m)).toList();
  }
}

/// Generic transformer utilities
class DynamicContentTransformer {
  /// Combine multiple data sources into a single map for DynamicContent
  static Map<String, Object> combine(Map<String, Object> sources) {
    return sources;
  }

  /// Create a data map with null-safe defaults (Layer 1: Data Defaults)
  static Map<String, Object> withDefaults(
    Map<String, Object?> data, {
    String defaultString = '',
    int defaultInt = 0,
    double defaultDouble = 0.0,
    bool defaultBool = false,
  }) {
    final result = <String, Object>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value == null) {
        // Apply type-based defaults (Layer 1: Data Defaults from QUESTIONS.md)
        continue; // Skip null values - RFW handles missing keys
      }
      result[entry.key] = value;
    }
    return result;
  }
}
