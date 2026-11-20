import 'dart:math';

/// How a [QuestionPicker] avoids repeating questions.
enum RepeatPolicy {
  /// Do not repeat any of the last few questions (Easy / Normal modes).
  recentWindow,

  /// Never repeat a question until every ayah of the pool has been asked once
  /// (Challenge mode); then start a new shuffled cycle.
  fullCycle,
}

/// Picks random ayah ids from a fixed pool.
///
/// Every pick is uniform among the ids that are currently allowed, so every
/// ayah in the pool is reachable. Cost per pick is O(pool size), at most a few
/// hundred operations for Juz 30.
class QuestionPicker {
  QuestionPicker({
    required List<int> pool,
    required this.policy,
    Random? random,
    Iterable<int> recent = const <int>[],
  })  : _pool = List<int>.unmodifiable(pool),
        _random = random ?? Random() {
    if (pool.isEmpty) {
      throw ArgumentError('QuestionPicker pool must not be empty.');
    }
    final Set<int> poolSet = _pool.toSet();
    // Seed with previously asked ids (oldest first) so repeats are also avoided
    // across sessions.
    for (final int id in recent) {
      if (poolSet.contains(id) && !_excluded.contains(id)) {
        _record(id);
      }
    }
  }

  final List<int> _pool;
  final Random _random;
  final RepeatPolicy policy;

  final List<int> _order = <int>[]; // excluded ids, oldest first
  final Set<int> _excluded = <int>{};

  int get poolSize => _pool.length;

  /// Number of ids that may repeat-window exclude (null = unlimited cycle).
  int? get _window {
    if (policy == RepeatPolicy.fullCycle) return null;
    return max(1, min(12, _pool.length ~/ 3));
  }

  int? get lastPicked => _order.isEmpty ? null : _order.last;

  void _record(int id) {
    _order.add(id);
    _excluded.add(id);
    final int? window = _window;
    if (window != null) {
      while (_order.length > window) {
        _excluded.remove(_order.removeAt(0));
      }
    }
  }

  List<int> _candidates() =>
      <int>[for (final int id in _pool) if (!_excluded.contains(id)) id];

  /// Returns the next question id.
  int next() {
    List<int> candidates = _candidates();
    if (candidates.isEmpty) {
      // Everything has been used: begin a new cycle. The most recent question
      // is only barred from being the very first pick of the new cycle (so the
      // same ayah never appears twice in a row); it is allowed again after
      // that. A one-element pool can only repeat.
      final int? last = lastPicked;
      _order.clear();
      _excluded.clear();
      candidates = _candidates();
      if (last != null && candidates.length > 1) {
        candidates.remove(last);
      }
    }
    final int pick = candidates[_random.nextInt(candidates.length)];
    _record(pick);
    return pick;
  }
}
