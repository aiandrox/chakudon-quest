import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/checkin/checkin_controller.dart';
import 'package:chakudon_quest/features/map/map_screen.dart';
import 'package:chakudon_quest/features/notifications/notification_service.dart';
import 'package:chakudon_quest/features/record/photo_picker.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/main.dart';

import 'support/fakes.dart';
import 'support/l10n.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, List<VisitWithShop> visits) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          activeCheckinProvider.overrideWithValue(const AsyncData(null)),
          documentsDirectoryProvider.overrideWithValue(createTempDirectory()),
          photoPickerProvider.overrideWithValue(FakePhotoPicker()),
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
    expect(find.text(ja.checkinButton), findsOneWidget);
  });

  testWidgets('下のタブでクエスト・統計・地図に切り替えられる。地図は開いたときだけ作る', (tester) async {
    await pumpApp(tester, const []);

    await tester.tap(find.text(ja.navQuests));
    await tester.pumpAndSettle();

    expect(find.text(ja.questSummary(0, 8)), findsOneWidget);
    expect(find.text('はじめての着丼'), findsOneWidget);

    await tester.tap(find.text(ja.navStats));
    await tester.pumpAndSettle();

    expect(find.text(ja.statsEmpty), findsOneWidget);
    expect(find.byType(MapScreen), findsNothing);

    await tester.tap(find.text(ja.navMap));
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.text(ja.mapEmpty), findsOneWidget);
  });

  testWidgets('記録があるときは店名・★・ポイントと、ランクを表示する', (tester) async {
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

    expect(find.text('麺屋テスト'), findsOneWidget);
    // 初訪問の1杯は 10 + 10 = 20点。
    expect(find.text('2026/9/30  ★4  +20 pt'), findsOneWidget);
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
    expect(find.textContaining(ja.ratingUnrated), findsOneWidget);

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
    final notifications = FakeNotificationService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(const AsyncData([])),
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
}
