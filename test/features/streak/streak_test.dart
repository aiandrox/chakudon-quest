import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/streak/streak.dart';

import '../../support/builders.dart';

void main() {
  // 2026-10-01 は木曜。その週の月曜は 9/28。
  final thursday = DateTime(2026, 10, 1, 12);

  test('週は月曜はじまり', () {
    expect(weekStartOf(DateTime(2026, 9, 28, 0, 0)), DateTime(2026, 9, 28));
    expect(weekStartOf(DateTime(2026, 10, 4, 23, 59)), DateTime(2026, 9, 28));
    expect(weekStartOf(DateTime(2026, 10, 5)), DateTime(2026, 10, 5));
    expect(weekStartOf(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });

  test('知らせるのは今週の日曜18時', () {
    expect(streakReminderTimeOf(thursday), DateTime(2026, 10, 4, 18));
    expect(
      streakReminderTimeOf(DateTime(2026, 10, 4, 20)),
      DateTime(2026, 10, 4, 18),
    );
  });

  test('今週を含めて続いている週を数える', () {
    final streak = currentStreak([
      buildVisit(eatenAt: DateTime(2026, 9, 14, 12)),
      buildVisit(eatenAt: DateTime(2026, 9, 21, 12)),
      buildVisit(eatenAt: DateTime(2026, 9, 27, 20)),
      buildVisit(eatenAt: DateTime(2026, 9, 29, 12)),
    ], thursday);

    expect(streak.weeks, 3);
    expect(streak.thisWeekDone, isTrue);
    expect(streak.isAtRisk, isFalse);
  });

  test('今週まだでも、先週まで続いていれば数え、途切れそうと判定する', () {
    final streak = currentStreak([
      buildVisit(eatenAt: DateTime(2026, 9, 14, 12)),
      buildVisit(eatenAt: DateTime(2026, 9, 22, 12)),
    ], thursday);

    expect(streak.weeks, 2);
    expect(streak.thisWeekDone, isFalse);
    expect(streak.isAtRisk, isTrue);
  });

  test('先週も今週も食べていなければ0週', () {
    final streak = currentStreak([
      buildVisit(eatenAt: DateTime(2026, 9, 14, 12)),
    ], thursday);

    expect(streak.weeks, 0);
    expect(streak.isAtRisk, isFalse);
  });

  test('間が1週空くと、そこで途切れる', () {
    final streak = currentStreak([
      buildVisit(eatenAt: DateTime(2026, 9, 7, 12)),
      buildVisit(eatenAt: DateTime(2026, 9, 21, 12)),
      buildVisit(eatenAt: DateTime(2026, 9, 30, 12)),
    ], thursday);

    expect(streak.weeks, 2);
  });

  test('撤退だけの週は数えない', () {
    final streak = currentStreak([
      buildVisit(eatenAt: DateTime(2026, 9, 22, 12)),
      buildVisit(
        eatenAt: DateTime(2026, 9, 30, 12),
        result: VisitResult.retreated,
      ),
    ], thursday);

    expect(streak.weeks, 1);
    expect(streak.thisWeekDone, isFalse);
  });

  test('年をまたいでも続けて数える', () {
    final streak = currentStreak([
      buildVisit(eatenAt: DateTime(2026, 12, 22, 12)),
      buildVisit(eatenAt: DateTime(2026, 12, 30, 12)),
      buildVisit(eatenAt: DateTime(2027, 1, 5, 12)),
    ], DateTime(2027, 1, 6));

    expect(streak.weeks, 3);
  });
}
