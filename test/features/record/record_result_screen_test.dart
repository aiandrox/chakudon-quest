import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/record/record_result_screen.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';

import '../../support/builders.dart';
import '../../support/l10n.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 9, d, 12);

  Future<void> pumpResult(
    WidgetTester tester,
    List<VisitWithShop> visits,
    String visitId,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [visitsProvider.overrideWithValue(AsyncData(visits))],
        child: localizedApp(home: RecordResultScreen(visitId: visitId)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('得たポイントの内訳と、累計・次のランクまでを表示する', (tester) async {
    final lunch = buildShop(
      id: 'lunch',
      name: '昼だけの店',
      hoursConditions: {HoursCondition.lunchOnly},
    );
    // (10 + 15 + 20 + 10) × 1.5 = 82.5 → 82
    final entry = buildEntry(
      shop: lunch,
      eatenAt: day(1),
      waitMinutes: 35,
      isLimited: true,
    );
    await pumpResult(tester, [entry], entry.visit.id);

    expect(find.text('昼だけの店'), findsOneWidget);
    expect(find.text(ja.pointsGained(82)), findsOneWidget);
    expect(find.text(ja.pointsBase), findsOneWidget);
    expect(find.text(ja.pointsWait(35)), findsOneWidget);
    expect(find.text(ja.pointsGained(15)), findsOneWidget);
    expect(find.text(ja.isLimited), findsOneWidget);
    expect(find.text(ja.pointsFirstVisit), findsOneWidget);
    expect(find.text(ja.pointsHours(ja.hoursLunchOnly)), findsOneWidget);
    expect(find.text(ja.pointsMultiplier('1.5')), findsOneWidget);
    // 0点の項目は出さない。
    expect(find.text(ja.hasTicket), findsNothing);
    expect(find.text(ja.pointsRetry), findsNothing);

    expect(find.text(ja.rankApprentice), findsOneWidget);
    expect(find.text(ja.totalPoints(82)), findsOneWidget);
    expect(find.text(ja.nextRank(ja.rankTraveler, 118)), findsOneWidget);
    expect(find.text(ja.rankUp), findsNothing);

    // 最初の1杯で「はじめての着丼」、35分待ちで「行列に挑む者」、
    // 1杯で60点以上（Sランク）なので「大物討伐」を達成する。
    expect(find.text(ja.questAchieved), findsNWidgets(3));
    expect(find.text('はじめての着丼'), findsOneWidget);
    expect(find.text('行列に挑む者'), findsOneWidget);
    expect(find.text('大物討伐'), findsOneWidget);
  });

  testWidgets('ランクが上がったら知らせる', (tester) async {
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
    // 10 + 10 = 20 → 累計 200
    final reaches = buildEntry(
      shop: buildShop(id: 'shop'),
      eatenAt: day(2),
    );
    await pumpResult(tester, [reaches, big], reaches.visit.id);

    expect(find.text(ja.rankUp), findsOneWidget);
    expect(find.text(ja.rankTraveler), findsNWidgets(2));
    expect(find.text(ja.totalPoints(200)), findsOneWidget);
  });

  testWidgets('最高ランクでは、次のランクの代わりに到達を表示する', (tester) async {
    final rare = buildShop(
      id: 'rare',
      hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
    );
    // 1杯目 180、以降 (10 + 20 + 20 + 30) × 2 = 160 ずつ
    final entries = [
      for (var d = 1; d <= 10; d++)
        buildEntry(
          shop: rare,
          eatenAt: day(d),
          isLimited: true,
          hasTicket: true,
          waitMinutes: 60,
        ),
    ];
    await pumpResult(tester, entries, entries.last.visit.id);

    // この1杯で最高ランクに上がるため、お知らせとランク表示の両方に出る。
    expect(find.text(ja.rankLegend), findsNWidgets(2));
    expect(find.text(ja.maxRank), findsOneWidget);
  });

  testWidgets('記録がまだ読み込まれていなければ待つ', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [visitsProvider.overrideWithValue(const AsyncData([]))],
        child: localizedApp(home: const RecordResultScreen(visitId: 'v')),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(ja.resultOk), findsOneWidget);
  });
}
