import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'washi.dart';

/// 祝いの紙吹雪。朱・金・和紙色の紙片が上から舞い落ちる。1回だけ流れて止まる。
/// 印が押されるのを待ってから降り始め、そのときに強めに震わせる。
/// 「動きを減らす」設定のときは紙吹雪を出さず、震えだけにする。
class KamiFubuki extends StatefulWidget {
  const KamiFubuki({super.key});

  static const duration = Duration(milliseconds: 3600);

  @override
  State<KamiFubuki> createState() => _KamiFubukiState();
}

class _KamiFubukiState extends State<KamiFubuki>
    with SingleTickerProviderStateMixin {
  /// 印が押されるまで（全体のこの割合）は降らせない。
  static const _start = 0.22;

  late final _controller = AnimationController(
    vsync: this,
    duration: KamiFubuki.duration,
  );
  late final _pieces = _makePieces(70);
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    _controller
      ..addListener(_buzzOnce)
      ..forward();
  }

  void _buzzOnce() {
    if (_buzzed || _controller.value < _start) return;
    _buzzed = true;
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = (_controller.value - _start) / (1 - _start);
          if (t <= 0 || t >= 1) return const SizedBox.expand();
          return CustomPaint(
            size: Size.infinite,
            painter: _FubukiPainter(_pieces, t),
          );
        },
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.x,
    required this.delay,
    required this.fall,
    required this.sway,
    required this.spin,
    required this.color,
    required this.size,
  });

  /// 横の位置（画面の幅に対する割合）。
  final double x;

  /// 降り始めるまでの遅れ（0〜0.35）。
  final double delay;

  /// 落ちる速さ（画面の高さに対する割合）。
  final double fall;
  final double sway;
  final double spin;
  final Color color;
  final Size size;
}

const _colors = [
  Washi.shu,
  Washi.shuLight,
  Color(0xFFD4A63A),
  Washi.paper,
  Washi.shu,
];

List<_Piece> _makePieces(int count) {
  // 毎回同じ舞い方にするため、種を固定する。
  final random = math.Random(7);
  return [
    for (var i = 0; i < count; i++)
      _Piece(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.35,
        fall: 0.9 + random.nextDouble() * 0.6,
        sway: 8 + random.nextDouble() * 18,
        spin: (random.nextDouble() - 0.5) * 12,
        color: _colors[random.nextInt(_colors.length)],
        size: Size(5 + random.nextDouble() * 4, 8 + random.nextDouble() * 6),
      ),
  ];
}

class _FubukiPainter extends CustomPainter {
  _FubukiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final piece in pieces) {
      final local = (t - piece.delay) / (1 - piece.delay);
      if (local <= 0) continue;
      final y = -20 + local * piece.fall * (size.height + 40);
      if (y > size.height + 20) continue;
      final x =
          piece.x * size.width + math.sin(local * math.pi * 3) * piece.sway;
      // 最後の2割で薄くして消す。
      final opacity = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      paint.color = piece.color.withValues(alpha: opacity.clamp(0, 1));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(local * piece.spin);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: piece.size.width,
          // 裏返るように見せるため、高さを回転に合わせて伸び縮みさせる。
          height: piece.size.height * math.cos(local * piece.spin * 1.7).abs(),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FubukiPainter old) => old.t != t;
}
