import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../logic/pool_builder.dart';
import '../logic/settings.dart';
import '../logic/stats.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/scope_selector.dart';
import 'revision_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final HifzColors c = HifzColors.of(context);
    final AppSettings s = app.settings;
    final PoolResult pool = app.currentPool;
    final DayStats today = app.today;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: <Widget>[
                _Header(
                  onStats: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const StatisticsScreen()),
                  ),
                  onSettings: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                  ),
                ),
                const SizedBox(height: 18),
                _Hero(
                  summary:
                      '${_difficultyLabel(s.difficulty)} · ${s.describeScope(app.data)} · ${pool.ids.length} ayahs',
                  onStart: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => RevisionScreen(app: app)),
                  ),
                ),
                if (pool.easyFallback) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Easy mode needs short surahs; none are selected, so all selected ayahs are used.',
                    style: TextStyle(color: c.warning, fontSize: 12.5),
                  ),
                ],
                const SizedBox(height: 20),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('Practice mode',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
                      const SizedBox(height: 12),
                      SegmentedButton<Difficulty>(
                        showSelectedIcon: false,
                        segments: const <ButtonSegment<Difficulty>>[
                          ButtonSegment<Difficulty>(
                              value: Difficulty.easy, label: Text('Easy')),
                          ButtonSegment<Difficulty>(
                              value: Difficulty.normal, label: Text('Normal')),
                          ButtonSegment<Difficulty>(
                              value: Difficulty.challenge, label: Text('Challenge')),
                        ],
                        selected: <Difficulty>{s.difficulty},
                        onSelectionChanged: (Set<Difficulty> v) =>
                            app.updateSettings(s.copyWith(difficulty: v.first)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _difficultyHelp(s.difficulty),
                        style: TextStyle(color: c.textMuted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              s.describeScope(app.data),
                              style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openScopeSheet(context),
                            icon: const Icon(Icons.tune_rounded, size: 18),
                            label: const Text('Choose Surahs'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _TodayCard(today: today, goal: s.dailyGoal, streak: app.streak),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${app.data.totalAyahs} ayahs · ${app.data.surahs.length} surahs · works fully offline',
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                  ),
                ),
                if (!app.storageAvailable) ...<Widget>[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Local storage is unavailable; progress will not be saved.',
                      style: TextStyle(color: c.warning, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.normal:
        return 'Normal';
      case Difficulty.challenge:
        return 'Challenge';
    }
  }

  static String _difficultyHelp(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Random ayahs from the shorter surahs (up to $kEasyMaxAyahs ayahs).';
      case Difficulty.normal:
        return 'Random ayahs from your selected surahs; recent ones are skipped.';
      case Difficulty.challenge:
        return 'No ayah repeats until every ayah in your selection has been asked.';
    }
  }

  static void _openScopeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final AppState app = AppScope.of(sheetContext);
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Which Surahs do you want to practise?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ScopeSelector(
                  settings: app.settings,
                  data: app.data,
                  onChanged: app.updateSettings,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onStats, required this.onSettings});

  final VoidCallback onStats;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Juz 30 Hifz',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800, color: c.text)),
              Text('Daily revision of Amma Para',
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Statistics',
          onPressed: onStats,
          icon: Icon(Icons.bar_chart_rounded, color: c.primary, size: 28),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: onSettings,
          icon: Icon(Icons.settings_rounded, color: c.primary, size: 26),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.summary, required this.onStart});

  final String summary;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[c.heroStart, c.heroEnd],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Revise from memory',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'A random ayah appears. Recite from the next ayah to the end of the surah.',
            style: TextStyle(color: Colors.white.withAlpha(0xDD), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: c.gold.withAlpha(0x99)),
          const SizedBox(height: 12),
          Text(summary,
              style: TextStyle(color: Colors.white.withAlpha(0xCC), fontSize: 12.5)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF3D98B),
                foregroundColor: const Color(0xFF3B2B00),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 26),
              label: const Text('Start Revision',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.today, required this.goal, required this.streak});

  final DayStats today;
  final int goal;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    final double progress = goal <= 0 ? 0 : math.min(1.0, today.practised / goal);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text("Today's progress",
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
              ),
              Icon(Icons.local_fire_department_rounded, color: c.gold, size: 20),
              const SizedBox(width: 4),
              Text(
                streak == 1 ? '1 day streak' : '$streak day streak',
                style: TextStyle(color: c.textMuted, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: c.surfaceAlt,
                        valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text('${today.practised}',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800, color: c.text)),
                        Text('of $goal',
                            style: TextStyle(fontSize: 11, color: c.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    StatTile(
                        value: '${today.recalled}', label: 'Recalled', color: c.success),
                    StatTile(
                        value: '${today.neededHelp}', label: 'Needed help', color: c.warning),
                    StatTile(value: '${today.skipped}', label: 'Skipped'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
