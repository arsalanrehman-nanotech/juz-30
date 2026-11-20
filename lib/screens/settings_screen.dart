import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../logic/settings.dart';
import '../state/app_scope.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/scope_selector.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final HifzColors c = HifzColors.of(context);
    final AppSettings s = app.settings;
    // A real ayah from the bundled data (never typed text) as the preview.
    final String previewText = app.data.surahByNumber(112).ayahs.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: <Widget>[
                _Section(
                  title: 'Appearance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SegmentedButton<ThemePref>(
                        showSelectedIcon: false,
                        segments: const <ButtonSegment<ThemePref>>[
                          ButtonSegment<ThemePref>(
                              value: ThemePref.system,
                              icon: Icon(Icons.brightness_auto_rounded),
                              label: Text('System')),
                          ButtonSegment<ThemePref>(
                              value: ThemePref.light,
                              icon: Icon(Icons.light_mode_rounded),
                              label: Text('Light')),
                          ButtonSegment<ThemePref>(
                              value: ThemePref.dark,
                              icon: Icon(Icons.dark_mode_rounded),
                              label: Text('Dark')),
                        ],
                        selected: <ThemePref>{s.theme},
                        onSelectionChanged: (Set<ThemePref> v) =>
                            app.updateSettings(s.copyWith(theme: v.first)),
                      ),
                      const SizedBox(height: 18),
                      Text('Arabic text size: ${s.arabicFontSize.round()}',
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                      Slider(
                        min: AppSettings.minFontSize,
                        max: AppSettings.maxFontSize,
                        divisions: 14,
                        value: s.arabicFontSize,
                        onChanged: (double v) =>
                            app.updateSettings(s.copyWith(arabicFontSize: v)),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ArabicText(previewText, fontSize: s.arabicFontSize),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Practice',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('Difficulty',
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 18),
                      Text('Surahs',
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ScopeSelector(
                        settings: s,
                        data: app.data,
                        onChanged: app.updateSettings,
                      ),
                      const SizedBox(height: 18),
                      Text('"Show Full Ayah" reveals',
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<RevealMode>(
                        showSelectedIcon: false,
                        segments: const <ButtonSegment<RevealMode>>[
                          ButtonSegment<RevealMode>(
                              value: RevealMode.nextAyah, label: Text('The next ayah')),
                          ButtonSegment<RevealMode>(
                              value: RevealMode.selectedAyah,
                              label: Text('The selected ayah')),
                        ],
                        selected: <RevealMode>{s.revealMode},
                        onSelectionChanged: (Set<RevealMode> v) =>
                            app.updateSettings(s.copyWith(revealMode: v.first)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s.revealMode == RevealMode.nextAyah
                            ? 'Shows the ayah you are trying to recall (the one after the question).'
                            : 'Shows the question ayah again as a reminder.',
                        style: TextStyle(color: c.textMuted, fontSize: 12.5),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Next question after marking'),
                        subtitle: const Text(
                            'Move on automatically when you mark a result.'),
                        value: s.autoAdvance,
                        onChanged: (bool v) =>
                            app.updateSettings(s.copyWith(autoAdvance: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include last ayah of each surah'),
                        subtitle: const Text(
                            'The last ayah has no next ayah to recite.'),
                        value: s.includeLastAyah,
                        onChanged: (bool v) =>
                            app.updateSettings(s.copyWith(includeLastAyah: v)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text('Daily goal (ayahs)',
                                style:
                                    TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                          ),
                          DropdownButton<int>(
                            value: s.dailyGoal,
                            borderRadius: BorderRadius.circular(16),
                            items: <DropdownMenuItem<int>>[
                              for (final int g in kDailyGoalOptions)
                                DropdownMenuItem<int>(value: g, child: Text('$g')),
                            ],
                            onChanged: (int? v) {
                              if (v != null) app.updateSettings(s.copyWith(dailyGoal: v));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'About',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Quran text: QUL Uthmani (Madinah Mushaf), Juz 30 only: '
                        '${QuranData.expectedAyahCount} ayahs in ${QuranData.expectedSurahCount} surahs '
                        '(78:1 to 114:6), bundled inside the app. Font: KFGQPC Uthmanic Script (Hafs). '
                        'Everything works offline and nothing leaves your device.',
                        style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.45),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final HifzColors c = HifzColors.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: c.text)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
