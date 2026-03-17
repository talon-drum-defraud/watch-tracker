import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/prefs_service.dart';
import '../services/time_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  NtpServer? _selected;
  bool _loading = true;
  bool _benchmarking = false;
  List<ServerBenchmark>? _benchmarkResults;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final server = await PrefsService.instance.getPreferredNtpServer();
    setState(() { _selected = server; _loading = false; });
  }

  Future<void> _selectServer(NtpServer server) async {
    await PrefsService.instance.setPreferredNtpServer(server);
    setState(() => _selected = server);
  }

  Future<void> _runBenchmark() async {
    setState(() { _benchmarking = true; _benchmarkResults = null; });
    final results = await TimeService.benchmarkAll();
    if (!mounted) return;
    setState(() { _benchmarkResults = results; _benchmarking = false; });
    // Auto-select fastest reachable server
    final fastest = results.firstWhere(
      (r) => r.reachable,
      orElse: () => results.first,
    );
    if (fastest.reachable) await _selectServer(fastest.server);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Appearance ────────────────────────────────────
                _SectionHeader('Appearance'),
                _ThemePicker(),
                const SizedBox(height: 24),

                // ── NTP Server ────────────────────────────────────
                _SectionHeader('Time Source'),
                Text(
                  'The app queries this server when recording a reading. '
                  'Run the speed test to automatically select the fastest server for your location.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Speed test button
                FilledButton.icon(
                  onPressed: _benchmarking ? null : _runBenchmark,
                  icon: _benchmarking
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.speed, size: 18),
                  label: Text(_benchmarking
                      ? 'Testing all servers…'
                      : 'Run Speed Test'),
                ),
                const SizedBox(height: 12),

                // Server list
                Card(
                  child: Column(
                    children: (_benchmarkResults != null
                        ? _benchmarkResults!.map((b) => b.server)
                        : TimeService.availableServers
                    ).map((server) {
                      final benchmark = _benchmarkResults?.firstWhere(
                        (b) => b.server.host == server.host,
                        orElse: () => ServerBenchmark(
                            server: server, reachable: false),
                      );
                      return _ServerTile(
                        server: server,
                        isSelected: _selected?.host == server.host,
                        benchmark: benchmark,
                        onTap: () => _selectServer(server),
                      );
                    }).toList(),
                  ),
                ),

                if (_benchmarkResults != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '✓ Speed test complete — fastest server selected automatically',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade400, fontSize: 12),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Info ──────────────────────────────────────────
                _SectionHeader('About NTP accuracy'),
                Text(
                  'NTP (Network Time Protocol) accounts for network '
                  'round-trip delay, giving ±10–50ms accuracy — far better '
                  'than HTTP-based time APIs. If NTP is blocked on your '
                  'network, the app falls back to HTTP sources automatically.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

// ── Theme picker ──────────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    return Card(
      child: Column(
        children: [
          _ThemeTile(
            label: 'System default',
            subtitle: 'Follows your device setting',
            icon: Icons.brightness_auto_outlined,
            selected: provider.mode == ThemeMode.system,
            onTap: () => provider.setMode(ThemeMode.system),
          ),
          const Divider(height: 1, indent: 56),
          _ThemeTile(
            label: 'Light',
            subtitle: 'Always light appearance',
            icon: Icons.light_mode_outlined,
            selected: provider.mode == ThemeMode.light,
            onTap: () => provider.setMode(ThemeMode.light),
          ),
          const Divider(height: 1, indent: 56),
          _ThemeTile(
            label: 'Dark',
            subtitle: 'Always dark appearance',
            icon: Icons.dark_mode_outlined,
            selected: provider.mode == ThemeMode.dark,
            onTap: () => provider.setMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label, required this.subtitle,
    required this.icon, required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(icon, color: selected ? primary : null),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: selected ? primary : null)),
      subtitle: Text(subtitle),
      trailing: selected
          ? Icon(Icons.check_circle, color: primary, size: 20)
          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

// ── Server tile ───────────────────────────────────────────────────────────────

class _ServerTile extends StatelessWidget {
  final NtpServer server;
  final bool isSelected;
  final ServerBenchmark? benchmark;
  final VoidCallback onTap;

  const _ServerTile({
    required this.server, required this.isSelected,
    this.benchmark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasBenchmark = benchmark != null;
    final reachable = benchmark?.reachable ?? true;
    final latency = benchmark?.latencyMs;

    Color latencyColor = Colors.grey;
    if (hasBenchmark && reachable && latency != null) {
      if (latency < 100) latencyColor = const Color(0xFF30D158);
      else if (latency < 250) latencyColor = const Color(0xFFFF9500);
      else latencyColor = Colors.red.shade400;
    }

    return ListTile(
      title: Text(
        '${server.region}  ${server.label}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isSelected ? primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      subtitle: Text(server.host,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontSize: 11, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasBenchmark)
            Text(
              reachable ? '${latency}ms' : 'Unreachable',
              style: TextStyle(
                  color: latencyColor, fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          const SizedBox(width: 8),
          isSelected
              ? Icon(Icons.check_circle, color: primary, size: 20)
              : const Icon(Icons.circle_outlined,
                  color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
}
