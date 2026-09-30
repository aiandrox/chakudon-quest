import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:chakudon_quest/features/record/star_rating.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/visit_detail/visit_detail_screen.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';
import '../../support/l10n.dart';

void main() {
  late Directory documents;
  late FakeRecordRepository repository;
  final shop = buildShop(name: '麺屋テスト');

  VisitWithShop entry({
    required String id,
    required DateTime eatenAt,
    int rating = 4,
    String memo = '',
    String? photoPath,
  }) => VisitWithShop(
    shop: shop,
    visit: buildVisit(
      id: id,
      eatenAt: eatenAt,
      rating: rating,
      memo: memo,
      photoPath: photoPath,
      style: RamenStyle.shoyu,
      isLimited: true,
    ),
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    List<VisitWithShop> visits,
    String visitId,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          recordRepositoryProvider.overrideWithValue(repository),
          documentsDirectoryProvider.overrideWithValue(documents),
        ],
        child: localizedApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => VisitDetailScreen(visitId: visitId),
                  ),
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

  Finder stars(int rating) => find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.label == ja.ratingStar(rating),
  );

  setUp(() {
    documents = createTempDirectory();
    repository = FakeRecordRepository();
  });

  testWidgets('記録の内容を表示する。初めての店では前回の記録を出さない', (tester) async {
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30, 12, 34), memo: 'スープが濃い'),
    ], 'v');

    expect(find.text('麺屋テスト'), findsWidgets);
    expect(find.text('2026/9/30 12:34'), findsOneWidget);
    expect(tester.widget<StarRating>(find.byType(StarRating)).rating, 4);
    expect(find.text(ja.styleShoyu), findsOneWidget);
    expect(find.text(ja.limitedBadge), findsOneWidget);
    expect(find.text('スープが濃い'), findsOneWidget);
    expect(find.text(ja.previousVisit), findsNothing);
  });

  testWidgets('★の無い記録は、詳細で★をタップして評価できる', (tester) async {
    await pumpDetail(tester, [
      VisitWithShop(
        shop: shop,
        visit: buildVisit(
          id: 'v',
          eatenAt: DateTime(2026, 9, 30),
          rating: null,
        ),
      ),
    ], 'v');

    expect(find.text(ja.ratingTapToRate), findsOneWidget);

    await tester.tap(find.byTooltip(ja.ratingStar(4)));
    await tester.pump();

    expect(repository.ratings, {'v': 4});
  });

  testWidgets('★の保存に失敗したら知らせる', (tester) async {
    repository.ratingError = StateError('db');
    await pumpDetail(tester, [
      VisitWithShop(
        shop: shop,
        visit: buildVisit(
          id: 'v',
          eatenAt: DateTime(2026, 9, 30),
          rating: null,
        ),
      ),
    ], 'v');

    await tester.tap(find.byTooltip(ja.ratingStar(4)));
    await tester.pump();

    expect(find.text(ja.editSaveFailed), findsOneWidget);
  });

  testWidgets('店の攻略メモを表示し、書き直せる', (tester) async {
    await pumpDetail(tester, [
      VisitWithShop(
        shop: buildShop(name: '麺屋テスト', strategyMemo: '券売機は現金のみ'),
        visit: buildVisit(id: 'v', eatenAt: DateTime(2026, 9, 30)),
      ),
    ], 'v');

    expect(find.text('券売機は現金のみ'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip(ja.shopMemoEdit));
    await tester.tap(find.byTooltip(ja.shopMemoEdit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' 開店30分前で1巡目 ');
    await tester.tap(find.text(ja.editSave));
    await tester.pumpAndSettle();

    expect(repository.shopMemos, {'shop': '開店30分前で1巡目'});
  });

  testWidgets('攻略メモが無い店は「まだありません」と出す', (tester) async {
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30)),
    ], 'v');

    expect(find.text(ja.shopMemoEmpty), findsOneWidget);
  });

  testWidgets('同じ店の2回目は、前回の日付・★・メモを表示する', (tester) async {
    await pumpDetail(tester, [
      entry(id: 'second', eatenAt: DateTime(2026, 9, 30, 12), rating: 3),
      entry(
        id: 'first',
        eatenAt: DateTime(2026, 9, 1, 12),
        rating: 5,
        memo: '前回のメモ',
      ),
    ], 'second');

    expect(find.text(ja.previousVisit), findsOneWidget);
    expect(find.text('2026/9/1'), findsOneWidget);
    expect(stars(5), findsOneWidget);
    expect(find.text('前回のメモ'), findsOneWidget);
  });

  testWidgets('削除を確認すると、記録と写真を消して一覧に戻る', (tester) async {
    final photo = File(p.join(documents.path, 'photos', 'a.jpg'))
      ..createSync(recursive: true);
    repository.deletedPhotoPath = 'photos/a.jpg';
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30), photoPath: 'photos/a.jpg'),
    ], 'v');

    await tester.tap(find.byTooltip(ja.delete));
    await tester.pumpAndSettle();
    expect(find.text(ja.deleteConfirmTitle), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, ja.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(VisitDetailScreen), findsOneWidget);
    expect(repository.deletedVisitIds, isEmpty);

    await tester.tap(find.byTooltip(ja.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, ja.delete));
    await tester.pumpAndSettle();
    // ファイルの削除は実時間で進む。
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(find.text(ja.deleteFailed), findsNothing);

    expect(repository.deletedVisitIds, ['v']);
    expect(find.byType(VisitDetailScreen), findsNothing);
    expect(photo.existsSync(), isFalse);
  });

  testWidgets('削除に失敗したら知らせて、画面に残る', (tester) async {
    repository.error = StateError('db');
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30)),
    ], 'v');

    await tester.tap(find.byTooltip(ja.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, ja.delete));
    await tester.pumpAndSettle();

    expect(find.text(ja.deleteFailed), findsOneWidget);
    expect(find.byType(VisitDetailScreen), findsOneWidget);
  });

  testWidgets('編集して保存すると、変更した内容で更新して詳細に戻る', (tester) async {
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30, 12)),
    ], 'v');

    await tester.tap(find.byTooltip(ja.edit));
    await tester.pumpAndSettle();
    expect(find.text(ja.editTitle), findsOneWidget);

    await tester.tap(find.byTooltip(ja.ratingStar(2)));
    await tester.enterText(
      find.widgetWithText(TextField, ja.memoLabel),
      ' 書き直した ',
    );
    final fewDays = find.widgetWithText(FilterChip, ja.hoursFewDays);
    await tester.ensureVisible(fewDays);
    await tester.pumpAndSettle();
    await tester.tap(fewDays);
    await tester.pump();
    final lunchOnly = find.widgetWithText(FilterChip, ja.hoursLunchOnly);
    await tester.ensureVisible(lunchOnly);
    await tester.pumpAndSettle();
    await tester.tap(lunchOnly);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, ja.editSave));
    await tester.pumpAndSettle();

    expect(find.text(ja.editTitle), findsNothing);
    final update = repository.updates.single;
    expect(update.visitId, 'v');
    expect(update.shopName, '麺屋テスト');
    expect(update.rating, 2);
    expect(update.memo, '書き直した');
    expect(update.hoursConditions, {
      HoursCondition.lunchOnly,
      HoursCondition.fewDays,
    });
    expect(update.eatenAt, DateTime(2026, 9, 30, 12));
    expect(update.style, RamenStyle.shoyu);
    expect(update.isLimited, isTrue);
  });

  testWidgets('営業の条件を変えずに保存したときは、変更なしとして渡す', (tester) async {
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30, 12)),
    ], 'v');
    await tester.tap(find.byTooltip(ja.edit));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, ja.editSave));
    await tester.pumpAndSettle();

    expect(repository.updates.single.hoursConditions, isNull);
  });

  testWidgets('店名を空にすると保存できない', (tester) async {
    await pumpDetail(tester, [
      entry(id: 'v', eatenAt: DateTime(2026, 9, 30, 12)),
    ], 'v');
    await tester.tap(find.byTooltip(ja.edit));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, ja.editShopName),
      '  ',
    );
    await tester.pump();

    final saveButton = find.widgetWithText(FilledButton, ja.editSave);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
  });
}
