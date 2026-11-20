import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:juz30_hifz/data/models.dart';
import 'package:juz30_hifz/logic/pool_builder.dart';
import 'package:juz30_hifz/logic/question_picker.dart';
import 'package:juz30_hifz/logic/session.dart';
import 'package:juz30_hifz/logic/settings.dart';
import 'package:juz30_hifz/logic/stats.dart';

void main() {
  late QuranData data;

  setUpAll(() {
    data = QuranData.fromJsonString(File('assets/quran/juz30.json').readAsStringSync());
  });

  group('pool builder', () {
    test('all of Juz 30', () {
      final PoolResult r = buildPool(data, const AppSettings());
      expect(r.ids.length, 564);
      expect(r.easyFallback, isFalse);
    });

    test('excluding last ayahs removes one ayah per surah', () {
      final PoolResult r = buildPool(data, const AppSettings(includeLastAyah: false));
      expect(r.ids.length, 564 - 37);
      for (final int id in r.ids) {
        expect(data.isLastAyahOfSurah(id), isFalse);
      }
    });

    test('easy mode uses only surahs of at most $kEasyMaxAyahs ayahs', () {
      final PoolResult r = buildPool(data, const AppSettings(difficulty: Difficulty.easy));
      expect(r.ids.length, 138);
      for (final int id in r.ids) {
        expect(data.surahOfId(id).ayahCount <= kEasyMaxAyahs, isTrue);
      }
    });

    test('single surah and range', () {
      final PoolResult one = buildPool(
          data, const AppSettings(scopeType: ScopeType.surah, fromSurah: 114));
      expect(one.ids.length, 6);
      final PoolResult range = buildPool(
          data,
          const AppSettings(
              scopeType: ScopeType.range, fromSurah: 114, toSurah: 112));
      expect(range.ids.length, 15);
    });

    test('easy mode on only long surahs falls back to the full selection', () {
      final PoolResult r = buildPool(
          data,
          const AppSettings(
              difficulty: Difficulty.easy, scopeType: ScopeType.surah, fromSurah: 78));
      expect(r.easyFallback, isTrue);
      expect(r.ids.length, 40);
    });
  });

  group('session', () {
    PracticeSession make() => PracticeSession(
          data: data,
          picker: QuestionPicker(
            pool: <int>[for (int i = 0; i < 564; i++) i],
            policy: RepeatPolicy.recentWindow,
            random: Random(7),
          ),
          startedAt: DateTime(2026, 1, 1),
        );

    test('counts practised, attempted, recalled, help and skipped', () {
      final PracticeSession s = make();
      s.advance();
      s.mark(RecallResult.recalled);
      s.advance();
      s.mark(RecallResult.neededHelp);
      s.advance();
      s.mark(RecallResult.skipped);
      s.advance();
      expect(s.practised, 4);
      expect(s.recalled, 1);
      expect(s.neededHelp, 1);
      expect(s.skipped, 1);
      expect(s.attempted, 2);
      expect(s.successRate, closeTo(0.5, 1e-9));
    });

    test('previous question and re-marking', () {
      final PracticeSession s = make();
      s.advance();
      final int first = s.current!.ayahId;
      s.advance();
      expect(s.canGoBack, isTrue);
      s.goBack();
      expect(s.current!.ayahId, first);
      expect(s.mark(RecallResult.recalled), isNull);
      expect(s.mark(RecallResult.neededHelp), RecallResult.recalled);
      expect(s.recalled, 0);
      expect(s.neededHelp, 1);
      // Going forward again revisits the existing question, no new draw.
      expect(s.advance(), isFalse);
      expect(s.practised, 2);
      // At the end, advance draws a new question.
      expect(s.advance(), isTrue);
      expect(s.practised, 3);
    });

    test('cannot go back from the first question', () {
      final PracticeSession s = make();
      s.advance();
      expect(s.canGoBack, isFalse);
      expect(s.goBack(), isFalse);
    });
  });

  group('settings and stats', () {
    test('settings survive a JSON round trip', () {
      const AppSettings original = AppSettings(
        theme: ThemePref.dark,
        difficulty: Difficulty.challenge,
        scopeType: ScopeType.range,
        fromSurah: 90,
        toSurah: 100,
        revealMode: RevealMode.selectedAyah,
        autoAdvance: false,
        includeLastAyah: false,
        arabicFontSize: 40,
        dailyGoal: 50,
      );
      final AppSettings copy = AppSettings.fromJson(original.toJson());
      expect(copy.toJson(), original.toJson());
    });

    test('garbage settings fall back to defaults', () {
      final AppSettings s = AppSettings.fromJson(<String, dynamic>{
        'theme': 'neon',
        'difficulty': 5,
        'fromSurah': 9999,
        'arabicFontSize': 'big',
        'dailyGoal': -3,
      });
      expect(s.theme, ThemePref.system);
      expect(s.difficulty, Difficulty.normal);
      expect(s.fromSurah, kLastSurah);
      expect(s.arabicFontSize, 34);
      expect(kDailyGoalOptions.contains(s.dailyGoal), isTrue);
    });

    test('day stats adjust and streak', () {
      DayStats d = const DayStats(practised: 3, recalled: 1);
      d = d.adjust(RecallResult.recalled, -1).adjust(RecallResult.neededHelp, 1);
      expect(d.recalled, 0);
      expect(d.neededHelp, 1);
      expect(d.adjust(RecallResult.skipped, -5).skipped, 0);

      final DateTime now = DateTime(2026, 11, 20);
      final Map<String, DayStats> h = <String, DayStats>{
        '2026-11-20': const DayStats(practised: 5),
        '2026-11-19': const DayStats(practised: 2),
        '2026-11-18': const DayStats(practised: 1),
        '2026-11-16': const DayStats(practised: 9),
      };
      expect(currentStreak(h, now), 3);
      h.remove('2026-11-20');
      expect(currentStreak(h, now), 2); // today empty does not break the streak
    });
  });
}
