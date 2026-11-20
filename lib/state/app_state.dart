import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../logic/pool_builder.dart';
import '../logic/question_picker.dart';
import '../logic/session.dart';
import '../logic/settings.dart';
import '../logic/stats.dart';
import '../services/app_storage.dart';

/// App-wide state: settings, daily history and the recently asked questions.
class AppState extends ChangeNotifier {
  AppState({required this.data, required AppStorage storage})
      : _storage = storage,
        _settings = storage.loadSettings(),
        _history = storage.loadHistory(),
        _recent = storage.loadRecent();

  static const int _recentCap = 150;

  final QuranData data;
  final AppStorage _storage;

  AppSettings _settings;
  Map<String, DayStats> _history;
  List<int> _recent;

  AppSettings get settings => _settings;
  bool get storageAvailable => _storage.isAvailable;
  Map<String, DayStats> get history => Map<String, DayStats>.unmodifiable(_history);

  DayStats get today => _history[dateKey(DateTime.now())] ?? const DayStats();

  int get streak => currentStreak(_history, DateTime.now());

  Future<void> updateSettings(AppSettings next) async {
    _settings = next;
    notifyListeners();
    await _storage.saveSettings(next);
  }

  /// The pool that a new session would use with the current settings.
  PoolResult get currentPool => buildPool(data, _settings);

  PracticeSession startSession() {
    final PoolResult pool = currentPool;
    final RepeatPolicy policy = _settings.difficulty == Difficulty.challenge
        ? RepeatPolicy.fullCycle
        : RepeatPolicy.recentWindow;
    final QuestionPicker picker = QuestionPicker(
      pool: pool.ids,
      policy: policy,
      recent: _recent,
    );
    return PracticeSession(data: data, picker: picker, startedAt: DateTime.now());
  }

  /// Called whenever a NEW question is shown.
  void recordShown(int ayahId) {
    _updateToday((DayStats d) => d.copyWith(practised: d.practised + 1));
    _recent = <int>[..._recent, ayahId];
    if (_recent.length > _recentCap) {
      _recent = _recent.sublist(_recent.length - _recentCap);
    }
    unawaited(_storage.saveRecent(_recent));
    notifyListeners();
  }

  /// Called when the result of a question is set or changed.
  void recordResult(RecallResult? previous, RecallResult current) {
    if (previous == current) return;
    _updateToday((DayStats d) {
      DayStats next = d;
      if (previous != null) next = next.adjust(previous, -1);
      return next.adjust(current, 1);
    });
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = <String, DayStats>{};
    _recent = <int>[];
    notifyListeners();
    await _storage.saveHistory(_history);
    await _storage.saveRecent(_recent);
  }

  void _updateToday(DayStats Function(DayStats) change) {
    final String key = dateKey(DateTime.now());
    final Map<String, DayStats> next = Map<String, DayStats>.of(_history);
    next[key] = change(next[key] ?? const DayStats());
    _history = next;
    unawaited(_storage.saveHistory(_history));
  }
}
