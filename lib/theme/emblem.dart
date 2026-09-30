import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 紋章の格。数字が大きいほど豪華な色になる。
enum EmblemTier { locked, bronze, silver, gold, platinum, legend }

extension on EmblemTier {
  List<Color> get metal => switch (this) {
    EmblemTier.locked => const [Color(0xFFBDBDBD), Color(0xFF8E8E8E)],
    EmblemTier.bronze => const [Color(0xFFE3A869), Color(0xFF9C5A26)],
    EmblemTier.silver => const [Color(0xFFF1F3F5), Color(0xFF8D98A3)],
    EmblemTier.gold => const [Color(0xFFFFE08A), Color(0xFFC08A12)],
    EmblemTier.platinum => const [Color(0xFFE6F7F5), Color(0xFF5FA7A0)],
    EmblemTier.legend => const [Color(0xFFFFB3C7), Color(0xFF7A4DD8)],
  };

  Color get core => switch (this) {
    EmblemTier.locked => const Color(0xFF6E6E6E),
    EmblemTier.bronze => const Color(0xFF6B3A17),
    EmblemTier.silver => const Color(0xFF4F5B66),
    EmblemTier.gold => const Color(0xFF8A5A00),
    EmblemTier.platinum => const Color(0xFF2E6B66),
    EmblemTier.legend => const Color(0xFF4B2A99),
  };
}

/// 称号やクエストを表す、ロゴ風の紋章（六角形のメダル＋アイコン＋帯）。
class Emblem extends StatelessWidget {
  const Emblem({
    super.key,
    required this.icon,
    required this.tier,
    this.size = 56,
    this.label,
  });

  final IconData icon;
  final EmblemTier tier;
  final double size;

  /// 下の帯に出す短い文字（「Lv.3」など）。
  final String? label;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return SizedBox(
      width: size,
      height: size * (label == null ? 1 : 1.12),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _EmblemPainter(tier),
            child: SizedBox.square(
              dimension: size,
              child: Icon(
                icon,
                size: size * 0.42,
                color: tier == EmblemTier.locked
                    ? Colors.white70
                    : Colors.white,
              ),
            ),
          ),
          if (label != null)
            Positioned(
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tier.core,
                  borderRadius: BorderRadius.circular(size * 0.08),
                  border: Border.all(color: tier.metal.first, width: 1.2),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size * 0.1,
                    vertical: size * 0.01,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: math.max(9, size * 0.18),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter(this.tier);

  final EmblemTier tier;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final outer = _hexagon(center, radius);
    final inner = _hexagon(center, radius * 0.78);
    final metal = tier.metal;

    canvas.drawPath(
      outer.shift(Offset(0, radius * 0.06)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.06),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [metal.first, metal.last, metal.first],
          stops: const [0, 0.6, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.lerp(tier.core, Colors.white, 0.18)!, tier.core],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.04
        ..color = metal.first.withValues(alpha: 0.9),
    );
  }

  Path _hexagon(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => oldDelegate.tier != tier;
}

/// 称号の文字をロゴ風に見せる（太字・字間・金属色のグラデーション）。
class TitleLogo extends StatelessWidget {
  const TitleLogo(
    this.text, {
    super.key,
    required this.tier,
    this.fontSize = 20,
  });

  final String text;
  final EmblemTier tier;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final metal = tier.metal;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(metal.last, Colors.black, 0.15)!, tier.core],
      ).createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: fontSize * 0.12,
          height: 1.1,
        ),
      ),
    );
  }
}
