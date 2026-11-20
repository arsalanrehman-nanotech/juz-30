import '../core/format.dart';
import 'settings.dart';

/// Counters for one calendar day.
class DayStats {
  const DayStats({
    this.practised = 0,
    this.recalled = 0,
    this.neededHelp = 0,
    this.skipped = 0,
  });

  final int practised;
  final int recalled;
  final int neededHelp;
  final int skipped;

  int get attempted => recalled + neededHelp;

  DayStats copyWith({int? practised, int? recalled, int? neededHelp, int? skipped}) {
    return DayStats(
      practised: practised ?? this.practised,
      recalled: recalled ?? this.recalled,
      neededHelp: neededHelp ?? this.neededHelp,
      skipped: skipped ?? this.skipped,
    );
  }

  /// Adds [delta] to the counter belonging to [result] (never below zero).
  DayStats adjust(RecallResult result, int delta) {
    int fix(int v) => v < 0 ? 0 : v;
    switch (result) {
      case RecallResult.recalled:
        return copyWith(recalled: fix(recalled + delta));
      case RecallResult.neededHelp:
        return copyWith(neededHelp: fix(neededHelp + delta));
      case RecallResult.skipped:
        return copyWith(skipped: fix(skipped + delta));
    }
  }

  DayStats operator +(DayStats other) => DayStats(
        practised: practised + other.practised,
        recalled: recalled + other.recalled,
        neededHelp: neededHelp + other.neededHelp,
        skipped: skipped + other.skipped,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'p': practised,
        'r': recalled,
        'h': neededHelp,
        's': skipped,
      };

  factory DayStats.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final Object? v = json[key];
      return v is int && v >= 0 ? v : 0;
    }

    return DayStats(
      practised: read('p'),
      recalled: read('r'),
      neededHelp: read('h'),
      skipped: read('s'),
    );
  }
}

/// Sum of the stats of the [days] most recent calendar days ending at [now].
DayStats sumLastDays(Map<String, DayStats> history, DateTime now, int days) {
  DayStats total = const DayStats();
  for (int i = 0; i < days; i++) {
    final DateTime d = DateTime(now.year, now.month, now.day - i);
    final DayStats? s = history[dateKey(d)];
    if (s != null) total = total + s;
  }
  return total;
}

/// Number of consecutive practice days. Today does not break the streak if it
/// has no practice yet; the count then ends yesterday.
int currentStreak(Map<String, DayStats> history, DateTime now) {
  DateTime day = DateTime(now.year, now.month, now.day);
  final DayStats? today = history[dateKey(day)];
  if (today == null || today.practised == 0) {
    day = DateTime(day.year, day.month, day.day - 1);
  }
  int streak = 0;
  while (true) {
    final DayStats? s = history[dateKey(day)];
    if (s == null || s.practised == 0) break;
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}
