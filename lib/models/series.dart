class Series {
  final String id;
  final String watchId;
  final String label;
  final DateTime startedAt;
  final DateTime? endedAt; // null = current series
  final String? note;

  Series({
    required this.id,
    required this.watchId,
    required this.label,
    required this.startedAt,
    this.endedAt,
    this.note,
  });

  bool get isCurrent => endedAt == null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'watch_id': watchId,
    'label': label,
    'started_at': startedAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'note': note,
  };

  factory Series.fromMap(Map<String, dynamic> map) => Series(
    id: map['id'],
    watchId: map['watch_id'],
    label: map['label'],
    startedAt: DateTime.parse(map['started_at']),
    endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at']) : null,
    note: map['note'],
  );
}
