import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../notifications/notification_service.dart';
import '../../theme/emblem.dart';
import '../quests/quest_visuals.dart';
import '../quests/quests.dart';
import '../scoring/ranks.dart';
import '../records/record_repository.dart';
import '../scoring/points_breakdown_view.dart';
import '../scoring/rank_labels.dart';
import '../scoring/rank_progress.dart';
import '../scoring/record_outcome.dart';

/// 保存した記録で得たポイントの内訳と、累計・ランクの変化を見せる。
class RecordResultScreen extends ConsumerStatefulWidget {
  const RecordResultScreen({super.key, required this.visitId});

  final String visitId;

  @override
  ConsumerState<RecordResultScreen> createState() => _RecordResultScreenState();
}

class _RecordResultScreenState extends ConsumerState<RecordResultScreen> {
  /// 最初に求めた結果を持ち続ける。表示中に記録が変わっても、演出をやり直さないため。
  RecordOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    // 連続記録が途切れそうなときに知らせるため、記録したこのときに通知の許可を尋ねる。
    ref.read(notificationServiceProvider).requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visitsState = ref.watch(visitsProvider);
    final visits = visitsState.value;
    _outcome ??= visits == null
        ? null
        : computeRecordOutcome(visits, widget.visitId);
    final outcome = _outcome;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.resultTitle),
      ),
      body: switch (outcome) {
        final outcome? => _ResultBody(outcome: outcome),
        null when visitsState.hasError => Center(
          child: Text(l10n.homeLoadFailed),
        ),
        null => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.resultOk),
        ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.outcome});

  final RecordOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final scored = outcome.scored;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text(
          scored.shop.name,
          style: textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: scored.points.total.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => Text(
            l10n.pointsGained(value.round()),
            style: textTheme.displayMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PointsBreakdownView(scored: scored),
          ),
        ),
        if (outcome.isRankUp) ...[
          const SizedBox(height: 16),
          _RankUpBanner(rank: outcome.rankAfter),
        ],
        for (final levelUp in outcome.questLevelUps) ...[
          const SizedBox(height: 12),
          _QuestAchievedBanner(levelUp: levelUp),
        ],
        const SizedBox(height: 24),
        RankProgress(totalPoints: outcome.totalAfter),
      ],
    );
  }
}

class _RankUpBanner extends StatelessWidget {
  const _RankUpBanner({required this.rank});

  final AdventurerRank rank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Card(
        elevation: 0,
        color: colors.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(l10n.rankUp, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Emblem(icon: rankIcon(rank), tier: rankTier(rank), size: 96),
              const SizedBox(height: 8),
              TitleLogo(
                adventurerRankLabel(l10n, rank),
                tier: rankTier(rank),
                fontSize: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestAchievedBanner extends StatelessWidget {
  const _QuestAchievedBanner({required this.levelUp});

  final QuestLevelUp levelUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final quest = levelUp.quest;
    final isSpot = quest.kind == QuestKind.spot;

    return Card(
      elevation: 0,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Emblem(
              icon: questIcon(quest),
              tier: questTier(quest, levelUp.level),
              size: 56,
              label: isSpot
                  ? l10n.questCleared
                  : l10n.questLevel(levelUp.level),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSpot ? l10n.questAchieved : l10n.questLevelUp,
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    isSpot
                        ? quest.title
                        : l10n.questLevelReached(quest.title, levelUp.level),
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
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
