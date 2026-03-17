class TimeReading {
  final String id;
  final String watchId;
  final String? seriesId;
  final DateTime recordedAt;
  final double offsetSeconds;
  final double? driftRatePerDay;
  final String? source;

  TimeReading({
    required this.id,
    required this.watchId,
    this.seriesId,
    required this.recordedAt,
    required this.offsetSeconds,
    this.driftRatePerDay,
    this.source,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'watch_id': watchId,
    'series_id': seriesId,
    'recorded_at': recordedAt.toIso8601String(),
    'offset_seconds': offsetSeconds,
    'drift_rate_per_day': driftRatePerDay,
    'source': source,
  };

  factory TimeReading.fromMap(Map<String, dynamic> map) => TimeReading(
    id: map['id'],
    watchId: map['watch_id'],
    seriesId: map['series_id'],
    recordedAt: DateTime.parse(map['recorded_at']),
    offsetSeconds: (map['offset_seconds'] as num).toDouble(),
    driftRatePerDay: map['drift_rate_per_day'] != null
        ? (map['drift_rate_per_day'] as num).toDouble() : null,
    source: map['source'],
  );

  String get offsetFormatted {
    final abs = offsetSeconds.abs();
    final sign = offsetSeconds >= 0 ? '+' : '-';
    if (abs < 60) return '${sign}${abs.toStringAsFixed(1)}s';
    final mins = (abs / 60).floor();
    final secs = (abs % 60).toStringAsFixed(0);
    return '${sign}${mins}m ${secs}s';
  }

  String get driftFormatted {
    if (driftRatePerDay == null) return 'N/A';
    final sign = driftRatePerDay! >= 0 ? '+' : '';
    return '${sign}${driftRatePerDay!.toStringAsFixed(2)} s/day';
  }
}
