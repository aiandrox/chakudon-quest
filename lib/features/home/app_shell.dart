import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../quests/quest_list_screen.dart';
import '../stats/stats_screen.dart';
import 'home_screen.dart';

/// 下のタブ（記録・クエスト・統計）で画面を切り替える、アプリの外枠。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomeScreen(), QuestListScreen(), StatsScreen()],
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
        ],
      ),
    );
  }
}
