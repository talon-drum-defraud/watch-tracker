import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/watch.dart';
import '../models/time_reading.dart';

class WatchCard extends StatelessWidget {
  final Watch watch;
  final TimeReading? latestReading;
  final VoidCallback onTap;

  const WatchCard({
    super.key,
    required this.watch,
    required this.latestReading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = latestReading;

    // Status dot colour
    Color statusColor;
    String offsetText;
    if (r == null) {
      statusColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      offsetText = 'No readings yet';
    } else {
      final abs = r.offsetSeconds.abs();
      if (abs <= 2) {
        statusColor = const Color(0xFF30D158); // excellent
      } else if (abs <= 10) {
        statusColor = const Color(0xFFFF9500); // acceptable
      } else {
        statusColor = Colors.red.shade400;     // needs attention
      }
      offsetText = r.offsetFormatted;
    }

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            // Status dot
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: r != null
                    ? [BoxShadow(
                        color: statusColor.withOpacity(0.5),
                        blurRadius: 6, spreadRadius: 1)]
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Watch info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(watch.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${watch.brand}${watch.movement.isNotEmpty ? " · ${watch.movement}" : ""}',
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  if (r != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Last check: ${DateFormat("dd MMM, HH:mm").format(r.recordedAt.toLocal())}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            // Offset + drift
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(offsetText,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: r == null ? Theme.of(context).colorScheme.onSurface.withOpacity(0.2) : statusColor,
                      fontWeight: FontWeight.w300,
                    )),
                if (r?.driftRatePerDay != null)
                  Text(r!.driftFormatted,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                size: 20),
          ]),
        ),
      ),
    );
  }
}
