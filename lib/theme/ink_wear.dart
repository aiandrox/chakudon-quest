import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 文字列から決まった数を作る。同じ記録・同じ印は、いつ開いても同じかすれ方にするため。
int inkSeed(String key) =>
    key.codeUnits.fold<int>(17, (sum, unit) => (sum * 31 + unit) & 0x7fffffff);

/// かすれの1つ。中心と半径は印の大きさに対する割合（0〜1）。
typedef InkWearMark = ({double x, double y, double radius, double strength});

/// かすれの筋（インクが擦れて抜けた線）。位置と長さ・太さは印の大きさに対する割合。
typedef InkWearStreak = ({
  double x,
  double y,
  double angle,
  double length,
  double width,
  double strength,
});

/// かすれ方。印全体の濃さのむら（明るくなる向きと強さ）、インクの抜けた点と筋。
class InkWearPattern {
  const InkWearPattern({
    required this.fadeAngle,
    required this.fadeStrength,
    required this.marks,
    required this.streaks,
  });

  final double fadeAngle;
  final double fadeStrength;
  final List<InkWearMark> marks;
  final List<InkWearStreak> streaks;
}

/// [seed]が同じなら必ず同じかすれ方になる。
InkWearPattern inkWearPattern(int seed) {
  final random = math.Random(seed);
  double between(double min, double max) =>
      min + random.nextDouble() * (max - min);
  return InkWearPattern(
    fadeAngle: between(0, 2 * math.pi),
    fadeStrength: between(0.28, 0.62),
    marks: [
      // 押しむらでできる、ぼんやり薄い大きめのところ。
      for (var i = 0; i < 3 + random.nextInt(3); i++)
        (
          x: between(0.1, 0.9),
          y: between(0.1, 0.9),
          radius: between(0.09, 0.2),
          strength: between(0.28, 0.55),
        ),
      // インクが乗らなかった細かい点。
      for (var i = 0; i < 80 + random.nextInt(70); i++)
        (
          x: between(0, 1),
          y: between(0, 1),
          radius: between(0.005, 0.022),
          strength: between(0.55, 0.95),
        ),
    ],
    streaks: [
      for (var i = 0; i < 4 + random.nextInt(6); i++)
        (
          x: between(0.1, 0.9),
          y: between(0.1, 0.9),
          angle: between(-0.7, 0.7),
          length: between(0.18, 0.5),
          width: between(0.01, 0.028),
          strength: between(0.5, 0.9),
        ),
    ],
  );
}

/// 子（印）のインクをかすれさせる。同じ[seed]なら同じかすれ方。
class InkWear extends StatelessWidget {
  const InkWear({super.key, required this.seed, required this.child});

  final int seed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 不透明度で別の層にまとめ、かすれ（消しゴム）が印の下の紙まで消さないようにする。
    return Opacity(
      opacity: 0.94,
      child: CustomPaint(
        foregroundPainter: _InkWearPainter(seed),
        child: child,
      ),
    );
  }
}

class _InkWearPainter extends CustomPainter {
  _InkWearPainter(this.seed) : pattern = inkWearPattern(seed);

  final int seed;
  final InkWearPattern pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final extent = size.shortestSide;
    final direction = Offset(
      math.cos(pattern.fadeAngle),
      math.sin(pattern.fadeAngle),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = LinearGradient(
          begin: Alignment(-direction.dx, -direction.dy),
          end: Alignment(direction.dx, direction.dy),
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: pattern.fadeStrength),
          ],
        ).createShader(rect),
    );
    for (final mark in pattern.marks) {
      final radius = mark.radius * extent;
      canvas.drawCircle(
        Offset(mark.x * size.width, mark.y * size.height),
        radius,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.black.withValues(alpha: mark.strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6),
      );
    }
    _paintStreaks(canvas, size);
  }

  void _paintStreaks(Canvas canvas, Size size) {
    final extent = size.shortestSide;
    for (final streak in pattern.streaks) {
      canvas.save();
      canvas.translate(streak.x * size.width, streak.y * size.height);
      canvas.rotate(streak.angle);
      final width = streak.width * extent;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: streak.length * extent,
            height: width,
          ),
          Radius.circular(width / 2),
        ),
        Paint()
          ..blendMode = BlendMode.dstOut
          ..color = Colors.black.withValues(alpha: streak.strength)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.4),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_InkWearPainter oldDelegate) => oldDelegate.seed != seed;
}
