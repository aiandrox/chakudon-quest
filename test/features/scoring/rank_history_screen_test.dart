import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/inkan/inkan_stamp.dart';
import 'package:chakudon_quest/features/records/date_format.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/scoring/rank_history_screen.dart';
import 'package:chakudon_quest/features/scoring/rank_progress.dart';
import 'package:chakudon_quest/features/visit_detail/visit_detail_screen.dart';
import 'package:chakudon_quest/features/wishes/wish_repository.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';
import 'package:chakudon_quest/features/words/words.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';
import '../../support/l10n.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 9, d, 12);

  Future<void> pumpHistory(
    WidgetTester tester,
    List<VisitWithShop> visits, {
    Widget home = const RankHistoryScreen(),
  }) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          wishesProvider.overrideWithValue(const AsyncData([])),
          recordRepositoryProvider.overrideWithValue(FakeRecordRepository()),
          documentsDirectoryProvider.overrideWithValue(createTempDirectory()),
        ],
        child: localizedApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder seal(String label) => find.byWidgetPredicate(
    (widget) => widget is RankSeal && widget.label == label,
  );

  testWidgets('上がった段位は日付と店、次の段位は残りの点、その先は伏せる', (tester) async {
    final rare = buildShop(
      id: 'rare',
      name: '幻の店',
      hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
    );
    // (10 + 50 + 20 + 10) × 2 = 180 → 初段と二段に一度に上がる。
    final big = buildEntry(
      shop: rare,
      eatenAt: day(5),
      isLimited: true,
      waitMinutes: 100,
    );
    await pumpHistory(tester, [big]);

    expect(seal(ja.rankApprentice), findsOneWidget);
    expect(seal(ja.rankFirstDan), findsOneWidget);
    expect(seal(ja.rankDan('二')), findsOneWidget);
    expect(find.text(formatDate(day(5))), findsNWidgets(3));
    expect(find.text('幻の店'), findsNWidgets(3));

    // 三段（200点）まで、あと 20 点。名前は見える。
    expect(seal(ja.rankDan('三')), findsOneWidget);
    expect(find.text(ja.rankHistoryRemaining(20)), findsOneWidget);
    expect(find.text(masterWords(AdventurerRank.dan2)), findsOneWidget);
    expect(find.text(masterWords(AdventurerRank.dan3)), findsNothing);

    // 四段より先は名前も点も出さない。
    expect(seal(ja.rankDan('四')), findsNothing);
    expect(seal(ja.rankGrandmaster), findsNothing);
    expect(seal(ja.rankHistoryHidden), findsNWidgets(8));

    await tester.tap(find.text('幻の店').at(1));
    await tester.pumpAndSettle();
    expect(find.byType(VisitDetailScreen), findsOneWidget);
  });

  testWidgets('記録が無ければ入門だけが上がった段位で、次は初段', (tester) async {
    await pumpHistory(tester, const []);

    expect(seal(ja.rankApprentice), findsOneWidget);
    expect(find.text(ja.rankHistoryNoRecord), findsOneWidget);
    expect(seal(ja.rankFirstDan), findsOneWidget);
    expect(find.text(ja.rankHistoryRemaining(50)), findsOneWidget);
    expect(seal(ja.rankHistoryHidden), findsNWidgets(10));
  });

  testWidgets('段位の表示をタップすると昇段の記録を開く', (tester) async {
    await pumpHistory(
      tester,
      const [],
      home: const Scaffold(body: RankProgress(totalPoints: 0)),
    );

    await tester.tap(find.byType(RankProgress));
    await tester.pumpAndSettle();
    expect(find.byType(RankHistoryScreen), findsOneWidget);
    expect(find.text(ja.rankHistoryTitle), findsOneWidget);
  });
}
