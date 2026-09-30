import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../map/map_screen.dart';
import '../quests/quest_list_screen.dart';
import '../stats/stats_screen.dart';
import 'home_screen.dart';

/// 下のタブ（記録・クエスト・統計・地図）で画面を切り替える、アプリの外枠。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _mapIndex = 3;

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const HomeScreen(),
          const QuestListScreen(),
          const StatsScreen(),
          // 地図は開いたときだけ作る。開くたびに全部のピンが入る範囲に合わせ直し、
          // 地図を見ていないときにタイルを取りに行かないようにするため。
          if (_index == _mapIndex)
            const MapScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.ramen_dining),
            label: l10n.navRecords,
          ),
          NavigationDestination(
            icon: const Icon(Icons.emoji_events),
            label: l10n.navQuests,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart),
            label: l10n.navStats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map),
            label: l10n.navMap,
          ),
        ],
      ),
    );
  }
}
