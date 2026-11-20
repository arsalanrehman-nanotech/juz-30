import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../logic/session.dart';
import '../logic/settings.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'summary_screen.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key, required this.app});

  final AppState app;

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  late PracticeSession _session;

  AppState get _app => widget.app;
  QuranData get _data => _app.data;

  @override
  void initState() {
    super.initState();
    _beginSession();
  }

  /// Creates a fresh session and draws its first question. The daily counters
  /// are updated after the first frame so that listeners are never notified
  /// while the framework is building.
  void _beginSession() {
    _session = _app.startSession();
    _session.advance();
    final int firstId = _session.current!.ayahId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _app.recordShown(firstId);
    });
  }

  void _next() {
    setState(() {
      final bool isNew = _session.advance();
      if (isNew) _app.recordShown(_session.current!.ayahId);
    });
  }

  void _previous() {
    setState(() {
      _session.goBack();
    });
  }

  void _toggleReveal() {
    final SessionEntry? entry = _session.current;
    if (entry == null) return;
    setState(() {
      entry.revealed = !entry.revealed;
    });
  }

  void _mark(RecallResult result) {
    final RecallResult? previous = _session.mark(result);
    _app.recordResult(previous, result);
    if (_app.settings.autoAdvance) {
      _next();
    } else {
      setState(() {});
    }
  }

  Future<void> _restart() async {
    final bool ok = await confirmDialog(
      context,
      title: 'Restart session?',
      message:
          'This starts a new session with fresh session counters. What you already practised today stays in your daily progress.',
      confirmLabel: 'Restart',
    );
    if (!ok || !mounted) return;
    setState(_beginSession);
  }

  Future<void> _finish() async {
    final SummaryAction? action = await Navigator.of(context).push<SummaryAction>(
      MaterialPageRoute<SummaryAction>(
        builder: (_) => SummaryScreen(session: _session, data: _data),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case SummaryAction.resume:
        break;
      case SummaryAction.newSession:
        setState(_beginSession);
        break;
      case SummaryAction.home:
        Navigator.of(context).pop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final SessionEntry? entry = _session.current;
    if (entry == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AppSettings settings = _app.settings;
    final AyahRef ref = _data.refOf(entry.ayahId);
    final Surah surah = _data.surahByNumber(ref.surah);
    final bool isLast = ref.ayah == surah.ayahCount;
    final bool nextMode = settings.revealMode == RevealMode.nextAyah;
    final bool canReveal = !nextMode || !isLast;
    final int? revealId = nextMode ? _data.nextIdInSurah(entry.ayahId) : entry.ayahId;
    final bool showReveal = entry.revealed && canReveal && revealId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_session.position}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Restart session',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: 'Finish and see summary',
            onPressed: _finish,
            icon: const Icon(Icons.flag_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: math.max(0.0, box.maxHeight - 16)),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _QuestionCard(
                                  surah: surah,
                                  ayah: ref.ayah,
                                  text: _data.textOf(entry.ayahId),
                                  fontSize: settings.arabicFontSize,
                                ),
                                const SizedBox(height: 12),
                                _Hint(
                                  isLast: isLast,
                                  nextMode: nextMode,
                                  ayah: ref.ayah,
                                  ayahCount: surah.ayahCount,
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  alignment: Alignment.topCenter,
                                  child: showReveal
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 14),
                                          child: _RevealCard(
                                            title: nextMode
                                                ? 'Next ayah · ${ref.surah}:${ref.ayah + 1}'
                                                : 'Selected ayah · ${ref.surah}:${ref.ayah}',
                                            ayahNumber:
                                                nextMode ? ref.ayah + 1 : ref.ayah,
                                            text: _data.textOf(revealId!),
                                            fontSize: settings.arabicFontSize,
                                          ),
                                        )
                                      : const SizedBox(width: double.infinity),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _RecallTile(
                              label: 'Successfully\nRecalled',
                              icon: Icons.check_circle_rounded,
                              color: c.success,
                              selected: entry.result == RecallResult.recalled,
                              onTap: () => _mark(RecallResult.recalled),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RecallTile(
                              label: 'Needed\nHelp',
                              icon: Icons.help_rounded,
                              color: c.warning,
                              selected: entry.result == RecallResult.neededHelp,
                              onTap: () => _mark(RecallResult.neededHelp),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RecallTile(
                              label: 'Skip',
                              icon: Icons.skip_next_rounded,
                              color: c.textMuted,
                              selected: entry.result == RecallResult.skipped,
                              onTap: () => _mark(RecallResult.skipped),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: canReveal ? _toggleReveal : null,
                        icon: Icon(entry.revealed && canReveal
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded),
                        label: Text(entry.revealed && canReveal ? 'Hide Ayah' : 'Show Full Ayah'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: OutlinedButton.icon(
                              onPressed: _session.canGoBack ? _previous : null,
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Previous'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: FilledButton.icon(
                              onPressed: _next,
                              icon: const Icon(Icons.casino_rounded),
                              label: const Text('Next Random Ayah'),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.fontSize,
  });

  final Surah surah;
  final int ayah;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Panel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AyahBadge(number: ayah),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Surah ${surah.nameEn}',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: c.text),
                    ),
                    Text(
                      'Surah ${surah.number} · Ayah $ayah of ${surah.ayahCount}',
                      style: TextStyle(fontSize: 12.5, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  surah.nameAr,
                  style: TextStyle(
                      fontFamily: kQuranFont, fontSize: 24, color: c.gold, height: 1.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const GoldDivider(),
          const SizedBox(height: 10),
          ArabicText(text, fontSize: _scaledSize(fontSize, text.length)),
        ],
      ),
    );
  }
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({
    required this.title,
    required this.ayahNumber,
    required this.text,
    required this.fontSize,
  });

  final String title;
  final int ayahNumber;
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Panel(
      color: c.revealBg,
      borderColor: c.gold,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_rounded, color: c.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: c.gold),
                ),
              ),
              AyahBadge(number: ayahNumber, size: 36),
            ],
          ),
          const SizedBox(height: 8),
          ArabicText(text, fontSize: _scaledSize(fontSize, text.length)),
        ],
      ),
    );
  }
}

/// Long ayahs are shown slightly smaller so they stay comfortable to read.
double _scaledSize(double base, int length) {
  if (length > 140) return base * 0.78;
  if (length > 90) return base * 0.88;
  return base;
}

class _Hint extends StatelessWidget {
  const _Hint({
    required this.isLast,
    required this.nextMode,
    required this.ayah,
    required this.ayahCount,
  });

  final bool isLast;
  final bool nextMode;
  final int ayah;
  final int ayahCount;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final String message;
    if (isLast) {
      message = 'This is the final ayah of the surah. Nothing further to recite here.';
    } else if (ayah + 1 == ayahCount) {
      message = 'Recite the next ayah (${ayah + 1}), the last of this surah.';
    } else {
      message = 'Recite from ayah ${ayah + 1} to the end of the surah (ayah $ayahCount).';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.5, color: c.textMuted, height: 1.4),
      ),
    );
  }
}

class _RecallTile extends StatelessWidget {
  const _RecallTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? color : color.withAlpha(0x1F);
    final Color foreground = selected ? Colors.white : color;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: foreground, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
