import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/map/map_screen.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';

import '../../support/builders.dart';
import '../../support/l10n.dart';

void main() {
  testWidgets('位置のわかる店が無いときは、地図の代わりに案内を出す', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(
            AsyncData([buildEntry(shop: buildShop(id: 'no-location'))]),
          ),
        ],
        child: localizedApp(home: const MapScreen()),
      ),
    );
    await tester.pump();

    expect(find.text(ja.mapTitle), findsOneWidget);
    expect(find.text(ja.mapEmpty), findsOneWidget);
  });
}
