import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../records/date_format.dart';
import '../scoring/scoring_providers.dart';
import 'quests.dart';

class QuestListScreen extends ConsumerWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final quests = ref.watch(questProgressProvider);
    final achieved = quests
        .where((progress) => progress.status == QuestStatus.achieved)
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.questTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(
            l10n.questSummary(achieved, quests.length),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final progress in quests) _QuestCard(progress: progress),
        ],
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
    final status = progress.status;
    final isAchieved = status == QuestStatus.achieved;
    final achievedAt = progress.achievedAt;

    return Card(
      elevation: 0,
      color: isAchieved
          ? colors.secondaryContainer
          : colors.surfaceContainerLow,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isAchieved ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: isAchieved ? colors.primary : colors.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(quest.title, style: textTheme.titleMedium),
                      ),
                      Text(
                        _statusLabel(l10n, status),
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(quest.condition, style: textTheme.bodyMedium),
                  if (isAchieved && achievedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.questAchievedOn(formatDate(achievedAt)),
                      style: textTheme.bodySmall,
                    ),
                  ],
                  if (!isAchieved && quest.target > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.current / quest.target,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.questProgress(progress.current, quest.target),
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, QuestStatus status) =>
      switch (status) {
        QuestStatus.achieved => l10n.questStatusAchieved,
        QuestStatus.inProgress => l10n.questStatusInProgress,
        QuestStatus.notStarted => l10n.questStatusNotStarted,
      };
}
