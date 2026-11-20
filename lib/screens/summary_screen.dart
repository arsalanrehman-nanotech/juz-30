import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../logic/session.dart';
import '../widgets/common.dart';

/// What the user chose on the summary screen.
enum SummaryAction { resume, newSession, home }

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.session, required this.data});

  final PracticeSession session;
  final QuranData data;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final double? rate = session.successRate;
    final String rateText = rate == null ? '–' : '${(rate * 100).round()}%';
    final Duration elapsed = DateTime.now().difference(session.startedAt);
    final List<SessionEntry> help = session.helpEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session summary'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(SummaryAction.resume),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: <Widget>[
                Panel(
                  child: Column(
                    children: <Widget>[
                      Text(rateText,
                          style: TextStyle(
                              fontSize: 44, fontWeight: FontWeight.w800, color: c.primary)),
                      Text('recalled of attempted',
                          style: TextStyle(color: c.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Time: ${formatDuration(elapsed)}',
                          style: TextStyle(color: c.textMuted, fontSize: 12.5)),
                      const SizedBox(height: 18),
                      const GoldDivider(),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          StatTile(value: '${session.practised}', label: 'Ayahs\npractised'),
                          StatTile(value: '${session.attempted}', label: 'Attempted'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          StatTile(
                              value: '${session.recalled}',
                              label: 'Successfully\nrecalled',
                              color: c.success),
                          StatTile(
                              value: '${session.neededHelp}',
                              label: 'Needed\nhelp',
                              color: c.warning),
                          StatTile(value: '${session.skipped}', label: 'Skipped'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (help.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Worth revising again',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
                        const SizedBox(height: 4),
                        Text('Ayahs where you needed help in this session.',
                            style: TextStyle(color: c.textMuted, fontSize: 12.5)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final SessionEntry e in help) _HelpChip(data: data, entry: e),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(SummaryAction.resume),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue this session'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(SummaryAction.newSession),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Start a new session'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(SummaryAction.home),
                  child: const Text('Back to home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HelpChip extends StatelessWidget {
  const _HelpChip({required this.data, required this.entry});

  final QuranData data;
  final SessionEntry entry;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final AyahRef ref = data.refOf(entry.ayahId);
    final Surah surah = data.surahByNumber(ref.surah);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.warning.withAlpha(0x22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.warning.withAlpha(0x66)),
      ),
      child: Text(
        '${surah.nameEn} ${ref.surah}:${ref.ayah}',
        style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
