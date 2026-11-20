import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../logic/stats.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final HifzColors c = HifzColors.of(context);
    final DateTime now = DateTime.now();
    final Map<String, DayStats> history = app.history;

    DayStats allTime = const DayStats();
    for (final DayStats d in history.values) {
      allTime = allTime + d;
    }
    final DayStats week = sumLastDays(history, now, 7);
    final DayStats today = app.today;

    final List<String> keys = history.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));
    final List<String> recentKeys = keys.take(30).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: <Widget>[
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Performance',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
                      const SizedBox(height: 14),
                      _SummaryRow(label: 'Today', stats: today),
                      const Divider(height: 22),
                      _SummaryRow(label: 'Last 7 days', stats: week),
                      const Divider(height: 22),
                      _SummaryRow(label: 'All time', stats: allTime),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Icon(Icons.local_fire_department_rounded, color: c.gold, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            app.streak == 1
                                ? 'Current streak: 1 day'
                                : 'Current streak: ${app.streak} days',
                            style: TextStyle(color: c.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Ayahs practised, last 7 days',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
                      const SizedBox(height: 16),
                      _WeekChart(history: history, now: now),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('History',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
                      const SizedBox(height: 10),
                      if (recentKeys.isEmpty)
                        Text('No practice recorded yet. Start a session!',
                            style: TextStyle(color: c.textMuted))
                      else
                        for (final String key in recentKeys)
                          _HistoryRow(dateKeyText: key, stats: history[key]!),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (history.isNotEmpty)
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final bool ok = await confirmDialog(
                          context,
                          title: 'Clear all history?',
                          message:
                              'This deletes your saved daily progress on this device. It cannot be undone.',
                          confirmLabel: 'Clear',
                        );
                        if (ok) await app.clearHistory();
                      },
                      icon: Icon(Icons.delete_outline_rounded, color: c.warning),
                      label: Text('Clear history', style: TextStyle(color: c.warning)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.stats});

  final String label;
  final DayStats stats;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final double? rate = stats.attempted == 0 ? null : stats.recalled / stats.attempted;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 86,
          child: Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              StatTile(value: '${stats.practised}', label: 'Practised'),
              StatTile(value: '${stats.recalled}', label: 'Recalled', color: c.success),
              StatTile(value: '${stats.neededHelp}', label: 'Help', color: c.warning),
              StatTile(
                  value: rate == null ? '–' : '${(rate * 100).round()}%',
                  label: 'Success'),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.history, required this.now});

  final Map<String, DayStats> history;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final List<DateTime> days = <DateTime>[
      for (int i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    int maxValue = 1;
    for (final DateTime d in days) {
      final int v = history[dateKey(d)]?.practised ?? 0;
      maxValue = math.max(maxValue, v);
    }
    const double chartHeight = 120;
    return SizedBox(
      height: chartHeight + 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final DateTime d in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text('${history[dateKey(d)]?.practised ?? 0}',
                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    width: 22,
                    height: math.max(
                        4.0,
                        chartHeight * ((history[dateKey(d)]?.practised ?? 0) / maxValue)),
                    decoration: BoxDecoration(
                      color: (history[dateKey(d)]?.practised ?? 0) == 0
                          ? c.surfaceAlt
                          : c.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(kWeekdayShort[d.weekday - 1],
                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.dateKeyText, required this.stats});

  final String dateKeyText;
  final DayStats stats;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final DateTime? day = parseDateKey(dateKeyText);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(day == null ? dateKeyText : formatDay(day),
                style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 4,
            child: Text(
              '${stats.practised} practised · ${stats.recalled} ✓ · ${stats.neededHelp} help · ${stats.skipped} skipped',
              textAlign: TextAlign.end,
              style: TextStyle(color: c.textMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
