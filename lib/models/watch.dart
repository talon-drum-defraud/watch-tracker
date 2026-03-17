class Watch {
  final String id;
  String name;
  String brand;
  String movement;
  DateTime? lastWoundAt;
  DateTime? lastSetAt;
  DateTime createdAt;
  bool notificationsEnabled;
  int notificationIntervalHours; // 0 = disabled

  Watch({
    required this.id,
    required this.name,
    required this.brand,
    required this.movement,
    this.lastWoundAt,
    this.lastSetAt,
    required this.createdAt,
    this.notificationsEnabled = false,
    this.notificationIntervalHours = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'brand': brand,
    'movement': movement,
    'last_wound_at': lastWoundAt?.toIso8601String(),
    'last_set_at': lastSetAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'notifications_enabled': notificationsEnabled ? 1 : 0,
    'notification_interval_hours': notificationIntervalHours,
  };

  factory Watch.fromMap(Map<String, dynamic> map) => Watch(
    id: map['id'],
    name: map['name'],
    brand: map['brand'],
    movement: map['movement'],
    lastWoundAt: map['last_wound_at'] != null
        ? DateTime.parse(map['last_wound_at']) : null,
    lastSetAt: map['last_set_at'] != null
        ? DateTime.parse(map['last_set_at']) : null,
    createdAt: DateTime.parse(map['created_at']),
    notificationsEnabled: (map['notifications_enabled'] ?? 0) == 1,
    notificationIntervalHours: map['notification_interval_hours'] ?? 0,
  );

  Watch copyWith({
    String? name, String? brand, String? movement,
    DateTime? lastWoundAt, DateTime? lastSetAt,
    bool? notificationsEnabled, int? notificationIntervalHours,
  }) => Watch(
    id: id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    movement: movement ?? this.movement,
    lastWoundAt: lastWoundAt ?? this.lastWoundAt,
    lastSetAt: lastSetAt ?? this.lastSetAt,
    createdAt: createdAt,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    notificationIntervalHours:
        notificationIntervalHours ?? this.notificationIntervalHours,
  );

  /// Human-readable interval label
  String get notificationIntervalLabel {
    if (!notificationsEnabled || notificationIntervalHours == 0) return 'Off';
    if (notificationIntervalHours < 24) return 'Every ${notificationIntervalHours}h';
    final days = notificationIntervalHours ~/ 24;
    return days == 1 ? 'Daily' : 'Every $days days';
  }
}
