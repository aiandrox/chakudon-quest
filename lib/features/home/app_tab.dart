import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 下のタブ。並びは画面の左から（真ん中の判子を除く）。
enum AppTab { records, wishes, shugyo, map }

final appTabProvider = NotifierProvider<AppTabNotifier, AppTab>(
  AppTabNotifier.new,
);

class AppTabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.records;

  void select(AppTab tab) => state = tab;
}
