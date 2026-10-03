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

  test('入門は最初の記録の日。累計が50点ちょうどになった1杯で初段に上がる', () {
    final a = buildShop(id: 'a');
    final b = buildShop(id: 'b');
    // 20 + 20 = 40 点では入門のまま。3杯目の 10 点で 50 点になる。
    final first = buildEntry(shop: a, eatenAt: day(1));
    final second = buildEntry(shop: b, eatenAt: day(2));
    final third = buildEntry(shop: a, eatenAt: day(3));
    final scored = scoreVisits([third, first, second]);

    final before = rankHistory(scored.take(2).toList());
    expect(before.map((e) => e.rank), [AdventurerRank.apprentice]);

    final history = rankHistory(scored);
    expect(history.map((e) => e.rank), [
      AdventurerRank.apprentice,
      AdventurerRank.dan1,
    ]);
    expect(history[0].visit!.visit.id, first.visit.id);
    expect(history[0].reachedAt, day(1));
    expect(history[1].visit!.visit.id, third.visit.id);
    expect(history[1].visit!.shop.name, 'a');
    expect(history[1].reachedAt, day(3));
  });

  test('49点では入門のまま、次の1杯で初段に上がる', () {
    final plain = buildShop(id: 'plain');
    final weekends = buildShop(
      id: 'weekends',
      hoursConditions: {HoursCondition.weekendsOnly},
    );
    // 初訪問・10分待ち 25 点 + 土日のみの初訪問 20 × 1.2 = 24 点 → 49 点。
    final scored = scoreVisits([
      buildEntry(shop: plain, eatenAt: day(1), waitMinutes: 10),
      buildEntry(shop: weekends, eatenAt: day(2)),
      buildEntry(shop: plain, eatenAt: day(3)),
    ]);
    final under = scored.take(2).toList();
    expect(totalPoints(under), 49);
    expect(rankHistory(under).last.rank, AdventurerRank.apprentice);

    final history = rankHistory(scored);
    expect(history.last.rank, AdventurerRank.dan1);
    expect(history.last.reachedAt, day(3));
  });

  test('1杯で複数の段位を越えたら、越えた段位すべてに同じ1杯をつける', () {
    final rare = buildShop(
      id: 'rare',
      hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
    );
    // (10 + 50 + 20 + 10) × 2 = 180 → 初段（50）と二段（120）を一度に越える。
    final big = buildEntry(
      shop: rare,
      eatenAt: day(1),
      isLimited: true,
      waitMinutes: 100,
    );
    // 10 + 10 = 20 → 累計 200 で三段（200）。
    final next = buildEntry(
      shop: buildShop(id: 'shop'),
      eatenAt: day(2),
    );
    final history = rankHistory(scoreVisits([big, next]));

    expect(history.map((e) => e.rank), [
      AdventurerRank.apprentice,
      AdventurerRank.dan1,
      AdventurerRank.dan2,
      AdventurerRank.dan3,
    ]);
    expect(history[1].visit!.visit.id, big.visit.id);
    expect(history[2].visit!.visit.id, big.visit.id);
    expect(history[3].visit!.visit.id, next.visit.id);
    expect(history[3].reachedAt, day(2));
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
