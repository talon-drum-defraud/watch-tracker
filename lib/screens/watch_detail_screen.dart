import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/watch_provider.dart';
import '../models/watch.dart';
import '../models/time_reading.dart';
import '../models/series.dart';
import '../widgets/record_reading_button.dart';
import '../widgets/stats_tab.dart';
import 'add_watch_screen.dart';
import 'series_archive_screen.dart';

class WatchDetailScreen extends StatefulWidget {
  final String watchId;
  const WatchDetailScreen({super.key, required this.watchId});

  @override
  State<WatchDetailScreen> createState() => _WatchDetailScreenState();
}

class _WatchDetailScreenState extends State<WatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WatchProvider>(
      builder: (context, provider, _) {
        final idx = provider.watches.indexWhere((w) => w.id == widget.watchId);
        if (idx == -1) {
          return const Scaffold(body: Center(child: Text('Watch not found')));
        }
        final watch = provider.watches[idx];
        final readings = provider.readingsFor(widget.watchId);
        final latest = readings.isNotEmpty ? readings.last : null;
        final currentSeries = provider.currentSeriesFor(widget.watchId);
        final archived = provider.archivedSeriesFor(widget.watchId);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(watch.name,
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${watch.brand}${watch.movement.isNotEmpty ? " · ${watch.movement}" : ""}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddWatchScreen(editWatchId: widget.watchId),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, provider, watch),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'History'),
                Tab(text: 'Stats'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _HistoryTab(
                watch: watch,
                readings: readings,
                latest: latest,
                provider: provider,
                watchId: widget.watchId,
                currentSeries: currentSeries,
                archivedSeries: archived,
              ),
              StatsTab(readings: readings),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WatchProvider provider, Watch watch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${watch.name}?'),
        content: const Text(
            'This will permanently delete the watch and all its readings.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteWatch(watch.id);
      Navigator.pop(context);
    }
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final Watch watch;
  final List<TimeReading> readings;
  final TimeReading? latest;
  final WatchProvider provider;
  final String watchId;
  final Series? currentSeries;
  final List<Series> archivedSeries;

  const _HistoryTab({
    required this.watch,
    required this.readings,
    required this.latest,
    required this.provider,
    required this.watchId,
    required this.currentSeries,
    required this.archivedSeries,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SeriesBanner(
          watchId: watchId,
          watchName: watch.name,
          provider: provider,
          currentSeries: currentSeries,
          archivedSeries: archivedSeries,
          readingCount: readings.length,
        ),
        const SizedBox(height: 16),
        _MetaCard(watch: watch, provider: provider),
        const SizedBox(height: 16),
        if (latest != null) ...[
          _OffsetBanner(latest: latest!),
          const SizedBox(height: 16),
        ],
        RecordReadingButton(watchId: watchId),
        const SizedBox(height: 24),
        if (readings.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reading history',
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${readings.length} reading${readings.length == 1 ? "" : "s"}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...readings.reversed.map((r) => _ReadingTile(
                reading: r,
                onDelete: () => provider.deleteReading(watchId, r.id),
              )),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Column(
                children: [
                  const Text('⏱', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('No readings yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Tap Record Reading to log your first measurement.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Series banner ─────────────────────────────────────────────────────────────

class _SeriesBanner extends StatelessWidget {
  final String watchId;
  final String watchName;
  final WatchProvider provider;
  final Series? currentSeries;
  final List<Series> archivedSeries;
  final int readingCount;

  const _SeriesBanner({
    required this.watchId,
    required this.watchName,
    required this.provider,
    required this.currentSeries,
    required this.archivedSeries,
    required this.readingCount,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentSeries != null
                        ? currentSeries!.label
                        : 'No active series',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                if (archivedSeries.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeriesArchiveScreen(
                          watchName: watchName,
                          archivedSeries: archivedSeries,
                          provider: provider,
                        ),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '${archivedSeries.length} archived',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                  ),
              ],
            ),
            if (currentSeries != null) ...[
              const SizedBox(height: 4),
              Text(
                'Started ${fmt.format(currentSeries!.startedAt.toLocal())}  ·  '
                '$readingCount reading${readingCount == 1 ? "" : "s"}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmNewSeries(context),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Start New Series'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmNewSeries(BuildContext context) async {
    final labelCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start New Series'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The current series will be archived. All future readings will belong to the new series.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Series name (optional)',
                hintText: 'e.g. After service, Post regulation',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Adjusted +2s/day',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start New Series')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.startNewSeries(
        watchId,
        label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New series started — previous series archived'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Meta card ─────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final Watch watch;
  final WatchProvider provider;
  const _MetaCard({required this.watch, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _InfoRow(
                label: 'Brand',
                value: watch.brand.isEmpty ? '—' : watch.brand),
            _InfoRow(
                label: 'Movement',
                value: watch.movement.isEmpty ? '—' : watch.movement),
            _InfoRow(
              label: 'Last set',
              value: watch.lastSetAt != null
                  ? fmt.format(watch.lastSetAt!.toLocal())
                  : '—',
            ),
            _InfoRow(
              label: 'Last wound',
              value: watch.lastWoundAt != null
                  ? fmt.format(watch.lastWoundAt!.toLocal())
                  : '—',
            ),
            const Divider(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => provider.markSet(watch.id),
                  icon: const Icon(Icons.schedule, size: 16),
                  label: const Text('Mark Set'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => provider.markWound(watch.id),
                  icon: const Icon(Icons.autorenew, size: 16),
                  label: const Text('Mark Wound'),
                ),
              ),
            ]),
            const Divider(height: 24),
            _NotificationRow(watch: watch, provider: provider),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7))),
        ),
      ]),
    );
  }
}

// ── Notification row ──────────────────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  final Watch watch;
  final WatchProvider provider;
  const _NotificationRow({required this.watch, required this.provider});

  static const _intervals = [
    (label: 'Off', hours: 0),
    (label: '12 hours', hours: 12),
    (label: 'Daily', hours: 24),
    (label: '2 days', hours: 48),
    (label: '3 days', hours: 72),
    (label: 'Weekly', hours: 168),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.notifications_outlined,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Reminders',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  watch.notificationIntervalLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final selected =
        await showModalBottomSheet<({bool enabled, int hours})>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Reminder frequency',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ..._intervals.map((opt) => ListTile(
                  title: Text(opt.label),
                  trailing: watch.notificationIntervalLabel == opt.label
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(
                      context, (enabled: opt.hours > 0, hours: opt.hours)),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      await provider.updateWatch(watch.copyWith(
        notificationsEnabled: selected.enabled,
        notificationIntervalHours: selected.hours,
      ));
    }
  }
}

// ── Offset banner ─────────────────────────────────────────────────────────────

class _OffsetBanner extends StatelessWidget {
  final TimeReading latest;
  const _OffsetBanner({required this.latest});

  @override
  Widget build(BuildContext context) {
    final off = latest.offsetSeconds;
    final abs = off.abs();
    final color = abs <= 2
        ? const Color(0xFFAAAAAA)
        : off > 0
            ? const Color(0xFFFF9500)
            : const Color(0xFF30D158);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest offset',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(latest.offsetFormatted,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: color)),
                Text(
                  off > 2
                      ? 'Running FAST'
                      : off < -2
                          ? 'Running SLOW'
                          : 'Excellent accuracy',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (latest.driftRatePerDay != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Drift rate',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(latest.driftFormatted,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
        ]),
      ),
    );
  }
}

// ── Reading tile ──────────────────────────────────────────────────────────────

class _ReadingTile extends StatelessWidget {
  final TimeReading reading;
  final VoidCallback onDelete;
  const _ReadingTile({required this.reading, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final off = reading.offsetSeconds;
    final color = off.abs() <= 2
        ? const Color(0xFFAAAAAA)
        : off > 0
            ? const Color(0xFFFF9500)
            : const Color(0xFF30D158);

    return Dismissible(
      key: Key(reading.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            radius: 20,
            child: Icon(
              off.abs() <= 2
                  ? Icons.check
                  : off > 0
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
              color: color,
              size: 16,
            ),
          ),
          title: Text(reading.offsetFormatted,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color)),
          subtitle: Text(
            '${fmt.format(reading.recordedAt.toLocal())}'
            '${reading.source != null ? "\n${reading.source}" : ""}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 11),
          ),
          isThreeLine: reading.source != null,
          trailing: reading.driftRatePerDay != null
              ? Text(reading.driftFormatted,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12))
              : null,
        ),
      ),
    );
  }
}
