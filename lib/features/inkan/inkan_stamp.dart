import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/washi.dart';
import '../records/models.dart';
import '../scoring/points.dart';
import '../scoring/rank_labels.dart';
import '../scoring/ranks.dart';
import 'inkan.dart';

String inkanStyleChar(AppLocalizations l10n, RamenStyle? style) =>
    switch (style) {
      RamenStyle.shoyu => l10n.inkanStyleShoyu,
      RamenStyle.miso => l10n.inkanStyleMiso,
      RamenStyle.shio => l10n.inkanStyleShio,
      RamenStyle.tonkotsu => l10n.inkanStyleTonkotsu,
      RamenStyle.iekei => l10n.inkanStyleIekei,
      RamenStyle.jiro => l10n.inkanStyleJiro,
      RamenStyle.tsukemen => l10n.inkanStyleTsukemen,
      RamenStyle.other || null => l10n.inkanStyleOther,
    };

String kanjiMonthDay(AppLocalizations l10n, DateTime date) =>
    l10n.kanjiMonthDay(kanjiNumber(date.month), kanjiNumber(date.day));

/// 1杯ごとの印。上に格と「一本」、真ん中に系統の一字、下に日付。
class InkanStamp extends StatelessWidget {
  const InkanStamp({super.key, required this.scored, this.size = 84});

  final ScoredVisit scored;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visit = scored.visit;
    final shape = inkanShapeFor(scored);
    final date = kanjiMonthDay(l10n, visit.eatenAt);
    final isRetreat = shape == InkanShape.retreat;
    final color = switch (shape) {
      InkanShape.retreat => Washi.faded,
      InkanShape.filled => Washi.page,
      _ => Washi.shu,
    };
    final top = isRetreat
        ? null
        : l10n.inkanTop(
            shopRankLabel(l10n, shopRankFor(scored.points.total)),
            scored.isRetrySuccess ? l10n.inkanRetry : l10n.inkanEaten,
          );
    final center = isRetreat
        ? l10n.inkanRetreat
        : inkanStyleChar(l10n, visit.style);
    final small = TextStyle(
      fontFamily: Washi.brush,
      fontSize: math.max(7, size * 0.11),
      color: color,
      height: 1.1,
    );

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (top != null) Text(top, style: small, maxLines: 1),
        Text(
          center,
          style: TextStyle(
            fontFamily: Washi.brush,
            fontSize: size * 0.42,
            color: color,
            height: 1.05,
          ),
        ),
        Text(date, style: small, maxLines: 1),
      ],
    );

    return Semantics(
      label: '$center $date',
      child: ExcludeSemantics(
        child: Transform.rotate(
          angle: inkanAngle(visit.id),
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _InkanPainter(shape),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InkanPainter extends CustomPainter {
  const _InkanPainter(this.shape);

  final InkanShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final stroke = radius * 0.07;
    Paint line(Color color, double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color.withValues(alpha: 0.92);

    switch (shape) {
      case InkanShape.circle:
        canvas.drawCircle(center, radius - stroke, line(Washi.shu, stroke));
      case InkanShape.doubleCircle:
        canvas.drawCircle(center, radius - stroke, line(Washi.shu, stroke));
        canvas.drawCircle(
          center,
          radius - stroke * 2.8,
          line(Washi.shu, stroke * 0.6),
        );
      case InkanShape.square:
        final outer = Rect.fromCircle(center: center, radius: radius * 0.86);
        final corner = Radius.circular(radius * 0.12);
        canvas.drawRRect(
          RRect.fromRectAndRadius(outer, corner),
          line(Washi.shu, stroke),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(outer.deflate(stroke * 1.8), corner),
          line(Washi.shu, stroke * 0.6),
        );
      case InkanShape.filled:
        canvas.drawCircle(center, radius - stroke, line(Washi.shu, stroke));
        canvas.drawCircle(
          center,
          radius - stroke * 2.6,
          Paint()..color = Washi.shu.withValues(alpha: 0.95),
        );
      case InkanShape.retreat:
        final paint = line(Washi.faded, stroke * 0.7);
        const dashes = 24;
        final rect = Rect.fromCircle(center: center, radius: radius - stroke);
        for (var i = 0; i < dashes; i++) {
          canvas.drawArc(
            rect,
            2 * math.pi * i / dashes,
            math.pi / dashes,
            false,
            paint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(_InkanPainter oldDelegate) => oldDelegate.shape != shape;
}

/// 段位の印（四角い朱の枠に段位の名前）。
class RankSeal extends StatelessWidget {
  const RankSeal({
    super.key,
    required this.label,
    this.fontSize = 16,
    this.color = Washi.shu,
  });

  final String label;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -5 * math.pi / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.45,
            vertical: fontSize * 0.25,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: Washi.brush,
              fontSize: fontSize,
              color: color,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
