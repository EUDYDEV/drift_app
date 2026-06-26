class AdminDashboardLayout {
  final String title;
  final String role;
  final Set<String> permissions;
  final List<AdminDashboardTab> tabs;

  const AdminDashboardLayout({
    required this.title,
    required this.role,
    required this.permissions,
    required this.tabs,
  });

  factory AdminDashboardLayout.fromJson(Map<String, dynamic> json) {
    final layout = _readObject(json['layout']);
    final tabs = _readList(layout['tabs'])
        .map((item) => AdminDashboardTab.fromJson(_readObject(item)))
        .where((tab) => tab.key.isNotEmpty)
        .toList(growable: false);

    return AdminDashboardLayout(
      title: (layout['title'] ?? 'Centre IT Drift').toString(),
      role: (json['role'] ?? '').toString(),
      permissions:
          _readList(json['permissions']).map((item) => item.toString()).toSet(),
      tabs: tabs,
    );
  }

  bool canAccess(AdminDashboardTab tab) {
    return role == 'SUPER_ADMIN' ||
        tab.permission.isEmpty ||
        permissions.contains(tab.permission);
  }
}

class AdminDashboardTab {
  final String key;
  final String label;
  final String icon;
  final String permission;
  final List<String> components;

  const AdminDashboardTab({
    required this.key,
    required this.label,
    required this.icon,
    required this.permission,
    required this.components,
  });

  factory AdminDashboardTab.fromJson(Map<String, dynamic> json) {
    return AdminDashboardTab(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
      permission: (json['permission'] ?? '').toString(),
      components: _readList(json['components'])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class AdminSummary {
  final int users;
  final int partners;
  final int prestations;
  final int openSecurityEvents;
  final int openCrashes;
  final int featureFlagsEnabled;
  final int maintenanceEnabled;
  final double grossRevenue;
  final double itExpenses;

  const AdminSummary({
    required this.users,
    required this.partners,
    required this.prestations,
    required this.openSecurityEvents,
    required this.openCrashes,
    required this.featureFlagsEnabled,
    required this.maintenanceEnabled,
    required this.grossRevenue,
    required this.itExpenses,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    return AdminSummary(
      users: _readInt(json['users']),
      partners: _readInt(json['partners']),
      prestations: _readInt(json['prestations']),
      openSecurityEvents: _readInt(json['openSecurityEvents']),
      openCrashes: _readInt(json['openCrashes']),
      featureFlagsEnabled: _readInt(json['featureFlagsEnabled']),
      maintenanceEnabled: _readInt(json['maintenanceEnabled']),
      grossRevenue: _readDouble(json['grossRevenue']),
      itExpenses: _readDouble(json['itExpenses']),
    );
  }
}

class AdminFinanceOverview {
  final double grossRevenue;
  final double eprojectCommission;
  final double partnerPayouts;
  final double itExpenses;
  final double netEstimated;

  const AdminFinanceOverview({
    required this.grossRevenue,
    required this.eprojectCommission,
    required this.partnerPayouts,
    required this.itExpenses,
    required this.netEstimated,
  });

  factory AdminFinanceOverview.fromJson(Map<String, dynamic> json) {
    return AdminFinanceOverview(
      grossRevenue: _readDouble(json['grossRevenue']),
      eprojectCommission: _readDouble(json['eprojectCommission']),
      partnerPayouts: _readDouble(json['partnerPayouts']),
      itExpenses: _readDouble(json['itExpenses']),
      netEstimated: _readDouble(json['netEstimated']),
    );
  }
}

class AdminFeatureFlag {
  final String flagKey;
  final String label;
  final String description;
  final bool enabled;
  final int rolloutPercentage;
  final Map<String, dynamic> audience;

  const AdminFeatureFlag({
    required this.flagKey,
    required this.label,
    required this.description,
    required this.enabled,
    required this.rolloutPercentage,
    required this.audience,
  });

  factory AdminFeatureFlag.fromJson(Map<String, dynamic> json) {
    return AdminFeatureFlag(
      flagKey: (json['flag_key'] ?? json['flagKey'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      enabled: json['enabled'] as bool? ?? false,
      rolloutPercentage: _readInt(
        json['rollout_percentage'] ?? json['rolloutPercentage'],
      ),
      audience: _readObject(json['audience']),
    );
  }
}

class AdminMaintenanceMode {
  final String id;
  final String scopeType;
  final String? scopeValue;
  final bool enabled;
  final String message;

  const AdminMaintenanceMode({
    required this.id,
    required this.scopeType,
    required this.scopeValue,
    required this.enabled,
    required this.message,
  });

  factory AdminMaintenanceMode.fromJson(Map<String, dynamic> json) {
    return AdminMaintenanceMode(
      id: (json['id'] ?? '').toString(),
      scopeType:
          (json['scope_type'] ?? json['scopeType'] ?? 'global').toString(),
      scopeValue: (json['scope_value'] ?? json['scopeValue'])?.toString(),
      enabled: json['enabled'] as bool? ?? false,
      message: (json['message'] ?? '').toString(),
    );
  }
}

int _readInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? 0;
  return 0;
}

double _readDouble(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? 0;
  return 0;
}

List<dynamic> _readList(dynamic raw) {
  return raw is List ? raw : const <dynamic>[];
}

Map<String, dynamic> _readObject(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}
