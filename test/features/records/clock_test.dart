import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/clock.dart';

void main() {
  testWidgets('「今」は1分ごとと、アプリに戻ってきたときに更新する', (tester) async {
    var now = DateTime(2026, 12, 31, 23, 59);
    final container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    container.listen(currentTimeProvider, (_, _) {});

    expect(container.read(currentTimeProvider), DateTime(2026, 12, 31, 23, 59));

    now = DateTime(2027, 1, 1, 0, 0);
    await tester.pump(const Duration(minutes: 1));
    expect(container.read(currentTimeProvider).year, 2027);

    now = DateTime(2027, 1, 1, 8, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(container.read(currentTimeProvider), DateTime(2027, 1, 1, 8, 0));

    // 1分ごとの更新を止めるため、テストの終わりを待たずに破棄する。
    container.dispose();
  });
}
