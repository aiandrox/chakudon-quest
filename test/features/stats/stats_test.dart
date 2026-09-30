import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';
import 'package:chakudon_quest/features/stats/stats.dart';

import '../../support/builders.dart';

void main() {
  final shopA = buildShop(id: 'a', name: 'A店');
  final shopB = buildShop(id: 'b', name: 'B店');
  final shopC = buildShop(id: 'c', name: 'C店', hoursType: HoursType.fewDays);

  group('杯数', () {
    final scored = scoreVisits([
      buildEntry(shop: shopA, eatenAt: DateTime(2025, 12, 31, 23, 59)),
      buildEntry(shop: shopA, eatenAt: DateTime(2026, 1, 1)),
      buildEntry(shop: shopB, eatenAt: DateTime(2026, 9, 30)),
      buildEntry(
        shop: shopB,
        eatenAt: DateTime(2026, 10, 1),
        result: VisitResult.retreated,
      ),
    ]);

    test('今年の杯数は、その年に食べた記録だけを数える', () {
      expect(bowlsInYear(scored, 2026), 2);
      expect(bowlsInYear(scored, 2025), 1);
      expect(bowlsInYear(scored, 2024), 0);
    });

    test('累計の杯数に撤退は含めない', () {
      expect(totalBowls(scored), 3);
      expect(totalBowls(const []), 0);
    });
  });

  group('styleShares', () {
    test('系統ごとの杯数と割合を、多い順に返す', () {
      final shares = styleShares(
        scoreVisits([
          buildEntry(shop: shopA, style: RamenStyle.miso),
          buildEntry(shop: shopA, style: RamenStyle.shoyu),
          buildEntry(shop: shopA, style: RamenStyle.shoyu),
          buildEntry(shop: shopA),
        ]),
      );

      expect(shares.map((s) => s.style), [
        RamenStyle.shoyu,
        RamenStyle.miso,
        null,
      ]);
      expect(shares.map((s) => s.count), [2, 1, 1]);
      expect(shares.map((s) => s.ratio), [0.5, 0.25, 0.25]);
    });

    test('撤退は数えない。記録が無ければ空', () {
      expect(
        styleShares(
          scoreVisits([
            buildEntry(
              shop: shopA,
              style: RamenStyle.jiro,
              result: VisitResult.retreated,
            ),
          ]),
        ),
        isEmpty,
      );
      expect(styleShares(const []), isEmpty);
    });
  });

  group('frequentShops', () {
    DateTime day(int d) => DateTime(2026, 9, d, 12);

    test('食べた回数の多い順。同数なら最近行った店が先', () {
      final shops = frequentShops(
        scoreVisits([
          buildEntry(shop: shopA, eatenAt: day(1)),
          buildEntry(shop: shopB, eatenAt: day(2)),
          buildEntry(shop: shopB, eatenAt: day(3)),
          buildEntry(shop: shopC, eatenAt: day(4)),
          buildEntry(
            shop: shopA,
            eatenAt: day(5),
            result: VisitResult.retreated,
          ),
        ]),
      );

      expect(shops.map((s) => s.shop.name), ['B店', 'C店', 'A店']);
      expect(shops.map((s) => s.count), [2, 1, 1]);
    });

    test('上位の件数を絞れる', () {
      final shops = frequentShops(
        scoreVisits([
          buildEntry(shop: shopA, eatenAt: day(1)),
          buildEntry(shop: shopB, eatenAt: day(2)),
          buildEntry(shop: shopC, eatenAt: day(3)),
        ]),
        limit: 2,
      );

      expect(shops.map((s) => s.shop.name), ['C店', 'B店']);
    });
  });

  group('rankedShops', () {
    DateTime day(int d) => DateTime(2026, 9, d, 12);

    test('店ごとの最高ポイントでランクをつけ、高い順に返す', () {
      final shops = rankedShops(
        scoreVisits([
          // A店: 20, 10 → 最高20（C）
          buildEntry(shop: shopA, eatenAt: day(1)),
          buildEntry(shop: shopA, eatenAt: day(2)),
          // B店: 10 + 10 + 20 = 40（A）
          buildEntry(shop: shopB, eatenAt: day(3), isLimited: true),
          // C店: (10 + 10 + 20) × 2 = 80（S）
          buildEntry(shop: shopC, eatenAt: day(4), isLimited: true),
        ]),
      );

      expect(shops.map((s) => s.shop.name), ['C店', 'B店', 'A店']);
      expect(shops.map((s) => s.rank), [ShopRank.s, ShopRank.a, ShopRank.c]);
      expect(shops.map((s) => s.bestPoints), [80, 40, 20]);
      expect(shops.map((s) => s.count), [1, 1, 2]);
    });

    test('撤退しかしていない店は含めない', () {
      final shops = rankedShops(
        scoreVisits([
          buildEntry(
            shop: shopA,
            eatenAt: day(1),
            result: VisitResult.retreated,
          ),
        ]),
      );

      expect(shops, isEmpty);
    });
  });
}
