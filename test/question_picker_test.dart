import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:juz30_hifz/logic/question_picker.dart';

void main() {
  List<int> range(int n) => <int>[for (int i = 0; i < n; i++) i];

  test('every ayah of the pool can be picked', () {
    final QuestionPicker p = QuestionPicker(
      pool: range(564),
      policy: RepeatPolicy.recentWindow,
      random: Random(1),
    );
    final Set<int> seen = <int>{};
    for (int i = 0; i < 30000; i++) {
      final int id = p.next();
      expect(id, inInclusiveRange(0, 563));
      seen.add(id);
    }
    expect(seen.length, 564);
  });

  test('recent window: never repeats one of the last few questions', () {
    final QuestionPicker p = QuestionPicker(
      pool: range(100),
      policy: RepeatPolicy.recentWindow,
      random: Random(2),
    );
    final List<int> history = <int>[];
    for (int i = 0; i < 3000; i++) {
      final int id = p.next();
      final int from = history.length > 12 ? history.length - 12 : 0;
      expect(history.sublist(from).contains(id), isFalse);
      history.add(id);
    }
  });

  test('full cycle: each cycle is a permutation, no repeat at the boundary', () {
    final QuestionPicker p = QuestionPicker(
      pool: range(50),
      policy: RepeatPolicy.fullCycle,
      random: Random(3),
    );
    int? previousLast;
    for (int cycle = 0; cycle < 6; cycle++) {
      final List<int> picks = <int>[for (int i = 0; i < 50; i++) p.next()];
      expect(picks.toSet().length, 50, reason: 'cycle $cycle');
      if (previousLast != null) {
        expect(picks.first, isNot(previousLast));
      }
      previousLast = picks.last;
    }
  });

  test('previously asked ids are avoided at the start', () {
    final QuestionPicker p = QuestionPicker(
      pool: range(30),
      policy: RepeatPolicy.fullCycle,
      random: Random(4),
      recent: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    );
    for (int i = 0; i < 20; i++) {
      expect(p.next(), greaterThanOrEqualTo(10));
    }
  });

  test('ids outside the pool in the recent list are ignored', () {
    final QuestionPicker p = QuestionPicker(
      pool: <int>[5, 6, 7, 8],
      policy: RepeatPolicy.recentWindow,
      random: Random(5),
      recent: <int>[100, 200],
    );
    expect(<int>[5, 6, 7, 8].contains(p.next()), isTrue);
  });

  test('a one-element pool keeps returning that element', () {
    final QuestionPicker p = QuestionPicker(
      pool: <int>[42],
      policy: RepeatPolicy.fullCycle,
      random: Random(6),
    );
    for (int i = 0; i < 5; i++) {
      expect(p.next(), 42);
    }
  });

  test('an empty pool is rejected', () {
    expect(
      () => QuestionPicker(pool: <int>[], policy: RepeatPolicy.recentWindow),
      throwsArgumentError,
    );
  });
}
