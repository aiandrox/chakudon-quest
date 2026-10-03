import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../onboarding/onboarding_screen.dart';
import '../../theme/washi.dart';
import '../backup/backup_screen.dart';
import '../credits/credits_screen.dart';
import '../journal/shugyoroku_screen.dart';
import '../map/home_base_line.dart';
import '../quests/quest_list_screen.dart';
import '../review/year_review_entry.dart';
import '../scoring/rank_progress.dart';
import '../scoring/scoring_providers.dart';
import '../stats/stats_screen.dart';
import '../streak/healthy_life_card.dart';
import '../streak/streak_line.dart';

/// 修行の記録をひとまとめにした画面。段位 → 型と秘伝 → 数字 → 設定の順に並べる。
class ShugyoScreen extends ConsumerWidget {
  const ShugyoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shugyoTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          RankProgress(
            totalPoints: ref.watch(totalPointsProvider),
            rank: ref.watch(currentRankProvider),
          ),
          const StreakLine(),
          const HealthyLifeCard(),
          const HomeBaseLine(),
          const SizedBox(height: 24),
          const QuestSections(),
          const SizedBox(height: 32),
          SectionTitle(l10n.shugyorokuTitle),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.shugyorokuOpen),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const ShugyorokuScreen()),
          ),
          const YearReviewEntry(),
          const SizedBox(height: 32),
          const StatsSections(),
          const SizedBox(height: 32),
          SectionTitle(l10n.settingsSection),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.backupTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const BackupScreen()),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.creditsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const CreditsScreen()),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.onboardingReplay),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => open(const OnboardingScreen()),
          ),
        ],
      ),
    );
  }
}
