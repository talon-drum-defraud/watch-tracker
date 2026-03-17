import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/watch_provider.dart';
import '../services/time_service.dart';
import '../services/prefs_service.dart';

// ── Public button ─────────────────────────────────────────────────────────────

class RecordReadingButton extends StatelessWidget {
  final String watchId;
  const RecordReadingButton({super.key, required this.watchId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Tap, then set what your watch shows',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.icon(
            onPressed: () => _onTap(context),
            icon: const Icon(Icons.fiber_manual_record, size: 18),
            label: const Text(
              'Record Reading',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onTap(BuildContext context) async {
    // Capture reference time instantly on tap
    HapticFeedback.heavyImpact();
    final tapTime = DateTime.now().toUtc(); // immediate device time as seed

    // Open dialog immediately — NTP fetch happens in background inside dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _RecordDialog(
          watchId: watchId,
          tapTime: tapTime,
        ),
      );
    }
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _RecordDialog extends StatefulWidget {
  final String watchId;
  final DateTime tapTime; // device time at tap — seed while NTP loads

  const _RecordDialog({required this.watchId, required this.tapTime});

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  // Reference NTP time (upgrades from device seed when ready)
  DateTime? _ntpTime;
  bool _ntpLoading = true;
  bool _ntpFallback = false;
  String _ntpSource = '';

  // Watch time inputs — seeded from device tap time, user adjusts
  late int _wHours;
  late int _wMinutes;
  late int _wSeconds;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from device tap time immediately
    final local = widget.tapTime.toLocal();
    _wHours = local.hour;
    _wMinutes = local.minute;
    _wSeconds = local.second;

    // Fetch NTP in background — upgrade when ready
    _fetchNtp();
  }

  Future<void> _fetchNtp() async {
    try {
      final preferred = await PrefsService.instance.getPreferredNtpServer();
      final result =
          await TimeService.getAccurateTime(preferredServer: preferred);
      if (!mounted) return;
      final local = result.time.toLocal();
      setState(() {
        _ntpTime = result.time;
        _ntpLoading = false;
        _ntpFallback = result.isFallback;
        _ntpSource = result.source;
        // Also upgrade the pre-fill to NTP time
        _wHours = local.hour;
        _wMinutes = local.minute;
        _wSeconds = local.second;
      });
      HapticFeedback.lightImpact();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ntpTime = widget.tapTime;
        _ntpLoading = false;
        _ntpFallback = true;
        _ntpSource = 'Device clock (offline)';
      });
    }
  }

  // Hint: last reading offset added to NTP seconds as suggested starting point
  int get _lastOffsetHint {
    final provider = context.read<WatchProvider>();
    final last = provider.latestReadingFor(widget.watchId);
    if (last == null) return 0;
    return last.offsetSeconds.round().clamp(-59, 59);
  }

  DateTime get _referenceTime => _ntpTime ?? widget.tapTime;

  DateTime get _watchTime {
    final ref = _referenceTime.toLocal();
    return DateTime(ref.year, ref.month, ref.day,
        _wHours, _wMinutes, _wSeconds).toUtc();
  }

  double get _liveOffset =>
      _watchTime.difference(_referenceTime).inMilliseconds / 1000.0;

  Color _offsetColor(double offset) {
    final abs = offset.abs();
    if (abs <= 2) return const Color(0xFFAAAAAA);
    if (offset > 0) return const Color(0xFFFF9500);
    return const Color(0xFF30D158);
  }

  String _formatOffset(double s) {
    final abs = s.abs();
    final sign = s >= 0 ? '+' : '-';
    if (abs < 60) return '${sign}${abs.toStringAsFixed(1)}s';
    final m = (abs / 60).floor();
    final sec = (abs % 60).toStringAsFixed(0);
    return '${sign}${m}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final refFmt = DateFormat('HH:mm:ss');
    final offset = _liveOffset;
    final offsetColor = _offsetColor(offset);

    return AlertDialog(
      title: const Text('Record Reading'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Reference time banner ─────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _ntpFallback ? Icons.wifi_off : Icons.gps_fixed,
                    size: 14,
                    color: _ntpFallback ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ntpLoading
                        ? Row(children: [
                            const SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text('Fetching NTP time…',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontSize: 12)),
                          ])
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reference: ${refFmt.format(_referenceTime.toLocal())}',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(_ntpSource,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontSize: 11)),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Watch time label ──────────────────────────────────
            Text(
              'What does your watch show?',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust to match your watch display exactly',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),

            // ── HH : MM : SS spinners ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Spinner(
                  label: 'HH',
                  value: _wHours,
                  min: 0, max: 23,
                  onChanged: (v) => setState(() => _wHours = v),
                ),
                _Colon(),
                _Spinner(
                  label: 'MM',
                  value: _wMinutes,
                  min: 0, max: 59,
                  onChanged: (v) => setState(() => _wMinutes = v),
                ),
                _Colon(),
                _Spinner(
                  label: 'SS',
                  value: _wSeconds,
                  min: 0, max: 59,
                  onChanged: (v) => setState(() => _wSeconds = v),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── ±1s nudge row ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Fine-tune seconds: ',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                _NudgeButton(
                  label: '−1s',
                  onTap: () => setState(() {
                    _wSeconds = (_wSeconds - 1 + 60) % 60;
                    if (_wSeconds == 59) {
                      _wMinutes = (_wMinutes - 1 + 60) % 60;
                    }
                  }),
                ),
                const SizedBox(width: 8),
                _NudgeButton(
                  label: '+1s',
                  onTap: () => setState(() {
                    _wSeconds = (_wSeconds + 1) % 60;
                    if (_wSeconds == 0) {
                      _wMinutes = (_wMinutes + 1) % 60;
                    }
                  }),
                ),
              ],
            ),

            // ── Last reading hint ─────────────────────────────────
            if (!_ntpLoading) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  final hint = _lastOffsetHint;
                  if (hint == 0) return;
                  final ref = _referenceTime.toLocal();
                  final suggested = DateTime(
                    ref.year, ref.month, ref.day,
                    ref.hour, ref.minute,
                    (ref.second + hint).clamp(0, 59),
                  );
                  setState(() {
                    _wHours = suggested.hour;
                    _wMinutes = suggested.minute;
                    _wSeconds = suggested.second;
                  });
                  HapticFeedback.selectionClick();
                },
                child: _lastOffsetHint != 0
                    ? Text(
                        'Hint: last reading was ${_formatOffset(_lastOffsetHint.toDouble())} — tap to pre-apply',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.primary.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      )
                    : const SizedBox.shrink(),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ── Live offset preview ───────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calculated offset',
                        style: theme.textTheme.bodyMedium),
                    Text(
                      offset > 0
                          ? 'Watch is running FAST'
                          : offset < 0
                              ? 'Watch is running SLOW'
                              : 'Watch is spot on',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11, color: offsetColor),
                    ),
                  ],
                ),
                Text(
                  _formatOffset(offset),
                  style: theme.textTheme.displaySmall?.copyWith(
                      color: offsetColor, fontSize: 32),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final provider = context.read<WatchProvider>();
    final result = await provider.recordReadingWithTimes(
      widget.watchId,
      watchTime: _watchTime,
      ntpTime: _referenceTime,
      source: _ntpSource,
    );

    if (mounted) {
      Navigator.pop(context);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ntpFallback
                ? '⚠️ Saved with device clock — may be inaccurate'
                : 'Saved ${_formatOffset(result.reading.offsetSeconds)}  •  ${_ntpSource}',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// ── Spinner widget ────────────────────────────────────────────────────────────

class _Spinner extends StatelessWidget {
  final String label;
  final int value;
  final int min, max;
  final ValueChanged<int> onChanged;

  const _Spinner({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 10, letterSpacing: 1.2,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
        const SizedBox(height: 4),
        Container(
          width: 62,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _ArrowBtn(
                icon: Icons.keyboard_arrow_up,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value >= max ? min : value + 1);
                },
              ),
              GestureDetector(
                onTap: () => _editDirectly(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontSize: 30, fontWeight: FontWeight.w200),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _ArrowBtn(
                icon: Icons.keyboard_arrow_down,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(value <= min ? max : value - 1);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editDirectly(BuildContext context) async {
    final ctrl =
        TextEditingController(text: value.toString().padLeft(2, '0'));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Enter $label'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28),
          decoration: InputDecoration(hintText: '$min–$max'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v >= min && v <= max) onChanged(v);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ),
      );
}

class _Colon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
        child: Text(':',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(fontSize: 28, fontWeight: FontWeight.w200)),
      );
}

class _NudgeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NudgeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
      );
}
