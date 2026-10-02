import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../records/clock.dart';
import '../records/date_format.dart';
import '../records/labels.dart';
import '../records/record_repository.dart';
import '../scoring/rank_labels.dart';
import '../scoring/ranks.dart';
import '../scoring/scoring_providers.dart';
import 'stats.dart';
import '../records/models.dart';
import '../../theme/washi.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final visits = ref.watch(visitsProvider);
    final scored = ref.watch(scoredVisitsProvider);
    final total = totalBowls(scored);
    final thisYear = bowlsInYear(scored, ref.watch(currentTimeProvider).year);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: visits.hasError
          ? Center(child: Text(l10n.homeLoadFailed))
          : visits.isLoading && !visits.hasValue
          ? const Center(child: CircularProgressIndicator())
          : total == 0
          ? Center(child: Text(l10n.statsEmpty))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CountCard(
                        label: l10n.statsThisYear,
                        value: l10n.bowls(thisYear),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CountCard(
                        label: l10n.statsTotal,
                        value: l10n.bowls(total),
                      ),
                    ),
                  ],
                ),
                ..._bests(l10n, textTheme, personalBests(scored)),
                const SizedBox(height: 24),
                SectionTitle(l10n.statsStyles),
                _StyleBreakdown(shares: styleShares(scored)),
                const SizedBox(height: 24),
                SectionTitle(l10n.statsFrequent),
                for (final frequent in frequentShops(scored))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(Icons.storefront),
                    title: Text(frequent.shop.name),
                    trailing: Text(
                      l10n.bowls(frequent.count),
                      style: textTheme.bodyLarge,
                    ),
                  ),
                const SizedBox(height: 24),
                SectionTitle(l10n.statsShopRanks),
                for (final ranked in rankedShops(scored))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: _RankBadge(rank: ranked.rank),
                    title: Text(ranked.shop.name),
                    trailing: Text(
                      l10n.statsBestPoints(ranked.bestPoints),
                      style: textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
    );
  }
}

List<Widget> _bests(
  AppLocalizations l10n,
  TextTheme textTheme,
  PersonalBests bests,
) {
  ListTile row(IconData icon, String label, PersonalBest best, String value) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(
          l10n.bestDetail(
            best.entry.shop.name,
            formatDate(best.entry.visit.eatenAt),
          ),
        ),
        trailing: Text(value, style: textTheme.titleMedium),
      );
  final rows = [
    if (bests.longestWait case final best?)
      row(
        Icons.hourglass_bottom,
        l10n.bestLongestWait,
        best,
        l10n.minutes(best.value),
      ),
    if (bests.highestPoints case final best?)
      row(Icons.star, l10n.bestHighestPoints, best, l10n.points(best.value)),
    if (bests.mostRetreats case final best?)
      row(
        Icons.shield,
        l10n.bestMostRetreats,
        best,
        l10n.retreatCount(best.value),
      ),
  ];
  if (rows.isEmpty) return const [];
  return [const SizedBox(height: 24), SectionTitle(l10n.statsBests), ...rows];
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.headlineMedium?.copyWith(
                fontFamily: Washi.brush,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 系統ごとの色。隣り合っても見分けやすいよう、明るさも変えた和の色にする。
Color styleColor(RamenStyle? style) => switch (style) {
  RamenStyle.shoyu => const Color(0xFF6B3A22),
  RamenStyle.miso => const Color(0xFFB4793A),
  RamenStyle.shio => const Color(0xFF7FA7B8),
  RamenStyle.tonkotsu => const Color(0xFFE3C26F),
  RamenStyle.iekei => Washi.shu,
  RamenStyle.jiro => const Color(0xFF3F6B3F),
  RamenStyle.tsukemen => const Color(0xFF2E4A6B),
  RamenStyle.shirunashi => const Color(0xFF7E5A96),
  RamenStyle.other => Washi.faded,
  null => const Color(0xFFD8CDB8),
};

/// 全体を100とした1本の帯を系統ごとに色分けし、下に色・系統・杯数・割合を並べる。
class _StyleBreakdown extends StatelessWidget {
  const _StyleBreakdown({required this.shares});

  final List<StyleShare> shares;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    String label(RamenStyle? style) =>
        style == null ? l10n.styleUnset : styleLabel(l10n, style);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: [
            for (final share in shares)
              '${label(share.style)} ${l10n.percent((share.ratio * 100).round())}',
          ].join('、'),
          child: ExcludeSemantics(
            child: Container(
              height: 28,
              decoration: BoxDecoration(border: Border.all(color: Washi.ink)),
              child: Row(
                children: [
                  for (final (i, share) in shares.indexed)
                    Expanded(
                      flex: share.count,
                      child: Container(
                        decoration: BoxDecoration(
                          color: styleColor(share.style),
                          border: i == 0
                              ? null
                              : const Border(
                                  left: BorderSide(color: Washi.page),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final share in shares)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: styleColor(share.style),
                    border: Border.all(color: Washi.line),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label(share.style), style: textTheme.bodyMedium),
                ),
                Text(l10n.bowls(share.count), style: textTheme.bodyMedium),
                SizedBox(
                  width: 56,
                  child: Text(
                    l10n.percent((share.ratio * 100).round()),
                    style: textTheme.bodyMedium?.copyWith(color: Washi.inkSoft),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final ShopRank rank;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTop = rank == ShopRank.s;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isTop ? Washi.shu : Washi.page,
        border: Border.all(color: Washi.shu, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        shopRankLabel(l10n, rank),
        style: TextStyle(
          fontFamily: Washi.brush,
          fontSize: 18,
          color: isTop ? Washi.page : Washi.shu,
        ),
      ),
    );
  }
}
