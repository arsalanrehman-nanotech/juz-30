import '../data/models.dart';
import 'settings.dart';

class PoolResult {
  const PoolResult(this.ids, {this.easyFallback = false});

  /// Ayah ids that may be asked, ascending.
  final List<int> ids;

  /// True when Easy mode was requested but the selected surahs contain no short
  /// surah, so the whole selection is used instead.
  final bool easyFallback;
}

/// Builds the pool of question ids for the given settings.
PoolResult buildPool(QuranData data, AppSettings settings) {
  List<int> surahNumbers = settings.selectedSurahNumbers;
  bool easyFallback = false;

  if (settings.difficulty == Difficulty.easy) {
    final List<int> short = <int>[
      for (final int n in surahNumbers)
        if (data.surahByNumber(n).ayahCount <= kEasyMaxAyahs) n,
    ];
    if (short.isEmpty) {
      easyFallback = true;
    } else {
      surahNumbers = short;
    }
  }

  List<int> collect(bool includeLast) {
    final List<int> ids = <int>[];
    for (final int n in surahNumbers) {
      final Surah surah = data.surahByNumber(n);
      final int first = data.idOf(n, 1);
      for (int a = 1; a <= surah.ayahCount; a++) {
        if (!includeLast && a == surah.ayahCount) continue;
        ids.add(first + a - 1);
      }
    }
    return ids;
  }

  List<int> ids = collect(settings.includeLastAyah);
  if (ids.isEmpty) {
    ids = collect(true);
  }
  return PoolResult(ids, easyFallback: easyFallback);
}
