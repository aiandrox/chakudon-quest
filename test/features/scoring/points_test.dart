import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';

import '../../support/builders.dart';

PointsBreakdown _points({
  int? waitMinutes,
  bool isLimited = false,
  bool hasTicket = false,
  bool isFirstVisit = false,
  bool isRetrySuccess = false,
  HoursType hoursType = HoursType.normal,
  VisitResult result = VisitResult.eaten,
}) => calculatePoints(
  visit: buildVisit(
    result: result,
    waitMinutes: waitMinutes,
    isLimited: isLimited,
    hasTicket: hasTicket,
  ),
  hoursType: hoursType,
  isFirstVisit: isFirstVisit,
  isRetrySuccess: isRetrySuccess,
);

void main() {
  group('calculatePoints', () {
    test('何もボーナスが無い記録は10点', () {
      final points = _points();

      expect(points.base, 10);
      expect(points.subtotal, 10);
      expect(points.total, 10);
    });

    test('待ち時間は10分ごとに+5。端数は切り捨てる', () {
      expect(_points(waitMinutes: 0).waitBonus, 0);
      expect(_points(waitMinutes: 9).waitBonus, 0);
      expect(_points(waitMinutes: 10).waitBonus, 5);
      expect(_points(waitMinutes: 19).waitBonus, 5);
      expect(_points(waitMinutes: 20).waitBonus, 10);
      expect(_points(waitMinutes: 59).waitBonus, 25);
      expect(_points(waitMinutes: 60).waitBonus, 30);
    });

    test('チェックインしていなければ待ち時間ボーナスは0', () {
      expect(_points().waitBonus, 0);
    });

    test('食べた時刻がチェックインより前なら待ち時間ボーナスは0', () {
      expect(_points(waitMinutes: -30).waitBonus, 0);
    });

    test('限定+20、整理券+20、初訪問+10、再挑戦成功+15', () {
      expect(_points(isLimited: true).total, 30);
      expect(_points(hasTicket: true).total, 30);
      expect(_points(isFirstVisit: true).total, 20);
      expect(_points(isRetrySuccess: true).total, 25);
    });

    test('すべてのボーナスを合計する', () {
      final points = _points(
        waitMinutes: 45,
        isLimited: true,
        hasTicket: true,
        isFirstVisit: true,
        isRetrySuccess: true,
      );

      // 10 + 20 + 20 + 20 + 10 + 15
      expect(points.subtotal, 95);
      expect(points.total, 95);
    });

    test('営業時間の倍率は合計にかける（昼のみ×1.5、週3日以下×2）', () {
      expect(_points(hoursType: HoursType.lunchOnly).total, 15);
      expect(_points(hoursType: HoursType.fewDays).total, 20);
      expect(_points(isLimited: true, hoursType: HoursType.fewDays).total, 60);
    });

    test('倍率をかけたあとの小数は切り捨てる', () {
      // (10 + 5) × 1.5 = 22.5
      expect(
        _points(waitMinutes: 10, hoursType: HoursType.lunchOnly).total,
        22,
      );
      // (10 + 15) × 1.5 = 37.5
      expect(
        _points(isRetrySuccess: true, hoursType: HoursType.lunchOnly).total,
        37,
      );
    });

    test('撤退の記録は0点', () {
      final points = _points(
        result: VisitResult.retreated,
        waitMinutes: 60,
        isLimited: true,
        hasTicket: true,
        hoursType: HoursType.fewDays,
      );

      expect(points.total, 0);
      expect(points.subtotal, 0);
    });
  });

  group('scoreVisits', () {
    final shopA = buildShop(id: 'a');
    final shopB = buildShop(id: 'b');
    DateTime day(int d) => DateTime(2026, 9, d, 12);

    test('店ごとに最初の「食べた」記録だけが初訪問になる', () {
      final scored = scoreVisits([
        buildEntry(shop: shopA, eatenAt: day(1)),
        buildEntry(shop: shopB, eatenAt: day(2)),
        buildEntry(shop: shopA, eatenAt: day(3)),
      ]);

      expect(scored.map((s) => s.isFirstVisit), [true, true, false]);
      expect(scored.map((s) => s.points.total), [20, 20, 10]);
    });

    test('渡した順番に関係なく、食べた時刻の古い順に採点する', () {
      final scored = scoreVisits([
        buildEntry(shop: shopA, eatenAt: day(3)),
        buildEntry(shop: shopA, eatenAt: day(1)),
      ]);

      expect(scored.map((s) => s.visit.eatenAt), [day(1), day(3)]);
      expect(scored.map((s) => s.isFirstVisit), [true, false]);
    });

    test('撤退の次に同じ店で食べると再挑戦成功。初訪問と両方つく', () {
      final scored = scoreVisits([
        buildEntry(shop: shopA, eatenAt: day(1), result: VisitResult.retreated),
        buildEntry(shop: shopA, eatenAt: day(2)),
        buildEntry(shop: shopA, eatenAt: day(3)),
      ]);

      expect(scored.map((s) => s.isRetrySuccess), [false, true, false]);
      expect(scored.map((s) => s.isFirstVisit), [false, true, false]);
      // 撤退 0 / 10 + 10 + 15 / 10
      expect(scored.map((s) => s.points.total), [0, 35, 10]);
    });

    test('撤退のあとに別の店で食べても再挑戦成功にならない', () {
      final scored = scoreVisits([
        buildEntry(shop: shopA, eatenAt: day(1), result: VisitResult.retreated),
        buildEntry(shop: shopB, eatenAt: day(2)),
        buildEntry(shop: shopA, eatenAt: day(3)),
      ]);

      expect(scored.map((s) => s.isRetrySuccess), [false, false, true]);
    });

    test('撤退が続いたあとに食べても再挑戦成功は1回だけ', () {
      final scored = scoreVisits([
        buildEntry(shop: shopA, eatenAt: day(1), result: VisitResult.retreated),
        buildEntry(shop: shopA, eatenAt: day(2), result: VisitResult.retreated),
        buildEntry(shop: shopA, eatenAt: day(3)),
        buildEntry(shop: shopA, eatenAt: day(4)),
      ]);

      expect(scored.map((s) => s.isRetrySuccess), [false, false, true, false]);
    });

    test('店の営業時間の倍率を使い、累計ポイントを合計する', () {
      final rare = buildShop(id: 'rare', hoursType: HoursType.fewDays);
      final scored = scoreVisits([
        buildEntry(shop: rare, eatenAt: day(1), waitMinutes: 30),
        buildEntry(shop: shopA, eatenAt: day(2)),
      ]);

      // (10 + 15 + 10) × 2 = 70、10 + 10 = 20
      expect(scored.map((s) => s.points.total), [70, 20]);
      expect(totalPoints(scored), 90);
    });

    test('記録が無ければ累計は0', () {
      expect(totalPoints(scoreVisits(const [])), 0);
    });
  });
}
