import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/watch.dart';
import '../models/time_reading.dart';
import '../models/series.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/time_service.dart';
import '../services/prefs_service.dart';

class WatchProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<Watch> _watches = [];
  Map<String, List<TimeReading>> _allReadings = {};
  Map<String, List<Series>> _allSeries = {};
  Map<String, Series?> _currentSeries = {};

  bool _loading = false;
  String? _error;

  List<Watch> get watches => _watches;
  bool get loading => _loading;
  String? get error => _error;

  // All readings for a watch (all series)
  List<TimeReading> allReadingsFor(String watchId) =>
      _allReadings[watchId] ?? [];

  // Readings for current series only
  List<TimeReading> readingsFor(String watchId) {
    final current = _currentSeries[watchId];
    if (current == null) return allReadingsFor(watchId);
    return allReadingsFor(watchId)
        .where((r) => r.seriesId == current.id)
        .toList();
  }

  List<Series> seriesFor(String watchId) => _allSeries[watchId] ?? [];

  Series? currentSeriesFor(String watchId) => _currentSeries[watchId];

  // Archived series (all except current)
  List<Series> archivedSeriesFor(String watchId) =>
      seriesFor(watchId).where((s) => s.endedAt != null).toList();

  TimeReading? latestReadingFor(String watchId) {
    final list = readingsFor(watchId);
    if (list.isEmpty) return null;
    return list.last;
  }

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _watches = await _db.getAllWatches();
      _allReadings = {};
      _allSeries = {};
      _currentSeries = {};
      for (final w in _watches) {
        _allReadings[w.id] = await _db.getReadingsForWatch(w.id);
        _allSeries[w.id] = await _db.getSeriesForWatch(w.id);
        _currentSeries[w.id] = await _db.getCurrentSeries(w.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<Watch> addWatch({
    required String name,
    required String brand,
    required String movement,
  }) async {
    final watch = Watch(
      id: _uuid.v4(),
      name: name,
      brand: brand,
      movement: movement,
      createdAt: DateTime.now(),
    );
    await _db.insertWatch(watch);
    _watches.add(watch);
    _allReadings[watch.id] = [];
    _allSeries[watch.id] = [];

    // Create initial series automatically
    final series = await _createSeries(watch.id, label: 'Series 1');
    _currentSeries[watch.id] = series;

    notifyListeners();
    return watch;
  }

  Future<Series> _createSeries(String watchId,
      {required String label, String? note}) async {
    final series = Series(
      id: _uuid.v4(),
      watchId: watchId,
      label: label,
      startedAt: DateTime.now(),
      note: note,
    );
    await _db.insertSeries(series);
    _allSeries[watchId] = (_allSeries[watchId] ?? [])..add(series);
    return series;
  }

  /// Starts a new series for a watch.
  /// Closes the current series first, then creates a fresh one.
  Future<Series> startNewSeries(String watchId,
      {String? label, String? note}) async {
    // Close current series
    final current = _currentSeries[watchId];
    if (current != null) {
      final closed = Series(
        id: current.id,
        watchId: current.watchId,
        label: current.label,
        startedAt: current.startedAt,
        endedAt: DateTime.now(),
        note: current.note,
      );
      await _db.updateSeries(closed);
      final idx = (_allSeries[watchId] ?? [])
          .indexWhere((s) => s.id == current.id);
      if (idx != -1) _allSeries[watchId]![idx] = closed;
    }

    // Determine label for new series
    final seriesCount = (_allSeries[watchId] ?? []).length + 1;
    final newLabel = label ?? 'Series $seriesCount';
    final newSeries = await _createSeries(watchId, label: newLabel, note: note);
    _currentSeries[watchId] = newSeries;

    notifyListeners();
    return newSeries;
  }

  /// Returns all readings for a specific archived series
  List<TimeReading> readingsForSeries(String seriesId) {
    final all = _allReadings.values.expand((list) => list);
    return all.where((r) => r.seriesId == seriesId).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  Future<void> updateWatch(Watch updated) async {
    await _db.updateWatch(updated);
    final idx = _watches.indexWhere((w) => w.id == updated.id);
    if (idx != -1) _watches[idx] = updated;
    await _syncNotification(updated);
    notifyListeners();
  }

  Future<void> deleteWatch(String id) async {
    await _db.deleteWatch(id);
    _watches.removeWhere((w) => w.id == id);
    _allReadings.remove(id);
    _allSeries.remove(id);
    _currentSeries.remove(id);
    await NotificationService.instance.cancelWatchReminder(id);
    notifyListeners();
  }

  Future<void> _syncNotification(Watch watch) async {
    if (watch.notificationsEnabled && watch.notificationIntervalHours > 0) {
      await NotificationService.instance.scheduleWatchReminder(
        watchId: watch.id,
        watchName: watch.name,
        intervalHours: watch.notificationIntervalHours,
      );
    } else {
      await NotificationService.instance.cancelWatchReminder(watch.id);
    }
  }

  Future<({TimeReading reading, bool isFallback})> recordReadingWithTimes(
    String watchId, {
    required DateTime watchTime,
    required DateTime ntpTime,
    String? source,
  }) async {
    final offsetSeconds =
        watchTime.difference(ntpTime).inMilliseconds / 1000.0;

    final prev = latestReadingFor(watchId);
    double? drift;
    if (prev != null) {
      drift = TimeService.computeDriftRate(
        prev.offsetSeconds, prev.recordedAt,
        offsetSeconds, ntpTime,
      );
    }

    // Get or create current series
    var current = _currentSeries[watchId];
    if (current == null) {
      current = await _createSeries(watchId, label: 'Series 1');
      _currentSeries[watchId] = current;
    }

    final reading = TimeReading(
      id: _uuid.v4(),
      watchId: watchId,
      seriesId: current.id,
      recordedAt: ntpTime,
      offsetSeconds: offsetSeconds,
      driftRatePerDay: drift,
      source: source,
    );

    await _db.insertReading(reading);
    _allReadings[watchId] = (_allReadings[watchId] ?? [])..add(reading);

    final watch = _watches.firstWhere((w) => w.id == watchId);
    await _syncNotification(watch);

    notifyListeners();
    return (
      reading: reading,
      isFallback: source?.contains('offline') ?? false,
    );
  }

  Future<void> deleteReading(String watchId, String readingId) async {
    await _db.deleteReading(readingId);
    _allReadings[watchId]?.removeWhere((r) => r.id == readingId);
    notifyListeners();
  }

  Future<void> markWound(String watchId) async {
    final idx = _watches.indexWhere((w) => w.id == watchId);
    if (idx == -1) return;
    await updateWatch(_watches[idx].copyWith(lastWoundAt: DateTime.now()));
  }

  Future<void> markSet(String watchId) async {
    final idx = _watches.indexWhere((w) => w.id == watchId);
    if (idx == -1) return;
    await updateWatch(_watches[idx].copyWith(lastSetAt: DateTime.now()));
  }
}
