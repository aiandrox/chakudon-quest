import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/clock.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/wishes/wish_list_screen.dart';
import 'package:chakudon_quest/features/wishes/wish_repository.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';
import '../../support/l10n.dart';

void main() {
  testWidgets('まだの願と叶った願を分けて見せ、＋で店名から願を掛けられる', (tester) async {
    final repository = FakeWishRepository();
    final shop = buildShop(id: 'shop', name: 'はやし田');
    final eaten = buildEntry(shop: shop, eatenAt: DateTime(2026, 10, 3, 12));
    final wishes = [
      Wish(
        id: 'a',
        shopId: 'shop',
        name: 'はやし田',
        trigger: '同僚に聞いた',
        createdAt: DateTime(2026, 9, 1),
        fulfilledVisitId: eaten.visit.id,
      ),
      Wish(
        id: 'b',
        name: '麺屋藤ろう',
        note: '煮干し',
        createdAt: DateTime(2026, 9, 28),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wishRepositoryProvider.overrideWithValue(repository),
          wishesProvider.overrideWithValue(AsyncData(wishes)),
          visitsProvider.overrideWithValue(AsyncData([eaten])),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 3, 18)),
        ],
        child: localizedApp(home: const WishListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(ja.wishPendingTab(1)), findsOneWidget);
    expect(find.text(ja.wishFulfilledTab(1)), findsOneWidget);
    expect(find.text('麺屋藤ろう'), findsOneWidget);
    expect(find.text(ja.wishSinceDays(5)), findsOneWidget);

    await tester.tap(find.text(ja.wishFulfilledTab(1)));
    await tester.pumpAndSettle();
    expect(find.text('はやし田'), findsOneWidget);
    expect(find.text(ja.wishFulfilledLine('2026/10/3', 32)), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '豚山');
    await tester.pump();
    await tester.tap(find.text(ja.wishAddButton).last);
    await tester.pumpAndSettle();

    expect(repository.added.single.name, '豚山');
    expect(find.text(ja.wishAdded('豚山')), findsOneWidget);
  });
}
