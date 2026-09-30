import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/quests/quest_list_screen.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';

import '../../support/builders.dart';
import '../../support/l10n.dart';

void main() {
  Future<void> pumpQuests(
    WidgetTester tester,
    List<VisitWithShop> visits,
  ) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [visitsProvider.overrideWithValue(AsyncData(visits))],
        child: localizedApp(home: const QuestListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('記録が無いときは、8件すべて未達成で表示する', (tester) async {
    await pumpQuests(tester, const []);

    expect(find.text(ja.questSummary(0, 8)), findsOneWidget);
    expect(find.text('はじめての着丼'), findsOneWidget);
    expect(find.text('食べた記録が1件'), findsOneWidget);
    expect(find.text('百杯の道'), findsOneWidget);
    expect(find.text(ja.questStatusNotStarted), findsNWidgets(8));
  });

  testWidgets('達成済み・挑戦中・未達成を見分けて表示する', (tester) async {
    final shop = buildShop(id: 'shop');
    await pumpQuests(tester, [
      buildEntry(
        shop: shop,
        eatenAt: DateTime(2026, 9, 1, 12),
        isLimited: true,
        style: RamenStyle.shoyu,
      ),
      buildEntry(
        shop: shop,
        eatenAt: DateTime(2026, 9, 2, 12),
        isLimited: true,
        style: RamenStyle.miso,
      ),
    ]);

    expect(find.text(ja.questSummary(1, 8)), findsOneWidget);
    // はじめての着丼
    expect(find.text(ja.questStatusAchieved), findsOneWidget);
    expect(find.text(ja.questAchievedOn('2026/9/1')), findsOneWidget);
    // 全系統制覇 2/7、限定を狩れ 2/5、百杯の道 2/100
    expect(find.text(ja.questStatusInProgress), findsNWidgets(3));
    expect(find.text(ja.questProgress(2, 7)), findsOneWidget);
    expect(find.text(ja.questProgress(2, 5)), findsOneWidget);
    expect(find.text(ja.questProgress(2, 100)), findsOneWidget);
    expect(find.text(ja.questStatusNotStarted), findsNWidgets(4));
  });
}
