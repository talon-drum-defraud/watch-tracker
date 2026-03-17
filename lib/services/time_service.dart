import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ntp/ntp.dart';

class NtpServer {
  final String host;
  final String label;
  final String region;

  const NtpServer({
    required this.host,
    required this.label,
    required this.region,
  });
}

class ServerBenchmark {
  final NtpServer server;
  final int? latencyMs; // null = unreachable
  final bool reachable;

  const ServerBenchmark({
    required this.server,
    this.latencyMs,
    required this.reachable,
  });

  String get latencyLabel =>
      reachable ? '${latencyMs}ms' : 'Unreachable';
}

class TimeService {
  static const List<NtpServer> availableServers = [
    NtpServer(host: 'ntp.iitb.ac.in',     label: 'IIT Bombay',   region: '🇮🇳 India'),
    NtpServer(host: 'in.pool.ntp.org',     label: 'NTP Pool India', region: '🇮🇳 India'),
    NtpServer(host: 'asia.pool.ntp.org',   label: 'NTP Pool Asia',  region: '🌏 Asia'),
    NtpServer(host: 'time.google.com',     label: 'Google',         region: '🌐 Global'),
    NtpServer(host: 'time.cloudflare.com', label: 'Cloudflare',     region: '🌐 Global'),
    NtpServer(host: 'time.apple.com',      label: 'Apple',          region: '🌐 Global'),
    NtpServer(host: 'time.windows.com',    label: 'Microsoft',      region: '🌐 Global'),
    NtpServer(host: 'time.facebook.com',   label: 'Meta',           region: '🌐 Global'),
    NtpServer(host: 'pool.ntp.org',        label: 'NTP Pool Global', region: '🌐 Global'),
  ];

  static const NtpServer defaultServer = NtpServer(
    host: 'in.pool.ntp.org',
    label: 'NTP Pool India',
    region: '🇮🇳 India',
  );

  static const _httpFallback1 = 'https://worldtimeapi.org/api/timezone/Etc/UTC';
  static const _httpFallback2 = 'http://worldclockapi.com/api/json/utc/now';

  /// Fetches accurate UTC time from the preferred server,
  /// falling back through the chain automatically.
  static Future<({DateTime time, bool isFallback, String source})>
      getAccurateTime({NtpServer? preferredServer}) async {
    final preferred = preferredServer ?? defaultServer;

    // Build attempt list: preferred first, then others (max 3 NTP attempts)
    final attempts = <NtpServer>[preferred];
    for (final s in availableServers) {
      if (s.host != preferred.host) attempts.add(s);
      if (attempts.length == 3) break;
    }

    for (final server in attempts) {
      try {
        final offset = await NTP.getNtpOffset(
          localTime: DateTime.now(),
          lookUpAddress: server.host,
        ).timeout(const Duration(seconds: 4));
        final t = DateTime.now().toUtc().add(Duration(milliseconds: offset));
        return (time: t, isFallback: false, source: '${server.label} (${server.host})');
      } catch (_) { continue; }
    }

    // HTTP fallbacks
    try {
      final r = await http.get(Uri.parse(_httpFallback1))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final dt = DateTime.parse(jsonDecode(r.body)['datetime']).toUtc();
        return (time: dt, isFallback: false, source: 'WorldTimeAPI (HTTP fallback)');
      }
    } catch (_) {}

    try {
      final r = await http.get(Uri.parse(_httpFallback2))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final dt = DateTime.parse(jsonDecode(r.body)['currentDateTime']).toUtc();
        return (time: dt, isFallback: false, source: 'WorldClockAPI (HTTP fallback)');
      }
    } catch (_) {}

    return (
      time: DateTime.now().toUtc(),
      isFallback: true,
      source: 'Device clock (offline)',
    );
  }

  /// Benchmarks all servers simultaneously and returns sorted results.
  static Future<List<ServerBenchmark>> benchmarkAll() async {
    final futures = availableServers.map((server) async {
      final sw = Stopwatch()..start();
      try {
        await NTP.getNtpOffset(
          localTime: DateTime.now(),
          lookUpAddress: server.host,
        ).timeout(const Duration(seconds: 5));
        sw.stop();
        return ServerBenchmark(
          server: server,
          latencyMs: sw.elapsedMilliseconds,
          reachable: true,
        );
      } catch (_) {
        return ServerBenchmark(server: server, reachable: false);
      }
    });

    final results = await Future.wait(futures);
    // Sort: reachable first by latency, unreachable last
    results.sort((a, b) {
      if (a.reachable && b.reachable) {
        return a.latencyMs!.compareTo(b.latencyMs!);
      }
      if (a.reachable) return -1;
      if (b.reachable) return 1;
      return 0;
    });
    return results;
  }

  static double computeOffset(DateTime watchTime, DateTime referenceTime) =>
      watchTime.difference(referenceTime).inMilliseconds / 1000.0;

  static double? computeDriftRate(
    double prevOffset, DateTime prevTime,
    double currOffset, DateTime currTime,
  ) {
    final hours = currTime.difference(prevTime).inMinutes / 60.0;
    if (hours < 1) return null;
    return ((currOffset - prevOffset) / hours) * 24.0;
  }
}
