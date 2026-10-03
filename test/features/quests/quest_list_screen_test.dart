import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/quests/quest_list_screen.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/wishes/wish_repository.dart';
import 'package:chakudon_quest/features/quests/quest_seal.dart';

import '../../support/builders.dart';
import '../../support/l10n.dart';

void main() {
  Future<void> pumpQuests(
    WidgetTester tester,
    List<VisitWithShop> visits,
  ) async {
    tester.view.physicalSize = const Size(1080, 7200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          wishesProvider.overrideWithValue(const AsyncData([])),
        ],
        child: localizedApp(
          home: Scaffold(body: ListView(children: const [QuestSections()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('常設とスポットに分けて表示する。記録が無ければすべて未達成', (tester) async {
    await pumpQuests(tester, const []);

    expect(find.text(ja.questStanding), findsOneWidget);
    expect(find.text(ja.questSpot), findsOneWidget);
    expect(find.text(ja.questLevelTotal(0)), findsNothing);
    expect(find.text(ja.questSpotSummary(0, 8)), findsOneWidget);
    expect(find.text('着丼の道'), findsOneWidget);
    expect(find.text('はじめての着丼'), findsOneWidget);
    expect(find.text(ja.questCount(0, '杯')), findsWidgets);
    final seals = tester.widgetList<QuestSeal>(find.byType(QuestSeal));
    expect(seals.map((seal) => seal.level).toSet(), {0});
    expect(find.text(ja.questLocked), findsNWidgets(seals.length));
  });

  testWidgets('常設はレベルと次の段階まで、スポットは達成と達成日を出す', (tester) async {
    final shop = buildShop(id: 'shop');
    await pumpQuests(tester, [
      for (var d = 1; d <= 10; d++)
        buildEntry(shop: shop, eatenAt: DateTime(2026, 9, d, 12)),
    ]);

    // 着丼の道は10杯で Lv.2（次は30杯）。
    expect(find.text(ja.questCount(10, '杯')), findsOneWidget);
    // はじめての着丼は達成。
    expect(find.text(ja.questCleared), findsOneWidget);
    expect(find.text(ja.questSpotSummary(1, 8)), findsOneWidget);
    // 着丼の道 Lv.2 + 開拓者 Lv.0 ...のレベル合計。
    expect(find.text(daijiNumber(2)), findsOneWidget);
  });
}
