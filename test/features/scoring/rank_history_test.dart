import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';
import 'package:chakudon_quest/features/scoring/rank_history.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';

import '../../support/builders.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 9, d, 12);

  test('記録が無ければ入門だけで、日付は無い', () {
    final history = rankHistory(const []);

    expect(history, hasLength(1));
    expect(history.single.rank, AdventurerRank.apprentice);
    expect(history.single.visit, isNull);
    expect(history.single.reachedAt, isNull);
  });

  test('入門は最初の記録の日。1杯目（20点）で五級、累計40点ちょうどの1杯で四級に上がる', () {
    final a = buildShop(id: 'a');
    // 初訪問 20 点 → 五級（15）。同じ店の 10 点 2 杯で 40 点 → 四級（40）。
    final first = buildEntry(shop: a, eatenAt: day(1));
    final second = buildEntry(shop: a, eatenAt: day(2));
    final third = buildEntry(shop: a, eatenAt: day(3));
    final scored = scoreVisits([third, first, second]);

    final before = rankHistory(scored.take(2).toList());
    expect(totalPoints(scored.take(2).toList()), 30);
    expect(before.map((e) => e.rank), [
      AdventurerRank.apprentice,
      AdventurerRank.kyu5,
    ]);

    final history = rankHistory(scored);
    expect(history.map((e) => e.rank), [
      AdventurerRank.apprentice,
      AdventurerRank.kyu5,
      AdventurerRank.kyu4,
    ]);
    expect(history[0].visit!.visit.id, first.visit.id);
    expect(history[0].reachedAt, day(1));
    expect(history[1].visit!.visit.id, first.visit.id);
    expect(history[2].visit!.visit.id, third.visit.id);
    expect(history[2].visit!.shop.name, 'a');
    expect(history[2].reachedAt, day(3));
  });

  test('1杯で複数の段位を越えたら、越えた段位すべてに同じ1杯をつける', () {
    final rare = buildShop(
      id: 'rare',
      hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
    );
    // (10 + 50 + 20 + 10) × 2 = 180 → 五級〜一級（15〜160）を一度に越える。
    final big = buildEntry(
      shop: rare,
      eatenAt: day(1),
      isLimited: true,
      waitMinutes: 100,
    );
    // 10 + 20 + 10 = 40 → 累計 220 で初段（220）。
    final next = buildEntry(
      shop: buildShop(id: 'shop'),
      eatenAt: day(2),
      isLimited: true,
    );
    final history = rankHistory(scoreVisits([big, next]));

    expect(history.map((e) => e.rank), [
      AdventurerRank.apprentice,
      AdventurerRank.kyu5,
      AdventurerRank.kyu4,
      AdventurerRank.kyu3,
      AdventurerRank.kyu2,
      AdventurerRank.kyu1,
      AdventurerRank.dan1,
    ]);
    for (var i = 1; i <= 5; i++) {
      expect(history[i].visit!.visit.id, big.visit.id);
    }
    expect(history[6].visit!.visit.id, next.visit.id);
    expect(history[6].reachedAt, day(2));
  });

  test('撤退の記録（0点）では昇段しない', () {
    final retreat = buildEntry(
      shop: buildShop(id: 'a'),
      eatenAt: day(1),
      result: VisitResult.retreated,
    );
    final history = rankHistory(scoreVisits([retreat]));

    expect(history.map((e) => e.rank), [AdventurerRank.apprentice]);
    expect(history.single.visit!.visit.id, retreat.visit.id);
  });
}
