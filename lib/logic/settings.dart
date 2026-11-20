import 'dart:math' as math;

import '../data/models.dart';

enum ThemePref { system, light, dark }

enum Difficulty { easy, normal, challenge }

enum ScopeType { all, surah, range }

/// What "Show Full Ayah" reveals.
enum RevealMode { nextAyah, selectedAyah }

enum RecallResult { recalled, neededHelp, skipped }

const int kFirstSurah = QuranData.firstSurah;
const int kLastSurah = QuranData.lastSurah;

/// Surahs with at most this many ayahs count as "short" in Easy mode.
const int kEasyMaxAyahs = 11;

const List<int> kDailyGoalOptions = <int>[10, 20, 30, 50, 100];

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

int _clampInt(Object? value, int min, int max, int fallback) {
  if (value is int) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
  return fallback;
}

double _clampDouble(Object? value, double min, double max, double fallback) {
  if (value is num) {
    final double v = value.toDouble();
    if (v.isNaN) return fallback;
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
  return fallback;
}

class AppSettings {
  const AppSettings({
    this.theme = ThemePref.system,
    this.difficulty = Difficulty.normal,
    this.scopeType = ScopeType.all,
    this.fromSurah = kFirstSurah,
    this.toSurah = kLastSurah,
    this.revealMode = RevealMode.nextAyah,
    this.autoAdvance = true,
    this.includeLastAyah = true,
    this.arabicFontSize = 34,
    this.dailyGoal = 20,
  });

  final ThemePref theme;
  final Difficulty difficulty;
  final ScopeType scopeType;

  /// For [ScopeType.surah] this is the chosen surah; for [ScopeType.range] the
  /// first surah of the range.
  final int fromSurah;
  final int toSurah;
  final RevealMode revealMode;

  /// Jump to the next question right after marking a result.
  final bool autoAdvance;

  /// Whether the final ayah of each surah may be chosen as a question.
  final bool includeLastAyah;
  final double arabicFontSize;
  final int dailyGoal;

  static const double minFontSize = 24;
  static const double maxFontSize = 52;

  AppSettings copyWith({
    ThemePref? theme,
    Difficulty? difficulty,
    ScopeType? scopeType,
    int? fromSurah,
    int? toSurah,
    RevealMode? revealMode,
    bool? autoAdvance,
    bool? includeLastAyah,
    double? arabicFontSize,
    int? dailyGoal,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      difficulty: difficulty ?? this.difficulty,
      scopeType: scopeType ?? this.scopeType,
      fromSurah: fromSurah ?? this.fromSurah,
      toSurah: toSurah ?? this.toSurah,
      revealMode: revealMode ?? this.revealMode,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      includeLastAyah: includeLastAyah ?? this.includeLastAyah,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }

  /// Surah numbers selected by the current scope, ascending.
  List<int> get selectedSurahNumbers {
    if (scopeType == ScopeType.surah) {
      return <int>[fromSurah];
    }
    if (scopeType == ScopeType.range) {
      final int lo = math.min(fromSurah, toSurah);
      final int hi = math.max(fromSurah, toSurah);
      return <int>[for (int n = lo; n <= hi; n++) n];
    }
    return <int>[for (int n = kFirstSurah; n <= kLastSurah; n++) n];
  }

  String describeScope(QuranData data) {
    if (scopeType == ScopeType.surah) {
      final Surah s = data.surahByNumber(fromSurah);
      return 'Surah ${s.nameEn} (${s.number})';
    }
    if (scopeType == ScopeType.range) {
      final int lo = math.min(fromSurah, toSurah);
      final int hi = math.max(fromSurah, toSurah);
      if (lo == hi) {
        final Surah s = data.surahByNumber(lo);
        return 'Surah ${s.nameEn} ($lo)';
      }
      return 'Surahs $lo–$hi';
    }
    return 'All of Juz 30';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'theme': theme.name,
        'difficulty': difficulty.name,
        'scopeType': scopeType.name,
        'fromSurah': fromSurah,
        'toSurah': toSurah,
        'revealMode': revealMode.name,
        'autoAdvance': autoAdvance,
        'includeLastAyah': includeLastAyah,
        'arabicFontSize': arabicFontSize,
        'dailyGoal': dailyGoal,
      };

  /// Tolerant parser: unknown / invalid values fall back to defaults.
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    const AppSettings d = AppSettings();
    final int goalRaw = _clampInt(json['dailyGoal'], 1, 1000, d.dailyGoal);
    int goal = kDailyGoalOptions.first;
    for (final int option in kDailyGoalOptions) {
      if ((option - goalRaw).abs() < (goal - goalRaw).abs()) goal = option;
    }
    return AppSettings(
      theme: _enumByName(ThemePref.values, json['theme'], d.theme),
      difficulty: _enumByName(Difficulty.values, json['difficulty'], d.difficulty),
      scopeType: _enumByName(ScopeType.values, json['scopeType'], d.scopeType),
      fromSurah: _clampInt(json['fromSurah'], kFirstSurah, kLastSurah, d.fromSurah),
      toSurah: _clampInt(json['toSurah'], kFirstSurah, kLastSurah, d.toSurah),
      revealMode: _enumByName(RevealMode.values, json['revealMode'], d.revealMode),
      autoAdvance: json['autoAdvance'] is bool ? json['autoAdvance'] as bool : d.autoAdvance,
      includeLastAyah: json['includeLastAyah'] is bool
          ? json['includeLastAyah'] as bool
          : d.includeLastAyah,
      arabicFontSize: _clampDouble(
          json['arabicFontSize'], minFontSize, maxFontSize, d.arabicFontSize),
      dailyGoal: goal,
    );
  }
}
