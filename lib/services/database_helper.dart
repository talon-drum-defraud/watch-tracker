import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/watch.dart';
import '../models/time_reading.dart';
import '../models/series.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('watch_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final path = join(await getDatabasesPath(), fileName);
    return await openDatabase(path,
        version: 3, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE watches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        brand TEXT NOT NULL,
        movement TEXT NOT NULL,
        last_wound_at TEXT,
        last_set_at TEXT,
        created_at TEXT NOT NULL,
        notifications_enabled INTEGER NOT NULL DEFAULT 0,
        notification_interval_hours INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE series (
        id TEXT PRIMARY KEY,
        watch_id TEXT NOT NULL,
        label TEXT NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        note TEXT,
        FOREIGN KEY (watch_id) REFERENCES watches(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE time_readings (
        id TEXT PRIMARY KEY,
        watch_id TEXT NOT NULL,
        series_id TEXT,
        recorded_at TEXT NOT NULL,
        offset_seconds REAL NOT NULL,
        drift_rate_per_day REAL,
        source TEXT,
        FOREIGN KEY (watch_id) REFERENCES watches(id) ON DELETE CASCADE,
        FOREIGN KEY (series_id) REFERENCES series(id) ON DELETE SET NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE watches ADD COLUMN notifications_enabled INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'ALTER TABLE watches ADD COLUMN notification_interval_hours INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS series (
          id TEXT PRIMARY KEY,
          watch_id TEXT NOT NULL,
          label TEXT NOT NULL,
          started_at TEXT NOT NULL,
          ended_at TEXT,
          note TEXT,
          FOREIGN KEY (watch_id) REFERENCES watches(id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
          'ALTER TABLE time_readings ADD COLUMN series_id TEXT');
    }
  }

  // ── Watches ───────────────────────────────────────────────────────────────

  Future<void> insertWatch(Watch w) async {
    final db = await database;
    await db.insert('watches', w.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Watch>> getAllWatches() async {
    final db = await database;
    return (await db.query('watches', orderBy: 'created_at ASC'))
        .map(Watch.fromMap).toList();
  }

  Future<void> updateWatch(Watch w) async {
    final db = await database;
    await db.update('watches', w.toMap(),
        where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteWatch(String id) async {
    final db = await database;
    await db.delete('watches', where: 'id = ?', whereArgs: [id]);
    await db.delete('series', where: 'watch_id = ?', whereArgs: [id]);
    await db.delete('time_readings', where: 'watch_id = ?', whereArgs: [id]);
  }

  // ── Series ────────────────────────────────────────────────────────────────

  Future<void> insertSeries(Series s) async {
    final db = await database;
    await db.insert('series', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSeries(Series s) async {
    final db = await database;
    await db.update('series', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  Future<List<Series>> getSeriesForWatch(String watchId) async {
    final db = await database;
    return (await db.query('series',
        where: 'watch_id = ?', whereArgs: [watchId],
        orderBy: 'started_at ASC'))
        .map(Series.fromMap).toList();
  }

  Future<Series?> getCurrentSeries(String watchId) async {
    final db = await database;
    final maps = await db.query('series',
        where: 'watch_id = ? AND ended_at IS NULL',
        whereArgs: [watchId], limit: 1);
    if (maps.isEmpty) return null;
    return Series.fromMap(maps.first);
  }

  // ── Readings ──────────────────────────────────────────────────────────────

  Future<void> insertReading(TimeReading r) async {
    final db = await database;
    await db.insert('time_readings', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TimeReading>> getReadingsForWatch(String watchId) async {
    final db = await database;
    return (await db.query('time_readings',
        where: 'watch_id = ?', whereArgs: [watchId],
        orderBy: 'recorded_at ASC'))
        .map(TimeReading.fromMap).toList();
  }

  Future<List<TimeReading>> getReadingsForSeries(String seriesId) async {
    final db = await database;
    return (await db.query('time_readings',
        where: 'series_id = ?', whereArgs: [seriesId],
        orderBy: 'recorded_at ASC'))
        .map(TimeReading.fromMap).toList();
  }

  Future<void> deleteReading(String id) async {
    final db = await database;
    await db.delete('time_readings', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async => (await database).close();
}
