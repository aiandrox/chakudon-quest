import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/checkin/checkin_controller.dart';
import 'package:chakudon_quest/features/map/map_screen.dart';
import 'package:chakudon_quest/features/notifications/notification_service.dart';
import 'package:chakudon_quest/features/record/photo_picker.dart';
import 'package:chakudon_quest/features/records/clock.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/wishes/wish_repository.dart';
import 'package:chakudon_quest/features/inkan/inkan_stamp.dart';
import 'package:chakudon_quest/main.dart';
import 'package:chakudon_quest/theme/washi.dart';

import 'support/fakes.dart';
import 'support/l10n.dart';

Finder verticalText(String text) => find.byWidgetPredicate(
  (widget) => widget is VerticalText && widget.text == text,
);

void main() {
  late FakeNotificationService notifications;

  setUp(() => notifications = FakeNotificationService());

  Future<void> pumpApp(
    WidgetTester tester,
    List<VisitWithShop> visits, {
    DateTime? now,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          wishesProvider.overrideWithValue(const AsyncData([])),
          activeCheckinProvider.overrideWithValue(const AsyncData(null)),
          documentsDirectoryProvider.overrideWithValue(createTempDirectory()),
          photoPickerProvider.overrideWithValue(FakePhotoPicker()),
          notificationServiceProvider.overrideWithValue(notifications),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
          if (now != null) clockProvider.overrideWithValue(() => now),
        ],
        child: const ChakudonQuestApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('記録が無いときは最初の記録を促す', (tester) async {
    await pumpApp(tester, const []);

    expect(find.text(ja.appName), findsOneWidget);
    expect(find.text(ja.homeEmpty), findsOneWidget);
    expect(find.byTooltip(ja.addRecord), findsOneWidget);
  });

  testWidgets('下のタブで修行・地図に切り替えられる。地図は開いたときだけ作る', (tester) async {
    await pumpApp(tester, const []);

    await tester.tap(find.text(ja.navShugyo));
    await tester.pumpAndSettle();

    expect(find.text(ja.questStanding), findsOneWidget);
    expect(find.text('着丼の道'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(ja.statsEmpty), 300);
    expect(find.text(ja.statsEmpty), findsOneWidget);
    await tester.scrollUntilVisible(find.text(ja.backupTitle), 300);
    expect(find.text(ja.creditsTitle), findsOneWidget);
    expect(find.byType(MapScreen), findsNothing);

    await tester.tap(find.text(ja.navMap));
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text(ja.mapEmpty), findsOneWidget);
  });

  testWidgets('記録があるときは店名と印、段位と修行点を表示する', (tester) async {
    final shop = Shop(
      id: 'shop',
      name: '麺屋テスト',
      hoursConditions: const {},
      createdAt: DateTime(2026, 9, 30),
    );
    await pumpApp(tester, [
      VisitWithShop(
        shop: shop,
        visit: Visit(
          id: 'visit',
          shopId: 'shop',
          result: VisitResult.eaten,
          eatenAt: DateTime(2026, 9, 30, 12, 34),
          rating: 4,
          isLimited: false,
          hasTicket: false,
          memo: '',
          createdAt: DateTime(2026, 9, 30, 12, 40),
        ),
      ),
    ]);

    expect(verticalText('麺屋テスト'), findsOneWidget);
    expect(find.byType(InkanStamp), findsOneWidget);
    expect(find.text(ja.rankApprentice), findsOneWidget);
    expect(find.text(ja.totalPoints(20)), findsOneWidget);
    expect(find.text(ja.homeEmpty), findsNothing);
  });

  testWidgets('食べてから12時間以内で★の無い記録は、一覧の上で評価を促す', (tester) async {
    final shop = Shop(
      id: 'shop',
      name: '麺屋テスト',
      hoursConditions: const {},
      createdAt: DateTime(2026, 9, 30),
    );
    Visit visit(String id, DateTime eatenAt) => Visit(
      id: id,
      shopId: 'shop',
      result: VisitResult.eaten,
      eatenAt: eatenAt,
      isLimited: false,
      hasTicket: false,
      memo: '',
      createdAt: eatenAt,
    );
    final now = DateTime.now();
    await pumpApp(tester, [
      VisitWithShop(
        shop: shop,
        visit: visit('recent', now.subtract(const Duration(hours: 1))),
      ),
    ]);

    expect(find.text(ja.ratingPrompt('麺屋テスト')), findsOneWidget);

    await pumpApp(tester, [
      VisitWithShop(
        shop: shop,
        visit: visit('old', now.subtract(const Duration(hours: 13))),
      ),
    ]);

    expect(find.text(ja.ratingPrompt('麺屋テスト')), findsNothing);
  });

  testWidgets('並んでいる間だけ通知を出し、並び終えたら消す', (tester) async {
    final checkins = StreamController<Checkin?>();
    addTearDown(checkins.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(const AsyncData([])),
          wishesProvider.overrideWithValue(const AsyncData([])),
          activeCheckinProvider.overrideWith((ref) => checkins.stream),
          documentsDirectoryProvider.overrideWithValue(createTempDirectory()),
          photoPickerProvider.overrideWithValue(FakePhotoPicker()),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const ChakudonQuestApp(),
      ),
    );

    // 起動時に並んでいなければ、前回の通知が残っていないよう消す。
    checkins.add(null);
    await tester.pumpAndSettle();
    expect(notifications.shown, isEmpty);
    expect(notifications.cancelCount, 1);

    checkins.add(
      Checkin(name: '麺屋テスト', checkedInAt: DateTime(2026, 10, 1, 11)),
    );
    await tester.pumpAndSettle();
    expect(notifications.shown, [ja.checkinBanner('麺屋テスト')]);

    checkins.add(null);
    await tester.pumpAndSettle();
    expect(notifications.cancelCount, 2);

    checkins.addError(StateError('db'));
    await tester.pumpAndSettle();
    expect(notifications.cancelCount, 3);
  });

  group('連続記録', () {
    // 2026-10-01 は木曜。
    final thursday = DateTime(2026, 10, 1, 12);
    final shop = Shop(id: 'shop', name: '麺屋テスト', createdAt: DateTime(2026));
    VisitWithShop eatenAt(DateTime at) => VisitWithShop(
      shop: shop,
      visit: Visit(
        id: at.toIso8601String(),
        shopId: 'shop',
        result: VisitResult.eaten,
        eatenAt: at,
        rating: 3,
        isLimited: false,
        hasTicket: false,
        memo: '',
        createdAt: at,
      ),
    );

    testWidgets('今週まだ食べていなければ「今週はまだ」と出し、日曜18時に知らせる', (tester) async {
      await pumpApp(tester, [
        eatenAt(DateTime(2026, 9, 22, 12)),
        eatenAt(DateTime(2026, 9, 15, 12)),
      ], now: thursday);
      await tester.tap(find.text(ja.navShugyo));
      await tester.pumpAndSettle();

      expect(find.text(ja.streakWeeks(2)), findsOneWidget);
      expect(find.text(ja.streakAtRisk), findsOneWidget);
      expect(notifications.streakReminders, [DateTime(2026, 10, 4, 18)]);
    });

    testWidgets('今週すでに食べていれば、来週の日曜18時に知らせる予約をしておく', (tester) async {
      await pumpApp(tester, [
        eatenAt(DateTime(2026, 9, 30, 12)),
        eatenAt(DateTime(2026, 9, 22, 12)),
      ], now: thursday);
      await tester.tap(find.text(ja.navShugyo));
      await tester.pumpAndSettle();

      expect(find.text(ja.streakWeeks(2)), findsOneWidget);
      expect(find.text(ja.streakAtRisk), findsNothing);
      expect(notifications.streakReminders, [DateTime(2026, 10, 11, 18)]);
    });

    testWidgets('連続記録が無ければ表示せず、知らせる予約も消す', (tester) async {
      await pumpApp(tester, [eatenAt(DateTime(2026, 9, 1, 12))], now: thursday);
      await tester.tap(find.text(ja.navShugyo));
      await tester.pumpAndSettle();

      expect(find.textContaining('週連続'), findsNothing);
      expect(notifications.streakReminders, isEmpty);
      expect(notifications.streakCancelCount, greaterThan(0));
    });
  });
}
