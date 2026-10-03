import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ramen_in_cho/features/inkan/inkan_stamp.dart';

import 'package:ramen_in_cho/features/records/clock.dart';
import 'package:ramen_in_cho/features/records/models.dart';
import 'package:ramen_in_cho/features/records/record_repository.dart';
import 'package:ramen_in_cho/features/review/year_review_entry.dart';
import 'package:ramen_in_cho/features/review/year_review_screen.dart';
import 'package:ramen_in_cho/features/wishes/wish_repository.dart';
import 'package:ramen_in_cho/features/words/words.dart';

import '../../support/builders.dart';
import '../../support/l10n.dart';

void main() {
  final shop = buildShop(id: 'a', name: '麺屋あさひ');
  final visits = [
    buildEntry(shop: shop, eatenAt: DateTime(2025, 5, 1, 12)),
    buildEntry(
      shop: shop,
      eatenAt: DateTime(2026, 3, 5, 12),
      style: RamenStyle.shoyu,
    ),
    buildEntry(
      shop: shop,
      eatenAt: DateTime(2026, 4, 1, 12),
      result: VisitResult.retreated,
    ),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    DateTime? now,
    List<VisitWithShop>? entries,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(entries ?? visits)),
          wishesProvider.overrideWithValue(const AsyncData([])),
          clockProvider.overrideWithValue(() => now ?? DateTime(2026, 10, 3)),
        ],
        child: localizedApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('表紙から締めのひとことまで、横にめくって見られる', (tester) async {
    await pump(tester, const YearReviewScreen(year: 2026));

    expect(find.text(ja.reviewCoverEra('令和', '八')), findsOneWidget);
    expect(find.textContaining('（'), findsNothing);
    expect(find.text(ja.reviewCoverYear(2026)), findsWidgets);
    expect(find.text(ja.reviewCoverHint), findsOneWidget);

    await next(tester);
    expect(find.text(ja.reviewCountsTitle), findsOneWidget);
    // この一年の1杯の印を押し終えてから、数字を出す。
    expect(find.byType(InkanStamp), findsOneWidget);
    expect(find.text(ja.bowls(1)), findsOneWidget);
    expect(find.text(ja.reviewRetreatCount(1)), findsOneWidget);

    // 2杯以上の店も、並んだ記録も無いので、その2枚は飛ばす。
    await next(tester);
    expect(find.text(ja.reviewBestTitle), findsOneWidget);
    expect(find.text('麺屋あさひ'), findsOneWidget);

    await next(tester);
    expect(find.text(ja.statsStyles), findsOneWidget);

    await next(tester);
    expect(find.text(ja.reviewMonthlyTitle), findsOneWidget);

    // 段位も型も届いていないので、成果の1枚は飛ばす。
    await next(tester);
    expect(find.text(ja.reviewClosingTitle), findsOneWidget);
    expect(find.text(yearClosingWords(2026)), findsOneWidget);
    expect(find.text(ja.shareButton), findsOneWidget);
  });

  testWidgets('表紙で記録のある別の年に切り替えられる', (tester) async {
    await pump(tester, const YearReviewScreen(year: 2026));

    await tester.tap(find.text(ja.reviewYearOption(2025)));
    await tester.pumpAndSettle();

    expect(find.text(ja.reviewEntry(2025)), findsOneWidget);
    expect(find.text(ja.reviewCoverEra('令和', '七')), findsOneWidget);
  });

  testWidgets('記録の無い年は表紙だけ', (tester) async {
    await pump(tester, const YearReviewScreen(year: 2024));

    expect(find.text(ja.reviewCoverEmpty), findsOneWidget);
    await next(tester);
    expect(find.text(ja.reviewCoverEmpty), findsOneWidget);
  });

  testWidgets('修行タブの入口は、今年の振り返りを開く', (tester) async {
    await pump(
      tester,
      Scaffold(body: ListView(children: const [YearReviewEntry()])),
    );

    await tester.tap(find.text(ja.reviewEntry(2026)));
    await tester.pumpAndSettle();

    expect(find.text(ja.reviewCoverYear(2026)), findsWidgets);
  });

  testWidgets('記録が無いうちは、修行タブに入口を出さない', (tester) async {
    await pump(
      tester,
      Scaffold(body: ListView(children: const [YearReviewEntry()])),
      entries: const [],
    );

    expect(find.byType(ListTile), findsNothing);
  });

  group('一覧の上の案内', () {
    Widget card() =>
        Scaffold(body: ListView(children: const [YearReviewInviteCard()]));

    testWidgets('12月はその年の振り返りを勧める', (tester) async {
      await pump(tester, card(), now: DateTime(2026, 12, 1));

      expect(find.text(ja.reviewInvite(2026)), findsOneWidget);

      await tester.tap(find.byTooltip(ja.reviewDismiss));
      await tester.pumpAndSettle();
      expect(find.text(ja.reviewInvite(2026)), findsNothing);
    });

    testWidgets('1月は前の年の振り返りを勧める', (tester) async {
      await pump(tester, card(), now: DateTime(2027, 1, 31));

      expect(find.text(ja.reviewInvite(2026)), findsOneWidget);
    });

    testWidgets('12月・1月のほかには出さない', (tester) async {
      await pump(tester, card(), now: DateTime(2026, 11, 30));

      expect(find.byType(Card), findsNothing);
    });

    testWidgets('記録の無い年には出さない', (tester) async {
      await pump(tester, card(), now: DateTime(2028, 1, 10));

      expect(find.byType(Card), findsNothing);
    });
  });
}
