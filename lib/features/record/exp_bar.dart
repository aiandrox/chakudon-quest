import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../inkan/inkan_stamp.dart';
import '../scoring/rank_labels.dart';
import '../scoring/ranks.dart';
import '../words/words.dart';

/// 着丼の直後に、修行点の帯を前の累計から今の累計まで伸ばす。
/// 段位が上がるときは、帯が新しい段位の必要点に届いたところ（すでに届いていれば伸ばし終えたところ）で、
/// 段位の印をぴかっと光らせて新しい段位に替える。1杯で上がるのは1つだけ。
class ExpBar extends StatefulWidget {
  const ExpBar({
    super.key,
    required this.before,
    required this.after,
    required this.rankBefore,
    required this.rankAfter,
    this.delay = const Duration(milliseconds: 900),
  });

  final int before;
  final int after;
  final AdventurerRank rankBefore;
  final AdventurerRank rankAfter;

  /// 印を押し終えるのを待ってから伸ばしはじめる。
  final Duration delay;

  @override
  State<ExpBar> createState() => _ExpBarState();
}

class _ExpBarState extends State<ExpBar> with TickerProviderStateMixin {
  late final _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final _points = Tween(
    begin: widget.before.toDouble(),
    end: widget.after.toDouble(),
  ).animate(CurvedAnimation(parent: _grow, curve: Curves.easeOutCubic));
  late AdventurerRank _rank = widget.rankBefore;
  bool _rankedUp = false;

  @override
  void initState() {
    super.initState();
    _grow
      ..addListener(_checkRank)
      ..addStatusListener((_) => _checkRank());
    Future<void>.delayed(widget.delay, () {
      if (mounted) _grow.forward();
    });
  }

  void _checkRank() {
    final target = widget.rankAfter;
    if (_rankedUp || target.index <= _rank.index) return;
    final reached = _points.value >= target.requiredPoints || _grow.isCompleted;
    if (!reached) return;
    setState(() {
      _rank = target;
      _rankedUp = true;
    });
    _flash.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _grow.dispose();
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_grow, _flash]),
      builder: (context, _) {
        final points = _points.value.floor();
        final next = _rank.next;
        final progress = next == null
            ? 1.0
            : ((points - _rank.requiredPoints) /
                      (next.requiredPoints - _rank.requiredPoints))
                  .clamp(0.0, 1.0);
        // 光は、ふくらんで消える。
        final glow = Curves.easeOut.transform(_flash.value);
        final shine = _flash.isAnimating || _flash.value > 0 ? (1 - glow) : 0.0;

        return Row(
          children: [
            SizedBox(
              width: 76,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (shine > 0)
                    Container(
                      width: 60 + 50 * glow,
                      height: 60 + 50 * glow,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.9 * shine),
                            Washi.aiLight.withValues(alpha: 0.5 * shine),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  Transform.scale(
                    scale: 1 + 0.3 * shine,
                    child: RankSeal(
                      label: adventurerRankLabel(l10n, _rank),
                      fontSize: 18,
                      color: Washi.shuLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.totalPoints(points),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                      if (_rankedUp)
                        Text(
                          _rank.isKyu ? l10n.rankUpKyu : l10n.rankUp,
                          style: textTheme.titleSmall?.copyWith(
                            fontFamily: Washi.brush,
                            color: colors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: colors.primary,
                    backgroundColor: Washi.line.withValues(alpha: 0.4),
                  ),
                  if (_rankedUp) ...[
                    const SizedBox(height: 6),
                    Text(
                      masterWords(_rank),
                      // 夜の色の結果画面でも読めるよう、背景に合わせた文字の色にする。
                      style: textTheme.bodyLarge?.copyWith(
                        fontFamily: Washi.brush,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
