import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../records/clock.dart';
import '../records/labels.dart';
import '../scoring/rank_labels.dart';
import '../scoring/ranks.dart';
import '../scoring/scoring_providers.dart';
import 'stats.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scored = ref.watch(scoredVisitsProvider);
    final total = totalBowls(scored);
    final thisYear = bowlsInYear(scored, ref.watch(clockProvider)().year);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: total == 0
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
                const SizedBox(height: 24),
                Text(l10n.statsStyles, style: textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final share in styleShares(scored))
                  _StyleRow(share: share),
                const SizedBox(height: 24),
                Text(l10n.statsFrequent, style: textTheme.titleMedium),
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
                Text(l10n.statsShopRanks, style: textTheme.titleMedium),
                Text(l10n.statsShopRanksNote, style: textTheme.bodySmall),
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
            Text(value, style: textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

class _StyleRow extends StatelessWidget {
  const _StyleRow({required this.share});

  final StyleShare share;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final style = share.style;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              style == null ? l10n.styleUnset : styleLabel(l10n, style),
              style: textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: share.ratio, minHeight: 12),
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              '${l10n.bowls(share.count)}  '
              '${l10n.percent((share.ratio * 100).round())}',
              style: textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final ShopRank rank;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTop = rank == ShopRank.s;
    return CircleAvatar(
      radius: 16,
      backgroundColor: isTop ? colors.primary : colors.secondaryContainer,
      foregroundColor: isTop ? colors.onPrimary : colors.onSecondaryContainer,
      child: Text(
        shopRankLabel(rank),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
