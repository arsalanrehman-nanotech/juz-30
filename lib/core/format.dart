// Small formatting helpers (pure Dart, no Flutter imports).

/// Converts Western digits in [n] to Arabic-Indic digits (٠١٢٣٤٥٦٧٨٩).
/// Used only for the decorative ayah-number badge.
String toArabicIndic(int n) {
  const int base = 0x0660;
  final StringBuffer buffer = StringBuffer();
  for (final int unit in n.toString().codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      buffer.writeCharCode(base + unit - 0x30);
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// 'yyyy-MM-dd' key for a calendar day (local time).
String dateKey(DateTime d) {
  final String y = d.year.toString().padLeft(4, '0');
  final String m = d.month.toString().padLeft(2, '0');
  final String day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime? parseDateKey(String key) {
  final List<String> parts = key.split('-');
  if (parts.length != 3) return null;
  final int? y = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  final int? d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

const List<String> kMonthShort = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> kWeekdayShort = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

String formatDay(DateTime d) => '${d.day} ${kMonthShort[d.month - 1]} ${d.year}';

String formatDuration(Duration d) {
  final int totalSeconds = d.inSeconds < 0 ? 0 : d.inSeconds;
  final int h = totalSeconds ~/ 3600;
  final int m = (totalSeconds % 3600) ~/ 60;
  final int s = totalSeconds % 60;
  final String mm = m.toString().padLeft(2, '0');
  final String ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
}
