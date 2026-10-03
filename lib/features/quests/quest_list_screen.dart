import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../scoring/scoring_providers.dart';
import 'quest_seal.dart';
import 'quests.dart';

/// 型と奥義の一覧。修行タブの中に並べる。
class QuestSections extends ConsumerWidget {
  const QuestSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final all = ref.watch(questProgressProvider);
    final standing = [
      for (final progress in all)
        if (progress.quest.kind == QuestKind.standing) progress,
    ];
    final spot = [
      for (final progress in all)
        if (progress.quest.kind == QuestKind.spot) progress,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: l10n.questStanding,
          summary: l10n.questLevelTotal(
            standing.fold(0, (sum, progress) => sum + progress.level),
          ),
        ),
        for (final progress in standing) _QuestCard(progress: progress),
        const SizedBox(height: 24),
        _SectionHeader(
          title: l10n.questSpot,
          summary: l10n.questSpotSummary(
            spot.where((progress) => progress.isAchieved).length,
            spot.length,
          ),
        ),
        for (final progress in spot) _QuestCard(progress: progress),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.summary});

  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: SectionTitle(
        title,
        trailing: Text(summary, style: textTheme.titleSmall),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.progress});

  final QuestProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final quest = progress.quest;
    final isSpot = quest.kind == QuestKind.spot;
    final next = progress.nextThreshold;
    final count = isSpot
        ? null
        : next == null
        ? l10n.questMaxLevel
        : l10n.questNext(progress.current, next, quest.unit);

    // 印・名前・数だけ。会得した日などは出さない。
    return Card(
      elevation: 0,
      color: progress.isAchieved
          ? colors.surfaceContainerHigh
          : colors.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        child: Row(
          children: [
            QuestSeal(quest: quest, level: progress.level, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontFamily: Washi.brush,
                    ),
                  ),
                  Text(
                    quest.description,
                    style: textTheme.bodySmall?.copyWith(color: Washi.inkSoft),
                  ),
                ],
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Text(
                count,
                style: textTheme.bodyMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
