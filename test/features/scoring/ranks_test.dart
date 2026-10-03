import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';

import '../../support/builders.dart';

void main() {
  group('adventurerRankFor', () {
    test('累計ポイントの境界でランクが上がる', () {
      expect(adventurerRankFor(0), AdventurerRank.apprentice);
      expect(adventurerRankFor(49), AdventurerRank.apprentice);
      expect(adventurerRankFor(50), AdventurerRank.dan1);
      expect(adventurerRankFor(119), AdventurerRank.dan1);
      expect(adventurerRankFor(120), AdventurerRank.dan2);
      expect(adventurerRankFor(199), AdventurerRank.dan2);
      expect(adventurerRankFor(200), AdventurerRank.dan3);
      expect(adventurerRankFor(1599), AdventurerRank.dan8);
      expect(adventurerRankFor(1600), AdventurerRank.dan9);
      expect(adventurerRankFor(2099), AdventurerRank.dan9);
      expect(adventurerRankFor(2100), AdventurerRank.master);
      expect(adventurerRankFor(2799), AdventurerRank.master);
      expect(adventurerRankFor(2800), AdventurerRank.grandmaster);
      expect(adventurerRankFor(100000), AdventurerRank.grandmaster);
    });

    test('段位は12段階で、必要ポイントは小さい順', () {
      final points = [
        for (final rank in AdventurerRank.values) rank.requiredPoints,
      ];
      expect(points, hasLength(12));
      expect(points, [...points]..sort());
    });

    test('次のランクと必要ポイントがわかる。最高ランクの次は無い', () {
      expect(AdventurerRank.apprentice.next, AdventurerRank.dan1);
      expect(AdventurerRank.apprentice.next!.requiredPoints, 50);
      expect(AdventurerRank.dan9.next, AdventurerRank.master);
      expect(AdventurerRank.grandmaster.next, isNull);
    });
  });

  group('shopRankFor', () {
    test('最高ポイントの境界でランクが決まる', () {
      expect(shopRankFor(0), ShopRank.c);
      expect(shopRankFor(24), ShopRank.c);
      expect(shopRankFor(25), ShopRank.b);
      expect(shopRankFor(39), ShopRank.b);
      expect(shopRankFor(40), ShopRank.a);
      expect(shopRankFor(59), ShopRank.a);
      expect(shopRankFor(60), ShopRank.s);
      expect(shopRankFor(500), ShopRank.s);
    });
  });

  group('shopRanks', () {
    DateTime day(int d) => DateTime(2026, 9, d, 12);

    test('店ごとに、合計ではなく最高ポイントで決まる', () {
      final often = buildShop(id: 'often');
      final hard = buildShop(
        id: 'hard',
        hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
      );
      final ranks = shopRanks(
        scoreVisits([
          // 20, 10, 10, 10（合計50でも最高は20）
          for (var d = 1; d <= 4; d++) buildEntry(shop: often, eatenAt: day(d)),
          // (10 + 10 + 20) × 2 = 80
          buildEntry(shop: hard, eatenAt: day(5), isLimited: true),
        ]),
      );

      expect(ranks, {'often': ShopRank.c, 'hard': ShopRank.s});
    });

    test('撤退しかしていない店にはランクをつけない', () {
      final ranks = shopRanks(
        scoreVisits([
          buildEntry(
            shop: buildShop(id: 'closed'),
            eatenAt: day(1),
            result: VisitResult.retreated,
          ),
        ]),
      );

      expect(ranks, isEmpty);
    });
  });
}
