import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/main.dart';

import 'support/l10n.dart';

void main() {
  testWidgets('起動すると最初の画面が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ChakudonQuestApp()));
    await tester.pumpAndSettle();

    expect(find.text(ja.appName), findsOneWidget);
    expect(find.text(ja.homeEmpty), findsOneWidget);
  });
}
