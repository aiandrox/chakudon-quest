import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ink_wear.dart';
import '../../theme/washi.dart';
import 'quests.dart';

const _daiji = ['壱', '弐', '参', '肆', '伍', '陸', '漆', '捌', '玖', '拾'];

/// 段を大字（壱・弐・参…）で書く。範囲外は数字のまま。
String daijiNumber(int value) =>
    value >= 1 && value <= _daiji.length ? _daiji[value - 1] : '$value';

/// 型と奥義の印。型は段を角印に、奥義は会得を丸印に。未達成は灰色の点線。
/// 最高段まで上がった型は朱で塗りつぶす。
class QuestSeal extends StatelessWidget {
  const QuestSeal({
    super.key,
    required this.quest,
    required this.level,
    this.size = 52,
  });

  final Quest quest;
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSpot = quest.kind == QuestKind.spot;
    final locked = level <= 0;
    final isMax = !isSpot && level >= quest.maxLevel;
    final color = locked ? Washi.faded : Washi.shu;
    final text = locked
        ? l10n.questLocked
        : isSpot
        ? l10n.questCleared
        : daijiNumber(level);
    final shape = isSpot
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));

    return Semantics(
      label: locked
          ? l10n.questLocked
          : isSpot
          ? l10n.questCleared
          : l10n.questLevel(level),
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: (locked ? 0 : -6) * math.pi / 180,
          child: InkWear(
            seed: inkSeed('${quest.id}:$level'),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: isMax ? Washi.shu : Colors.transparent,
                shape: shape.copyWith(
                  side: BorderSide(
                    color: color,
                    width: locked ? 1.5 : size * 0.06,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(size * 0.12),
                child: FittedBox(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: Washi.brush,
                      fontSize: size * 0.5,
                      height: 1.1,
                      color: isMax ? Washi.page : color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
