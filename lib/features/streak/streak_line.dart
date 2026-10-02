import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'streak.dart';

/// 何週続けて食べているか。今週まだなら「今週はまだ」も出す。
class StreakLine extends ConsumerWidget {
  const StreakLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final streak = ref.watch(streakProvider);
    if (streak.weeks == 0) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, size: 16, color: colors.primary),
          const SizedBox(width: 4),
          Text(l10n.streakWeeks(streak.weeks), style: textTheme.bodySmall),
          if (streak.isAtRisk) ...[
            const SizedBox(width: 8),
            Text(
              l10n.streakAtRisk,
              style: textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}
