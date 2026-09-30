import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/emblem.dart';
import '../quests/quest_visuals.dart';
import 'rank_labels.dart';
import 'ranks.dart';

/// 冒険者ランクと累計ポイント、次のランクまでの進み具合。
class RankProgress extends StatelessWidget {
  const RankProgress({super.key, required this.totalPoints});

  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rank = adventurerRankFor(totalPoints);
    final next = rank.next;
    final progress = next == null
        ? 1.0
        : (totalPoints - rank.requiredPoints) /
              (next.requiredPoints - rank.requiredPoints);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Emblem(icon: rankIcon(rank), tier: rankTier(rank), size: 36),
            const SizedBox(width: 8),
            Expanded(
              child: TitleLogo(
                adventurerRankLabel(l10n, rank),
                tier: rankTier(rank),
              ),
            ),
            Text(l10n.totalPoints(totalPoints), style: textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 8),
        ),
        const SizedBox(height: 4),
        Text(
          next == null
              ? l10n.maxRank
              : l10n.nextRank(
                  adventurerRankLabel(l10n, next),
                  next.requiredPoints - totalPoints,
                ),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
