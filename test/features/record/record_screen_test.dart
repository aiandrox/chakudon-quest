import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/database/app_database.dart';
import 'package:chakudon_quest/features/record/photo_picker.dart';
import 'package:chakudon_quest/features/record/record_result_screen.dart';
import 'package:chakudon_quest/features/record/record_screen.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/overpass_client.dart';

import '../../support/fakes.dart';
import '../../support/l10n.dart';

void main() {
  late AppDatabase database;
  late FakeOverpassClient overpass;

  Future<void> pumpScreen(WidgetTester tester) async {
    database = createTestDatabase();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          // driftの監視はテストの偽の時間の中で止まってしまうため、一覧は固定の値にする。
          visitsProvider.overrideWithValue(const AsyncData([])),
          documentsDirectoryProvider.overrideWithValue(createTempDirectory()),
          locationServiceProvider.overrideWithValue(
            FakeLocationService(position: const GeoPoint(35.0, 139.0)),
          ),
          overpassClientProvider.overrideWithValue(overpass),
          photoPickerProvider.overrideWithValue(FakePhotoPicker()),
        ],
        child: localizedApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(builder: (_) => const RecordScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    overpass = FakeOverpassClient(
      shops: const [
        OverpassShop(
          osmId: 'node/1',
          name: '麺屋テスト',
          location: GeoPoint(35.001, 139.0),
        ),
      ],
    );
  });

  testWidgets('候補の店と出典を表示し、店と★を選ぶと「着丼！」で保存して結果を見せる', (tester) async {
    await pumpScreen(tester);

    expect(find.text('麺屋テスト'), findsOneWidget);
    expect(find.text('111m'), findsOneWidget);
    expect(find.text(ja.osmAttribution), findsOneWidget);
    final saveButton = find.widgetWithText(FilledButton, ja.save);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.tap(find.text('麺屋テスト'));
    await tester.pump();
    // ★は食べ終わってから付けることが多いため、店が決まれば保存できる。
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.tap(find.byTooltip(ja.ratingStar(4)));
    await tester.pump();

    await tester.runAsync(() async {
      await tester.tap(saveButton);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    // 結果の画面は読み込み中の表示が回り続けるため、一定時間だけ進める。
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RecordScreen), findsNothing);
    expect(find.byType(RecordResultScreen), findsOneWidget);
    final visits = await tester.runAsync(
      () => RecordRepository(database).watchVisits().first,
    );
    expect(visits!.single.shop.name, '麺屋テスト');
    expect(visits.single.visit.rating, 4);
  });

  testWidgets('検索に失敗しても、店名を入力して保存できる', (tester) async {
    overpass.error = const SocketException('offline');
    await pumpScreen(tester);

    expect(find.text(ja.shopSearchFailed), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '電波のない店');
    await tester.tap(find.byTooltip(ja.ratingStar(3)));
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, ja.save);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('入力があるときに戻ろうとすると確認し、「続ける」なら残る', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byTooltip(ja.ratingStar(3)));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(ja.discardTitle), findsOneWidget);

    await tester.tap(find.text(ja.discardCancel));
    await tester.pumpAndSettle();
    expect(find.byType(RecordScreen), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(ja.discardConfirm));
    await tester.pumpAndSettle();
    expect(find.byType(RecordScreen), findsNothing);
  });

  testWidgets('何も入力していなければ確認なしで戻れる', (tester) async {
    await pumpScreen(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(ja.discardTitle), findsNothing);
    expect(find.byType(RecordScreen), findsNothing);
  });
}
