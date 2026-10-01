import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/clock.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/stats/stats_screen.dart';

import '../../support/builders.dart';
import '../../support/l10n.dart';

void main() {
  Future<void> pumpStats(
    WidgetTester tester,
    List<VisitWithShop> visits,
  ) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 1)),
        ],
        child: localizedApp(home: const StatsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('記録が無いときは案内を出す', (tester) async {
    await pumpStats(tester, const []);

    expect(find.text(ja.statsEmpty), findsOneWidget);
    expect(find.text(ja.statsThisYear), findsNothing);
  });

  testWidgets('記録を読み込めなかったときは、記録が無いとは表示しない', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(
            AsyncError(StateError('db'), StackTrace.empty),
          ),
        ],
        child: localizedApp(home: const StatsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(ja.homeLoadFailed), findsOneWidget);
    expect(find.text(ja.statsEmpty), findsNothing);
  });

  testWidgets('今年の杯数・系統の割合・よく行く店・店ランクを表示する', (tester) async {
    final often = buildShop(id: 'often', name: 'よく行く麺屋');
    final rare = buildShop(
      id: 'rare',
      name: '週2日の店',
      hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
    );
    await pumpStats(tester, [
      buildEntry(
        shop: often,
        eatenAt: DateTime(2025, 12, 1, 12),
        style: RamenStyle.shoyu,
      ),
      buildEntry(
        shop: often,
        eatenAt: DateTime(2026, 9, 1, 12),
        style: RamenStyle.shoyu,
      ),
      buildEntry(
        shop: often,
        eatenAt: DateTime(2026, 9, 2, 12),
        style: RamenStyle.miso,
      ),
      // (10 + 10 + 20) × 2 = 80 → Sランク
      buildEntry(
        shop: rare,
        eatenAt: DateTime(2026, 9, 3, 12),
        isLimited: true,
      ),
    ]);

    expect(find.text(ja.bowls(3)), findsWidgets);
    expect(find.text(ja.bowls(4)), findsOneWidget);

    expect(find.text(ja.styleShoyu), findsOneWidget);
    expect(find.text(ja.percent(50)), findsOneWidget);
    expect(find.text(ja.percent(25)), findsNWidgets(2));
    expect(find.text(ja.styleMiso), findsOneWidget);
    expect(find.text(ja.styleUnset), findsOneWidget);

    // よく行く店と店ランクの両方に出る。
    expect(find.text('よく行く麺屋'), findsNWidgets(2));
    expect(find.text('週2日の店'), findsNWidgets(2));
    expect(find.text(ja.shopRankS), findsOneWidget);
    expect(find.text(ja.shopRankC), findsOneWidget);
    expect(find.text(ja.statsBestPoints(80)), findsOneWidget);
    expect(find.text(ja.statsBestPoints(20)), findsOneWidget);

    expect(find.text(ja.statsBests), findsOneWidget);
    expect(find.text(ja.bestHighestPoints), findsOneWidget);
    expect(find.text(ja.bestDetail('週2日の店', '2026/9/3')), findsOneWidget);
    // 並んだ記録も撤退も無いので、その2つは出さない。
    expect(find.text(ja.bestLongestWait), findsNothing);
    expect(find.text(ja.bestMostRetreats), findsNothing);
  });
}
