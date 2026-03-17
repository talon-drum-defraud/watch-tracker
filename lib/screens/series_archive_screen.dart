import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/series.dart';
import '../models/time_reading.dart';
import '../providers/watch_provider.dart';
import '../widgets/stats_tab.dart';

class SeriesArchiveScreen extends StatelessWidget {
  final String watchName;
  final List<Series> archivedSeries;
  final WatchProvider provider;

  const SeriesArchiveScreen({
    super.key,
    required this.watchName,
    required this.archivedSeries,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Series Archive'),
            Text(watchName,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 12)),
          ],
        ),
      ),
      body: archivedSeries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📂', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text('No archived series yet',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'When you start a new series, the previous one is archived here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: archivedSeries.length,
              itemBuilder: (ctx, i) {
                // Show most recent first
                final series =
                    archivedSeries.reversed.toList()[i];
                return _SeriesCard(
                  series: series,
                  provider: provider,
                );
              },
            ),
    );
  }
}

class _SeriesCard extends StatefulWidget {
  final Series series;
  final WatchProvider provider;
  const _SeriesCard({required this.series, required this.provider});

  @override
  State<_SeriesCard> createState() => _SeriesCardState();
}

class _SeriesCardState extends State<_SeriesCard> {
  List<TimeReading>? _readings;
  bool _expanded = false;

  Future<void> _loadReadings() async {
    if (_readings != null) return;
    final r = await widget.provider.readingsForSeries(widget.series.id);
    if (mounted) setState(() => _readings = r);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final s = widget.series;
    final duration = s.endedAt != null
        ? s.endedAt!.difference(s.startedAt).inDays
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(s.label,
                style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(
              '${fmt.format(s.startedAt.toLocal())} → '
              '${s.endedAt != null ? fmt.format(s.endedAt!.toLocal()) : "ongoing"}'
              '${duration != null ? " · $duration days" : ""}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: IconButton(
              icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() => _expanded = !_expanded);
                if (_expanded) _loadReadings();
              },
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (_readings == null)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_readings!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No readings in this series',
                    style: Theme.of(context).textTheme.bodyMedium),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12),
                child: StatsTab(readings: _readings!),
              ),
          ],
        ],
      ),
    );
  }
}
