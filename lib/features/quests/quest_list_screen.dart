import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../records/date_format.dart';
import '../scoring/scoring_providers.dart';
import 'quest_seal.dart';
import 'quests.dart';

class QuestListScreen extends ConsumerWidget {
  const QuestListScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.questTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
      ),
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
    final previous = progress.level == 0
        ? 0
        : quest.thresholds[progress.level - 1];
    final achievedAt = progress.levelAchievedAt.lastOrNull;

    return Card(
      elevation: 0,
      color: progress.isAchieved
          ? colors.surfaceContainerHigh
          : colors.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestSeal(quest: quest, level: progress.level),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(quest.description, style: textTheme.bodyMedium),
                  if (!isSpot && next != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (progress.current - previous) / (next - previous),
                      minHeight: 4,
                      color: Washi.ink,
                      backgroundColor: Washi.line.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.questNext(progress.current, next, quest.unit),
                      style: textTheme.bodySmall,
                    ),
                  ],
                  if (!isSpot && next == null)
                    Text(
                      '${l10n.questMaxLevel}  '
                      '${l10n.questCount(progress.current, quest.unit)}',
                      style: textTheme.bodySmall,
                    ),
                  if (achievedAt != null)
                    Text(
                      l10n.questAchievedOn(formatDate(achievedAt)),
                      style: textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
