import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'time_service.dart';

class PrefsService {
  static final PrefsService instance = PrefsService._();
  PrefsService._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'prefs.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE prefs (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> setString(String key, String value) async {
    final db = await database;
    await db.insert('prefs', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getString(String key) async {
    final db = await database;
    final rows = await db.query('prefs', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  // ── NTP server ────────────────────────────────────────────────────────────

  Future<NtpServer> getPreferredNtpServer() async {
    final host = await getString('ntp_server');
    if (host == null) return TimeService.defaultServer;
    return TimeService.availableServers.firstWhere(
      (s) => s.host == host,
      orElse: () => TimeService.defaultServer,
    );
  }

  Future<void> setPreferredNtpServer(NtpServer server) async =>
      setString('ntp_server', server.host);

  // ── Theme ─────────────────────────────────────────────────────────────────
  // Values: 'system' | 'light' | 'dark'

  Future<String> getThemeMode() async =>
      (await getString('theme_mode')) ?? 'system';

  Future<void> setThemeMode(String mode) async =>
      setString('theme_mode', mode);
}
