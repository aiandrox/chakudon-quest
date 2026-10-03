import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/ink_wear.dart';
import '../../theme/washi.dart';
import '../inkan/inkan_stamp.dart';
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
    this.achievedAt,
  });

  final Quest quest;
  final int level;
  final double size;

  /// 奥義の印に入れる、会得した日。
  final DateTime? achievedAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSpot = quest.kind == QuestKind.spot;
    final design = quest.seal;
    if (isSpot && level > 0 && design != null) {
      return Semantics(
        label: quest.title,
        child: ExcludeSemantics(
          child: Transform.rotate(
            angle: -6 * math.pi / 180,
            child: InkWear(
              seed: inkSeed('${quest.id}:$level'),
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  painter: _SpotSealPainter(design.shape),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          design.glyph,
                          style: TextStyle(
                            fontFamily: Washi.brush,
                            fontSize: size * (achievedAt == null ? 0.46 : 0.36),
                            height: 1.0,
                            color: Washi.shu,
                          ),
                        ),
                        if (achievedAt case final at?)
                          SizedBox(
                            // 菱形と花は内側が狭いので、日付を小さくする。
                            width:
                                size *
                                (design.shape == QuestSealShape.diamond ||
                                        design.shape == QuestSealShape.flower
                                    ? 0.38
                                    : 0.5),
                            child: FittedBox(
                              child: Text(
                                kanjiEraDate(l10n, at),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: Washi.brush,
                                  fontSize: size * 0.12,
                                  height: 0.95,
                                  color: Washi.shu,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
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

/// 奥義ごとの印の枠。
class _SpotSealPainter extends CustomPainter {
  const _SpotSealPainter(this.shape);

  final QuestSealShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final w = r * 0.09;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = Washi.shu.withValues(alpha: 0.92);
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.5
      ..color = Washi.shu.withValues(alpha: 0.92);
    final fill = Paint()..color = Washi.shu.withValues(alpha: 0.92);

    Path polygon(int sides, double radius, {double rotate = 0}) {
      final path = Path();
      for (var i = 0; i < sides; i++) {
        final a = rotate + 2 * math.pi * i / sides - math.pi / 2;
        final p = c + Offset(math.cos(a), math.sin(a)) * radius;
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path..close();
    }

    switch (shape) {
      // 8つの系統を表す、8つの小さな丸の輪。
      case QuestSealShape.eightRing:
        canvas.drawCircle(c, r - w * 3.2, line);
        for (var i = 0; i < 8; i++) {
          final a = 2 * math.pi * i / 8 - math.pi / 2;
          canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * (r - w * 1.3),
            w * 1.1,
            fill,
          );
        }
      case QuestSealShape.doubleCircle:
        canvas.drawCircle(c, r - w, line);
        canvas.drawCircle(c, r - w * 2.8, thin);
      case QuestSealShape.square:
        final rect = Rect.fromCircle(center: c, radius: r * 0.82);
        canvas.drawRect(rect, line);
        canvas.drawRect(rect.deflate(w * 1.8), thin);
      case QuestSealShape.octagon:
        canvas.drawPath(polygon(8, r - w, rotate: math.pi / 8), line);
        canvas.drawPath(polygon(8, r - w * 2.8, rotate: math.pi / 8), thin);
      case QuestSealShape.diamond:
        canvas.drawPath(polygon(4, r - w * 0.5), line);
        canvas.drawPath(polygon(4, r - w * 2.6), thin);
      case QuestSealShape.hexagon:
        canvas.drawPath(polygon(6, r - w), line);
        canvas.drawPath(polygon(6, r - w * 2.8), thin);
      case QuestSealShape.flower:
        const petals = 8;
        final petalR = r * 0.24;
        final ringR = r - petalR - w * 0.5;
        for (var i = 0; i < petals; i++) {
          final a = 2 * math.pi * i / petals;
          canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * ringR,
            petalR,
            thin,
          );
        }
        canvas.drawCircle(c, ringR, line);
      case QuestSealShape.dottedRing:
        canvas.drawCircle(c, r - w * 2.4, line);
        final dots = Path();
        const count = 20;
        for (var i = 0; i < count; i++) {
          final a = 2 * math.pi * i / count;
          dots.addOval(
            Rect.fromCircle(
              center: c + Offset(math.cos(a), math.sin(a)) * (r - w * 0.6),
              radius: w * 0.5,
            ),
          );
        }
        canvas.drawPath(dots, fill);
      case QuestSealShape.castle:
        // 城壁のような凸凹の上辺をもつ角印。
        final rect = Rect.fromCircle(center: c, radius: r * 0.8);
        final path = Path()..moveTo(rect.left, rect.top);
        const merlons = 5;
        final step = rect.width / (merlons * 2 - 1);
        for (var i = 0; i < merlons * 2 - 1; i++) {
          final x = rect.left + step * (i + 1);
          final y = i.isEven ? rect.top : rect.top + step * 0.8;
          path
            ..lineTo(rect.left + step * i, y)
            ..lineTo(x, y);
        }
        path
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close();
        canvas.drawPath(path, line);
        canvas.drawRect(
          Rect.fromLTRB(
            rect.left + w * 1.8,
            rect.top + step * 0.8 + w * 1.8,
            rect.right - w * 1.8,
            rect.bottom - w * 1.8,
          ),
          thin,
        );
    }
  }

  @override
  bool shouldRepaint(_SpotSealPainter oldDelegate) =>
      oldDelegate.shape != shape;
}
