import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../notifications/notification_service.dart';
import '../quests/quests.dart';
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
          _RankUpBanner(rankName: adventurerRankLabel(l10n, outcome.rankAfter)),
        ],
        for (final quest in outcome.achievedQuests) ...[
          const SizedBox(height: 16),
          _QuestAchievedBanner(quest: quest),
        ],
        const SizedBox(height: 24),
        RankProgress(totalPoints: outcome.totalAfter),
      ],
    );
  }
}

class _RankUpBanner extends StatelessWidget {
  const _RankUpBanner({required this.rankName});

  final String rankName;

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
        color: colors.tertiaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.military_tech,
                size: 48,
                color: colors.onTertiaryContainer,
              ),
              Text(
                l10n.rankUp,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onTertiaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                rankName,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestAchievedBanner extends StatelessWidget {
  const _QuestAchievedBanner({required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.secondaryContainer,
      child: ListTile(
        leading: Icon(Icons.emoji_events, color: colors.onSecondaryContainer),
        title: Text(
          l10n.questAchieved,
          style: textTheme.labelLarge?.copyWith(
            color: colors.onSecondaryContainer,
          ),
        ),
        subtitle: Text(
          quest.title,
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
