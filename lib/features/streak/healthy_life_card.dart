import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../scoring/scoring_providers.dart';
import 'daily_streak.dart';

/// 隠し要素「毎日ラーメン健康生活」。7日続けて食べるまでは何も出さず、出現したあとは最高記録だけを見せる。
class HealthyLifeCard extends ConsumerWidget {
  const HealthyLifeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final best = bestDailyStreak(ref.watch(scoredVisitsProvider));
    if (best < healthyLifeDays) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Washi.page,
          border: Border.all(color: Washi.shuLight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.healthyLifeTitle,
                  style: const TextStyle(
                    fontFamily: Washi.brush,
                    fontSize: 17,
                    color: Washi.shu,
                  ),
                ),
              ),
              Text(
                l10n.healthyLifeBest(best),
                style: const TextStyle(
                  fontFamily: Washi.brush,
                  fontSize: 17,
                  color: Washi.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
