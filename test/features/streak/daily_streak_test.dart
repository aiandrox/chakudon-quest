import 'package:flutter_test/flutter_test.dart';

import 'package:ramen_in_cho/features/records/models.dart';
import 'package:ramen_in_cho/features/scoring/points.dart';
import 'package:ramen_in_cho/features/scoring/record_outcome.dart';
import 'package:ramen_in_cho/features/streak/daily_streak.dart';

import '../../support/builders.dart';

void main() {
  final shop = buildShop();
  List<VisitWithShop> days(Iterable<int> ds) => [
    for (final d in ds)
      buildEntry(shop: shop, eatenAt: DateTime(2026, 3, d, 12)),
  ];

  test('毎日続けて食べた日数の最高記録。同じ日の2杯目は1日と数え、撤退は数えない', () {
    expect(bestDailyStreak(scoreVisits(days([1, 2, 3, 5, 6]))), 3);
    expect(
      bestDailyStreak(
        scoreVisits([
          ...days([1, 1, 2]),
          buildEntry(
            shop: shop,
            eatenAt: DateTime(2026, 3, 3),
            result: VisitResult.retreated,
          ),
          ...days([4]),
        ]),
      ),
      2,
    );
    expect(bestDailyStreak(const []), 0);
  });

  test('7日連続になった1杯で、隠し要素が出現する（6日では出ない。8日目には知らせない）', () {
    final sixDays = days(List.generate(6, (i) => i + 1));
    final seventh = buildEntry(shop: shop, eatenAt: DateTime(2026, 3, 7, 12));
    final eighth = buildEntry(shop: shop, eatenAt: DateTime(2026, 3, 8, 12));

    expect(
      computeRecordOutcome(sixDays, sixDays.last.visit.id)!.revealsHealthyLife,
      isFalse,
    );
    expect(
      computeRecordOutcome([
        ...sixDays,
        seventh,
      ], seventh.visit.id)!.revealsHealthyLife,
      isTrue,
    );
    expect(
      computeRecordOutcome([
        ...sixDays,
        seventh,
        eighth,
      ], eighth.visit.id)!.revealsHealthyLife,
      isFalse,
    );
  });
}
