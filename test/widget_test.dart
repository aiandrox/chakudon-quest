import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/checkin/checkin_controller.dart';
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

  testWidgets('下のタブでクエストの一覧に切り替えられる', (tester) async {
    await pumpApp(tester, const []);

    await tester.tap(find.text(ja.navQuests));
    await tester.pumpAndSettle();

    expect(find.text(ja.questSummary(0, 8)), findsOneWidget);
    expect(find.text('はじめての着丼'), findsOneWidget);
  });

  testWidgets('記録があるときは店名・★・ポイントと、ランクを表示する', (tester) async {
    final shop = Shop(
      id: 'shop',
      name: '麺屋テスト',
      hoursType: HoursType.normal,
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
}
