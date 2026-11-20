import 'dart:convert';

/// One surah of Juz 30 with its ayah texts exactly as stored in
/// assets/quran/juz30.json (never modified at runtime).
class Surah {
  const Surah({
    required this.number,
    required this.nameAr,
    required this.nameEn,
    required this.ayahs,
  });

  final int number;
  final String nameAr;
  final String nameEn;

  /// Ayah texts; ayah number n is `ayahs[n - 1]`.
  final List<String> ayahs;

  int get ayahCount => ayahs.length;
}

/// A reference to a single ayah (surah number : ayah number).
class AyahRef {
  const AyahRef(this.surah, this.ayah);

  final int surah;
  final int ayah;

  @override
  bool operator ==(Object other) =>
      other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}

/// The complete, validated Juz 30 data set.
///
/// Every ayah has a stable integer id in `0 .. totalAyahs - 1`, assigned in
/// Mushaf order (78:1 = 0 ... 114:6 = 563). Ids are what the random picker,
/// session and local storage work with.
class QuranData {
  QuranData._(this.surahs, this._offsets, this.totalAyahs);

  static const int firstSurah = 78;
  static const int lastSurah = 114;
  static const int expectedSurahCount = 37;
  static const int expectedAyahCount = 564;

  final List<Surah> surahs;
  final List<int> _offsets;
  final int totalAyahs;

  /// Parses and strictly validates the bundled JSON. Throws [FormatException]
  /// when anything is off, so a corrupted asset can never be used silently.
  factory QuranData.fromJsonString(String source) {
    final dynamic decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Quran data: root must be a JSON object.');
    }
    final dynamic rawSurahs = decoded['surahs'];
    if (rawSurahs is! List<dynamic>) {
      throw const FormatException('Quran data: "surahs" must be a list.');
    }

    final List<Surah> surahs = <Surah>[];
    for (final dynamic item in rawSurahs) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Quran data: surah entry is not an object.');
      }
      final dynamic rawAyahs = item['ayahs'];
      if (rawAyahs is! List<dynamic>) {
        throw FormatException('Quran data: surah ${item['number']} has no ayah list.');
      }
      final List<String> ayahs = <String>[];
      for (final dynamic a in rawAyahs) {
        if (a is! String || a.isEmpty) {
          throw FormatException('Quran data: bad ayah text in surah ${item['number']}.');
        }
        ayahs.add(a);
      }
      final Object? number = item['number'];
      final Object? nameAr = item['name_ar'];
      final Object? nameEn = item['name_en'];
      final Object? declared = item['ayah_count'];
      if (number is! int || nameAr is! String || nameEn is! String) {
        throw const FormatException('Quran data: surah header is malformed.');
      }
      if (declared != ayahs.length) {
        throw FormatException(
            'Quran data: surah $number declares $declared ayahs but has ${ayahs.length}.');
      }
      surahs.add(Surah(
        number: number,
        nameAr: nameAr,
        nameEn: nameEn,
        ayahs: List<String>.unmodifiable(ayahs),
      ));
    }

    if (surahs.length != expectedSurahCount) {
      throw FormatException(
          'Quran data: expected $expectedSurahCount surahs, found ${surahs.length}.');
    }
    for (int i = 0; i < surahs.length; i++) {
      if (surahs[i].number != firstSurah + i) {
        throw FormatException(
            'Quran data: surah order broken at index $i (found ${surahs[i].number}).');
      }
    }

    final List<int> offsets = <int>[];
    int total = 0;
    for (final Surah s in surahs) {
      offsets.add(total);
      total += s.ayahCount;
    }
    if (total != expectedAyahCount) {
      throw FormatException(
          'Quran data: expected $expectedAyahCount ayahs in Juz 30, found $total.');
    }
    return QuranData._(
      List<Surah>.unmodifiable(surahs),
      List<int>.unmodifiable(offsets),
      total,
    );
  }

  Surah surahByNumber(int number) {
    if (number < firstSurah || number > lastSurah) {
      throw RangeError.range(number, firstSurah, lastSurah, 'number');
    }
    return surahs[number - firstSurah];
  }

  /// Id of ayah [ayah] (1-based) of surah [surah].
  int idOf(int surah, int ayah) {
    final Surah s = surahByNumber(surah);
    RangeError.checkValueInInterval(ayah, 1, s.ayahCount, 'ayah');
    return _offsets[surah - firstSurah] + ayah - 1;
  }

  /// Surah/ayah reference for [id].
  AyahRef refOf(int id) {
    RangeError.checkValueInInterval(id, 0, totalAyahs - 1, 'id');
    int lo = 0;
    int hi = _offsets.length - 1;
    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (_offsets[mid] <= id) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return AyahRef(firstSurah + lo, id - _offsets[lo] + 1);
  }

  Surah surahOfId(int id) => surahByNumber(refOf(id).surah);

  String textOf(int id) {
    final AyahRef r = refOf(id);
    return surahByNumber(r.surah).ayahs[r.ayah - 1];
  }

  bool isLastAyahOfSurah(int id) {
    final AyahRef r = refOf(id);
    return r.ayah == surahByNumber(r.surah).ayahCount;
  }

  /// Id of the following ayah within the same surah, or null for the last ayah.
  int? nextIdInSurah(int id) => isLastAyahOfSurah(id) ? null : id + 1;
}
