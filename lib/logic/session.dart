import '../data/models.dart';
import 'question_picker.dart';
import 'settings.dart';

/// One question shown during a session.
class SessionEntry {
  SessionEntry(this.ayahId);

  final int ayahId;
  RecallResult? result;
  bool revealed = false;
}

/// A revision session: the questions asked so far, the current position and
/// the marks given. Supports stepping back to earlier questions.
class PracticeSession {
  PracticeSession({
    required this.data,
    required this.picker,
    required this.startedAt,
  });

  final QuranData data;
  final QuestionPicker picker;
  final DateTime startedAt;

  final List<SessionEntry> entries = <SessionEntry>[];
  int _index = -1;

  SessionEntry? get current => _index >= 0 ? entries[_index] : null;

  /// 1-based position of the current question (0 before the first one).
  int get position => _index + 1;

  bool get canGoBack => _index > 0;

  /// Moves forward. If the user had stepped back, this re-visits the next
  /// earlier question; otherwise a new random question is drawn.
  /// Returns true when a NEW question was drawn.
  bool advance() {
    if (_index < entries.length - 1) {
      _index++;
      return false;
    }
    entries.add(SessionEntry(picker.next()));
    _index = entries.length - 1;
    return true;
  }

  bool goBack() {
    if (!canGoBack) return false;
    _index--;
    return true;
  }

  /// Sets the result of the current question and returns the previous result.
  RecallResult? mark(RecallResult result) {
    final SessionEntry? entry = current;
    if (entry == null) return null;
    final RecallResult? previous = entry.result;
    entry.result = result;
    return previous;
  }

  int _count(RecallResult r) =>
      entries.where((SessionEntry e) => e.result == r).length;

  int get practised => entries.length;
  int get recalled => _count(RecallResult.recalled);
  int get neededHelp => _count(RecallResult.neededHelp);
  int get skipped => _count(RecallResult.skipped);

  /// Questions the user actually attempted (recalled or needed help).
  int get attempted => recalled + neededHelp;

  /// Fraction of attempted questions that were recalled, or null if none.
  double? get successRate => attempted == 0 ? null : recalled / attempted;

  List<SessionEntry> get helpEntries => <SessionEntry>[
        for (final SessionEntry e in entries)
          if (e.result == RecallResult.neededHelp) e,
      ];
}
