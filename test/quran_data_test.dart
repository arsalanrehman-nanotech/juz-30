import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:juz30_hifz/data/models.dart';

void main() {
  late QuranData data;

  setUpAll(() {
    final String source = File('assets/quran/juz30.json').readAsStringSync();
    data = QuranData.fromJsonString(source);
  });

  test('Juz 30 has 37 surahs and 564 ayahs, 78:1 to 114:6', () {
    expect(data.surahs.length, 37);
    expect(data.totalAyahs, 564);
    expect(data.surahs.first.number, 78);
    expect(data.surahs.last.number, 114);
    expect(data.refOf(0), const AyahRef(78, 1));
    expect(data.refOf(563), const AyahRef(114, 6));
  });

  test('ayah counts match the standard Hafs numbering', () {
    const Map<int, int> expected = <int, int>{
      78: 40, 79: 46, 80: 42, 81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17,
      87: 19, 88: 26, 89: 30, 90: 20, 91: 15, 92: 21, 93: 11, 94: 8, 95: 8,
      96: 19, 97: 5, 98: 8, 99: 8, 100: 11, 101: 11, 102: 8, 103: 3, 104: 9,
      105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3, 111: 5, 112: 4, 113: 5,
      114: 6,
    };
    for (final MapEntry<int, int> e in expected.entries) {
      expect(data.surahByNumber(e.key).ayahCount, e.value, reason: 'surah ${e.key}');
    }
  });

  test('ids and references round-trip for every ayah', () {
    for (int id = 0; id < data.totalAyahs; id++) {
      final AyahRef ref = data.refOf(id);
      expect(data.idOf(ref.surah, ref.ayah), id);
      expect(data.textOf(id).isNotEmpty, isTrue);
    }
  });

  test('last ayah of each surah has no next ayah', () {
    for (final Surah s in data.surahs) {
      final int lastId = data.idOf(s.number, s.ayahCount);
      expect(data.isLastAyahOfSurah(lastId), isTrue);
      expect(data.nextIdInSurah(lastId), isNull);
      final int firstId = data.idOf(s.number, 1);
      expect(data.nextIdInSurah(firstId), firstId + 1);
    }
  });

  test('corrupted data is rejected', () {
    expect(() => QuranData.fromJsonString('{}'), throwsFormatException);
    expect(() => QuranData.fromJsonString('[]'), throwsFormatException);
    expect(() => QuranData.fromJsonString('{"surahs":[]}'), throwsFormatException);
  });
}
