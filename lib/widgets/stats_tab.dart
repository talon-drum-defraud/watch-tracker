import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/time_reading.dart';

// ── Public stats tab ──────────────────────────────────────────────────────────

class StatsTab extends StatelessWidget {
  final List<TimeReading> readings;
  const StatsTab({super.key, required this.readings});

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return _placeholder(context, 0,
          'No readings yet', 'Record your first reading to start tracking accuracy.');
    }
    if (readings.length < 2) {
      return _placeholder(context, 1,
          '1 reading recorded', 'Add 1 more reading to see your offset trend graph.');
    }

    final avgDrift = _avgDrift();
    final best = _best();
    final worst = _worst();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Summary cards ─────────────────────────────────────────
        _SummaryRow(readings: readings, avgDrift: avgDrift, best: best, worst: worst),
        const SizedBox(height: 24),

        // ── Graph 1: Offset over time ─────────────────────────────
        _ChartSection(
          title: 'Offset over time',
          subtitle: 'How far fast or slow your watch is at each reading',
          child: _OffsetChart(readings: readings),
        ),
        const SizedBox(height: 24),

        // ── Graph 2: Daily drift rate ─────────────────────────────
        if (readings.length >= 3) ...[
          _ChartSection(
            title: 'Daily drift rate',
            subtitle: 'Seconds gained or lost per day between readings',
            child: _DriftRateChart(readings: readings),
          ),
          const SizedBox(height: 24),
        ] else
          _miniPlaceholder(context, 'Daily drift rate',
              '${3 - readings.length} more reading${readings.length == 2 ? "" : "s"} needed'),

        // ── Graph 3: Projection ───────────────────────────────────
        if (readings.length >= 2 && avgDrift != null) ...[
          _ChartSection(
            title: 'Projection',
            subtitle: 'Where your watch will be if drift continues at current rate',
            child: _ProjectionChart(readings: readings, avgDrift: avgDrift),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  double? _avgDrift() {
    final drifts = readings
        .where((r) => r.driftRatePerDay != null)
        .map((r) => r.driftRatePerDay!)
        .toList();
    if (drifts.isEmpty) return null;
    return drifts.reduce((a, b) => a + b) / drifts.length;
  }

  TimeReading _best() => readings.reduce(
      (a, b) => a.offsetSeconds.abs() < b.offsetSeconds.abs() ? a : b);

  TimeReading _worst() => readings.reduce(
      (a, b) => a.offsetSeconds.abs() > b.offsetSeconds.abs() ? a : b);

  Widget _placeholder(BuildContext context, int current, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(sub,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _miniPlaceholder(BuildContext context, String title, String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.lock_clock_outlined, color: const Color(0x40808080), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(msg, style: Theme.of(context).textTheme.bodyMedium),
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<TimeReading> readings;
  final double? avgDrift;
  final TimeReading best, worst;

  const _SummaryRow({
    required this.readings,
    required this.avgDrift,
    required this.best,
    required this.worst,
  });

  String _fmtOffset(double s) {
    final abs = s.abs();
    final sign = s >= 0 ? '+' : '-';
    if (abs < 60) return '${sign}${abs.toStringAsFixed(1)}s';
    return '${sign}${(abs / 60).floor()}m${(abs % 60).toStringAsFixed(0)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          label: 'Readings',
          value: '${readings.length}',
          icon: Icons.history,
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Avg drift',
          value: avgDrift != null
              ? '${avgDrift! >= 0 ? "+" : ""}${avgDrift!.toStringAsFixed(1)}s/d'
              : '—',
          icon: Icons.trending_flat,
          valueColor: avgDrift == null
              ? null
              : avgDrift!.abs() <= 5
                  ? const Color(0xFF30D158)
                  : const Color(0xFFFF9500),
        )),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Best',
          value: _fmtOffset(best.offsetSeconds),
          icon: Icons.star_outline,
          valueColor: const Color(0xFF30D158),
        )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: valueColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Chart section wrapper ─────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  const _ChartSection(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12)),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: child)),
      ],
    );
  }
}

// ── Graph 1: Offset over time ─────────────────────────────────────────────────

class _OffsetChart extends StatelessWidget {
  final List<TimeReading> readings;
  const _OffsetChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.offsetSeconds))
        .toList();

    final offsets = readings.map((r) => r.offsetSeconds).toList();
    final minY = offsets.reduce((a, b) => a < b ? a : b);
    final maxY = offsets.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() * 0.25).clamp(2.0, double.infinity);

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0x1A808080), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: 0, color: const Color(0x40808080),
              strokeWidth: 1, dashArray: [4, 4]),
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 48,
            getTitlesWidget: (v, _) => Text(
              '${v >= 0 ? "+" : ""}${v.toStringAsFixed(0)}s',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            interval: (readings.length / 4).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= readings.length) return const SizedBox.shrink();
              return Text(
                DateFormat('d/M').format(readings[i].recordedAt.toLocal()),
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
              );
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, curveSmoothness: 0.3,
            color: const Color(0xFFB8860B),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                final offset = spot.y;
                final color = offset.abs() <= 2
                    ? const Color(0xFFAAAAAA)
                    : offset > 0
                        ? const Color(0xFFFF9500)
                        : const Color(0xFF30D158);
                return FlDotCirclePainter(
                    radius: 5, color: color,
                    strokeWidth: 2, strokeColor: Colors.black);
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFB8860B).withOpacity(0.07),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final r = readings[s.spotIndex];
              final off = r.offsetSeconds;
              final sign = off >= 0 ? '+' : '';
              return LineTooltipItem(
                '${sign}${off.toStringAsFixed(1)}s\n${DateFormat("dd MMM, HH:mm").format(r.recordedAt.toLocal())}',
                const TextStyle(color: const Color(0xFF1C1C1E), fontSize: 11),
              );
            }).toList(),
          ),
        ),
      )),
    );
  }
}

// ── Graph 2: Daily drift rate ─────────────────────────────────────────────────

class _DriftRateChart extends StatelessWidget {
  final List<TimeReading> readings;
  const _DriftRateChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final driftReadings =
        readings.where((r) => r.driftRatePerDay != null).toList();
    if (driftReadings.isEmpty) return const SizedBox.shrink();

    final spots = driftReadings.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.driftRatePerDay!))
        .toList();

    final drifts = driftReadings.map((r) => r.driftRatePerDay!).toList();
    final minY = drifts.reduce((a, b) => a < b ? a : b);
    final maxY = drifts.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() * 0.25).clamp(1.0, double.infinity);

    return SizedBox(
      height: 180,
      child: LineChart(LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0x1A808080), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: 0, color: const Color(0x40808080),
              strokeWidth: 1, dashArray: [4, 4]),
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 52,
            getTitlesWidget: (v, _) => Text(
              '${v >= 0 ? "+" : ""}${v.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            interval: (driftReadings.length / 4).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= driftReadings.length) return const SizedBox.shrink();
              return Text(
                DateFormat('d/M').format(driftReadings[i].recordedAt.toLocal()),
                style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
              );
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: const Color(0xFF5E9CE6),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4, color: const Color(0xFF5E9CE6),
                  strokeWidth: 2, strokeColor: Colors.black),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF5E9CE6).withOpacity(0.07),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final r = driftReadings[s.spotIndex];
              final d = r.driftRatePerDay!;
              return LineTooltipItem(
                '${d >= 0 ? "+" : ""}${d.toStringAsFixed(2)} s/day\n${DateFormat("dd MMM").format(r.recordedAt.toLocal())}',
                const TextStyle(color: const Color(0xFF1C1C1E), fontSize: 11),
              );
            }).toList(),
          ),
        ),
      )),
    );
  }
}

// ── Graph 3: Projection ───────────────────────────────────────────────────────

class _ProjectionChart extends StatelessWidget {
  final List<TimeReading> readings;
  final double avgDrift;
  const _ProjectionChart(
      {required this.readings, required this.avgDrift});

  @override
  Widget build(BuildContext context) {
    final last = readings.last;
    final lastOffset = last.offsetSeconds;
    final lastDate = last.recordedAt;

    // Historical spots
    final histSpots = readings.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.offsetSeconds))
        .toList();

    // Projection: 7 days forward in 1-day steps
    final projSpots = <FlSpot>[];
    final base = readings.length.toDouble() - 1;
    for (int d = 0; d <= 7; d++) {
      projSpots.add(FlSpot(base + d, lastOffset + avgDrift * d));
    }

    final allY = [
      ...readings.map((r) => r.offsetSeconds),
      ...projSpots.map((s) => s.y),
    ];
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final pad = ((maxY - minY).abs() * 0.2).clamp(2.0, double.infinity);

    // X axis labels: reading dates + projected dates
    final allDates = [
      ...readings.map((r) => r.recordedAt),
      for (int d = 1; d <= 7; d++)
        lastDate.add(Duration(days: d)),
    ];

    return SizedBox(
      height: 200,
      child: LineChart(LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0x1A808080), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(y: 0, color: const Color(0x40808080),
              strokeWidth: 1, dashArray: [4, 4]),
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 48,
            getTitlesWidget: (v, _) => Text(
              '${v >= 0 ? "+" : ""}${v.toStringAsFixed(0)}s',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 24,
            interval: ((allDates.length) / 5).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= allDates.length) return const SizedBox.shrink();
              return Text(
                DateFormat('d/M').format(allDates[i].toLocal()),
                style: TextStyle(
                  fontSize: 10,
                  color: i < readings.length
                      ? const Color(0xFF888888)
                      : const Color(0xFFB8860B).withOpacity(0.7),
                ),
              );
            },
          )),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          // Historical line
          LineChartBarData(
            spots: histSpots,
            isCurved: true, curveSmoothness: 0.3,
            color: const Color(0xFFB8860B),
            barWidth: 2.5,
            dotData: FlDotData(show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4, color: const Color(0xFFB8860B),
                  strokeWidth: 2, strokeColor: Colors.black)),
          ),
          // Projected line (dashed style via gradient opacity)
          LineChartBarData(
            spots: projSpots,
            isCurved: false,
            color: const Color(0xFFB8860B).withOpacity(0.5),
            barWidth: 2,
            dashArray: [6, 4],
            dotData: FlDotData(show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFFB8860B).withOpacity(0.5),
                  strokeWidth: 1, strokeColor: Colors.black)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.spotIndex;
              final isProj = s.barIndex == 1;
              final date = i < allDates.length ? allDates[i] : null;
              return LineTooltipItem(
                '${isProj ? "Projected: " : ""}${s.y >= 0 ? "+" : ""}${s.y.toStringAsFixed(1)}s'
                '${date != null ? "\n${DateFormat("dd MMM").format(date.toLocal())}" : ""}',
                TextStyle(
                    color: isProj ? const Color(0x99808080) : const Color(0xFF1C1C1E),
                    fontSize: 11),
              );
            }).toList(),
          ),
        ),
      )),
    );
  }
}
