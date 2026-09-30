import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';
import 'package:chakudon_quest/features/scoring/record_outcome.dart';

import '../../support/builders.dart';

void main() {
  final shop = buildShop(id: 'shop');
  DateTime day(int d) => DateTime(2026, 9, d, 12);

  test('保存した記録のポイントと、累計の変化を返す', () {
    final first = buildEntry(shop: shop, eatenAt: day(1));
    final second = buildEntry(shop: shop, eatenAt: day(2), isLimited: true);

    final outcome = computeRecordOutcome([second, first], second.visit.id)!;

    expect(outcome.scored.points.total, 30);
    expect(outcome.totalBefore, 20);
    expect(outcome.totalAfter, 50);
    expect(outcome.isRankUp, isFalse);
  });

  test('累計が200点に届くとランクアップ。届かなければしない', () {
    final rare = buildShop(
      id: 'rare',
      hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
    );
    // (10 + 10 + 20 + 20 + 30) × 2 = 180
    final big = buildEntry(
      shop: rare,
      eatenAt: day(1),
      isLimited: true,
      hasTicket: true,
      waitMinutes: 60,
    );
    // 初訪問 10 + 10 = 20 → 累計 200
    final reaches = buildEntry(shop: shop, eatenAt: day(2));
    final up = computeRecordOutcome([big, reaches], reaches.visit.id)!;

    expect(up.totalBefore, 180);
    expect(up.totalAfter, 200);
    expect(up.rankBefore, AdventurerRank.apprentice);
    expect(up.rankAfter, AdventurerRank.traveler);
    expect(up.isRankUp, isTrue);

    // 昼のみの店の初訪問 (10 + 10) × 1.5 = 30 → 累計 180 + 15 には届かない例として、
    // 2回目の「昼のみ」の店 10 × 1.5 = 15 → 累計 195
    final lunch = buildShop(
      id: 'lunch',
      hoursConditions: {HoursCondition.lunchOnly},
    );
    final lunchFirst = buildEntry(shop: lunch, eatenAt: day(1));
    final lunchAgain = buildEntry(shop: lunch, eatenAt: day(3));
    final bigOnly = computeRecordOutcome([big], big.visit.id)!;
    final notYet = computeRecordOutcome([
      big,
      lunchFirst,
      lunchAgain,
    ], lunchAgain.visit.id)!;

    expect(bigOnly.isRankUp, isFalse);
    expect(notYet.totalBefore, 210);
    expect(notYet.isRankUp, isFalse);
  });

  test('過去の日時の記録を足したときは、ほかの記録のボーナスの変化も含めた差になる', () {
    final later = buildEntry(shop: shop, eatenAt: day(10));
    final earlier = buildEntry(shop: shop, eatenAt: day(1));

    final outcome = computeRecordOutcome([later, earlier], earlier.visit.id)!;

    // 初訪問ボーナスが later から earlier に移るので、増えるのは10点だけ。
    expect(outcome.scored.points.total, 20);
    expect(outcome.totalBefore, 20);
    expect(outcome.totalAfter, 30);
  });

  test('撤退の記録は0点で、累計は変わらない', () {
    final retreat = buildEntry(
      shop: shop,
      eatenAt: day(1),
      result: VisitResult.retreated,
    );

    final outcome = computeRecordOutcome([retreat], retreat.visit.id)!;

    expect(outcome.scored.points.total, 0);
    expect(outcome.totalBefore, 0);
    expect(outcome.totalAfter, 0);
  });

  test('この記録で新しく達成したクエストを返す', () {
    final first = buildEntry(shop: shop, eatenAt: day(1));
    final second = buildEntry(shop: shop, eatenAt: day(2), waitMinutes: 40);

    final firstOutcome = computeRecordOutcome([first], first.visit.id)!;
    final secondOutcome = computeRecordOutcome([
      first,
      second,
    ], second.visit.id)!;

    expect(firstOutcome.achievedQuests.map((q) => q.id), ['first_bowl']);
    expect(secondOutcome.achievedQuests.map((q) => q.id), ['queue_30']);
  });

  test('撤退の記録ではクエストを達成しない', () {
    final retreat = buildEntry(
      shop: shop,
      eatenAt: day(1),
      result: VisitResult.retreated,
      waitMinutes: 90,
    );

    final outcome = computeRecordOutcome([retreat], retreat.visit.id)!;

    expect(outcome.achievedQuests, isEmpty);
  });

  test('記録が見つからなければnull', () {
    expect(computeRecordOutcome(const [], 'missing'), isNull);
  });
}
