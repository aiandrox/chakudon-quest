import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';

import '../../support/builders.dart';

void main() {
  group('adventurerRankFor', () {
    test('累計ポイントの境界でランクが上がる', () {
      expect(adventurerRankFor(0), AdventurerRank.apprentice);
      expect(adventurerRankFor(199), AdventurerRank.apprentice);
      expect(adventurerRankFor(200), AdventurerRank.traveler);
      expect(adventurerRankFor(599), AdventurerRank.traveler);
      expect(adventurerRankFor(600), AdventurerRank.hero);
      expect(adventurerRankFor(1499), AdventurerRank.hero);
      expect(adventurerRankFor(1500), AdventurerRank.legend);
      expect(adventurerRankFor(100000), AdventurerRank.legend);
    });

    test('次のランクと必要ポイントがわかる。最高ランクの次は無い', () {
      expect(AdventurerRank.apprentice.next, AdventurerRank.traveler);
      expect(AdventurerRank.apprentice.next!.requiredPoints, 200);
      expect(AdventurerRank.hero.next, AdventurerRank.legend);
      expect(AdventurerRank.legend.next, isNull);
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
      final hard = buildShop(id: 'hard', hoursType: HoursType.fewDays);
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
