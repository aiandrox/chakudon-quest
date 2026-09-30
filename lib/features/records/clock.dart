import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// 画面に出す「今」。1分ごとと、アプリに戻ってきたときに更新する。
/// 開いたまま日付や年をまたいでも、「今年の杯数」や評価の案内が古いままにならないようにする。
final currentTimeProvider = NotifierProvider<CurrentTime, DateTime>(
  CurrentTime.new,
);

class CurrentTime extends Notifier<DateTime> {
  @override
  DateTime build() {
    final clock = ref.watch(clockProvider);
    final timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => state = clock(),
    );
    final lifecycle = AppLifecycleListener(onResume: () => state = clock());
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
    return clock();
  }
}
