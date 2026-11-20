import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// Loads the bundled Juz 30 data. Throws if the asset is missing or invalid.
Future<QuranData> loadQuranData() async {
  final String source = await rootBundle.loadString('assets/quran/juz30.json');
  return QuranData.fromJsonString(source);
}
