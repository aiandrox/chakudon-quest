import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ink_wear.dart';
import 'washi.dart';

/// ボタンの見た目。役割ごとに、札・筆の線・印で描き分ける。
///
/// - 朱札（[shu]）: その画面でいちばん大事な決定（着丼・保存・共有など）
/// - 墨札（[sumi]）: ほかの選び方・寄り道（並ぶ・ページを見る・読み込むなど）
/// - 筆の下線（[fude]）: 控えめな寄り道の文字リンク
/// - 消し札（[keshi]）: 取り消し・撤退・削除。赤で脅かさず、灰の墨で控えめに
///
/// [night]は、墨色の背景（着丼直後の画面・並び中の帯）に置くとき。
abstract final class FudaStyle {
  static const _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );

  static ButtonStyle shu({
    bool night = false,
    double height = 52,
    double fontSize = 20,
    bool expand = false,
  }) {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        expand ? Size.fromHeight(height) : Size(64, height),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 22),
      ),
      shape: const WidgetStatePropertyAll(_shape),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? (night ? Washi.nightSoft : Washi.faded)
            : Washi.page,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? (night ? Washi.nightSoft : Washi.faded)
            : Washi.page,
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: Washi.brush,
          fontSize: fontSize,
          letterSpacing: fontSize / 8,
        ),
      ),
      backgroundBuilder: (context, states, child) =>
          _ShuBackground(states: states, night: night, child: child),
    );
  }

  static ButtonStyle sumi({
    bool night = false,
    double height = 48,
    bool expand = false,
  }) {
    final ink = night ? Washi.paper : Washi.ink;
    return _brushFramed(
      height: height,
      expand: expand,
      foreground: ink,
      disabled: night ? Washi.inkSoft : Washi.line,
      frame: ink,
      fill: night ? Colors.transparent : Washi.page,
      pressedFill: night ? const Color(0x22F3ECDF) : Washi.desk,
      weight: FontWeight.w600,
    );
  }

  static ButtonStyle keshi({
    bool night = false,
    double height = 48,
    bool expand = false,
  }) {
    return _brushFramed(
      height: height,
      expand: expand,
      foreground: night ? Washi.nightSoft : Washi.inkSoft,
      disabled: night ? Washi.inkSoft : Washi.line,
      frame: night ? Washi.nightSoft.withValues(alpha: 0.6) : Washi.faded,
      fill: night ? const Color(0x14F3ECDF) : Washi.desk,
      pressedFill: night ? const Color(0x2EF3ECDF) : Washi.line,
      weight: FontWeight.w500,
    );
  }

  static ButtonStyle fude({bool night = false}) {
    final text = night ? Washi.paper : Washi.ink;
    final disabled = night ? Washi.inkSoft : Washi.faded;
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10),
      ),
      shape: const WidgetStatePropertyAll(_shape),
      overlayColor: WidgetStatePropertyAll(text.withValues(alpha: 0.06)),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? disabled : text,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? disabled
            : (night ? Washi.shuLight : Washi.shu),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: Washi.mincho, fontSize: 15),
      ),
      backgroundBuilder: (context, states, child) => CustomPaint(
        painter: _UnderlinePainter(
          color: states.contains(WidgetState.disabled)
              ? disabled.withValues(alpha: 0.5)
              : (night ? Washi.shuLight : Washi.shu).withValues(alpha: 0.8),
        ),
        child: child,
      ),
    );
  }

  static ButtonStyle _brushFramed({
    required double height,
    required bool expand,
    required Color foreground,
    required Color disabled,
    required Color frame,
    required Color fill,
    required Color pressedFill,
    required FontWeight weight,
  }) {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        expand ? Size.fromHeight(height) : Size(64, height),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20),
      ),
      shape: const WidgetStatePropertyAll(_shape),
      side: const WidgetStatePropertyAll(BorderSide.none),
      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? disabled : foreground,
      ),
      iconColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? disabled : foreground,
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: Washi.mincho, fontSize: 16, fontWeight: weight),
      ),
      backgroundBuilder: (context, states, child) => CustomPaint(
        painter: _BrushFramePainter(
          frame: states.contains(WidgetState.disabled) ? disabled : frame,
          fill: states.contains(WidgetState.pressed) ? pressedFill : fill,
        ),
        child: child,
      ),
    );
  }
}

/// 朱塗りの札。朱の地に、和紙色の細い枠（角印の枠）を内側に引き、押しむらのかすれをつける。
class _ShuBackground extends StatelessWidget {
  const _ShuBackground({
    required this.states,
    required this.night,
    required this.child,
  });

  final Set<WidgetState> states;
  final bool night;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final disabled = states.contains(WidgetState.disabled);
    final pressed = states.contains(WidgetState.pressed);
    final fill = disabled
        ? (night ? const Color(0x26F3ECDF) : Washi.line)
        : (pressed ? const Color(0xFF8C1C16) : Washi.shu);
    final paint = CustomPaint(
      painter: _ShuPlatePainter(
        fill: fill,
        frame: disabled
            ? Colors.transparent
            : Washi.page.withValues(alpha: pressed ? 0.35 : 0.55),
      ),
    );
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: disabled
              ? paint
              : InkWear(seed: 7, strength: 0.2, child: paint),
        ),
        ?child,
      ],
    );
  }
}

class _ShuPlatePainter extends CustomPainter {
  const _ShuPlatePainter({required this.fill, required this.frame});

  final Color fill;
  final Color frame;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawPath(_wobblyRect(rect.deflate(0.5)), Paint()..color = fill);
    canvas.drawPath(
      _wobblyRect(rect.deflate(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = frame,
    );
  }

  @override
  bool shouldRepaint(_ShuPlatePainter old) =>
      old.fill != fill || old.frame != frame;
}

/// 筆で4辺を引いた枠。辺ごとに入りが太く抜けが細く、角で少しはみ出す。
class _BrushFramePainter extends CustomPainter {
  const _BrushFramePainter({required this.frame, required this.fill});

  final Color frame;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    // 大きさで揺れ方を決め、同じボタンはいつ見ても同じ揺れにする。
    final random = math.Random(size.width.round() * 31 + size.height.round());
    double wobble() => (random.nextDouble() - 0.5) * 1.2;
    final l = 4.0, t = 4.0, r = size.width - 4, b = size.height - 4;
    canvas.drawRect(Rect.fromLTRB(l, t, r, b), Paint()..color = fill);
    final paint = Paint()..color = frame;
    final w = wobble;
    brushStroke(
      canvas,
      Offset(l - 2, t + w()),
      Offset(r + 3, t),
      3.2,
      0.9,
      paint,
    );
    brushStroke(
      canvas,
      Offset(r, t - 2),
      Offset(r + w(), b + 3),
      2.8,
      0.8,
      paint,
    );
    brushStroke(
      canvas,
      Offset(l - 3, b),
      Offset(r + 2, b + w()),
      3.0,
      1.0,
      paint,
    );
    brushStroke(
      canvas,
      Offset(l + w(), t - 1),
      Offset(l, b + 2),
      3.4,
      1.1,
      paint,
    );
  }

  @override
  bool shouldRepaint(_BrushFramePainter old) =>
      old.frame != frame || old.fill != fill;
}

/// 文字の下に引いた、入りが太く抜けが細い筆の線。
class _UnderlinePainter extends CustomPainter {
  const _UnderlinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height - 11;
    final lift = math.Random(size.width.round()).nextDouble() * 1.5;
    brushStroke(
      canvas,
      Offset(10, y),
      Offset(size.width - 8, y - lift),
      2.6,
      0.6,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_UnderlinePainter old) => old.color != color;
}

/// [from]から[to]へ、太さ[startWidth]から[endWidth]へ細くなる筆の線を引く。
void brushStroke(
  Canvas canvas,
  Offset from,
  Offset to,
  double startWidth,
  double endWidth,
  Paint paint,
) {
  final delta = to - from;
  final length = delta.distance;
  if (length == 0) return;
  final normal = Offset(-delta.dy, delta.dx) / length;
  final path = Path()
    ..moveTo(
      from.dx + normal.dx * startWidth / 2,
      from.dy + normal.dy * startWidth / 2,
    )
    ..lineTo(to.dx + normal.dx * endWidth / 2, to.dy + normal.dy * endWidth / 2)
    ..arcToPoint(
      to - normal * endWidth / 2,
      radius: Radius.circular(endWidth / 2),
    )
    ..lineTo(
      from.dx - normal.dx * startWidth / 2,
      from.dy - normal.dy * startWidth / 2,
    )
    ..arcToPoint(
      from + normal * startWidth / 2,
      radius: Radius.circular(startWidth / 2),
    )
    ..close();
  canvas.drawPath(path, paint);
}

/// 朱札。その画面でいちばん大事な決定に使う。
class ShuFuda extends StatelessWidget {
  const ShuFuda({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.night = false,
    this.expand = false,
    this.height = 52,
    this.fontSize = 20,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool night;
  final bool expand;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = FudaStyle.shu(
      night: night,
      height: height,
      fontSize: fontSize,
      expand: expand,
    );
    return switch (icon) {
      final icon? => FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: icon,
        label: child,
      ),
      null => FilledButton(style: style, onPressed: onPressed, child: child),
    };
  }
}

/// 墨札。ほかの選び方や、別の画面へ進む寄り道に使う。
class SumiFuda extends StatelessWidget {
  const SumiFuda({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.night = false,
    this.expand = false,
    this.height = 48,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool night;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = FudaStyle.sumi(night: night, height: height, expand: expand);
    return switch (icon) {
      final icon? => OutlinedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: icon,
        label: child,
      ),
      null => OutlinedButton(style: style, onPressed: onPressed, child: child),
    };
  }
}

/// 消し札。取り消し・撤退・削除に使う。目立たせすぎず、押せることはわかるように。
class KeshiFuda extends StatelessWidget {
  const KeshiFuda({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.night = false,
    this.expand = false,
    this.height = 48,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool night;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = FudaStyle.keshi(night: night, height: height, expand: expand);
    return switch (icon) {
      final icon? => OutlinedButton.icon(
        style: style,
        onPressed: onPressed,
        icon: icon,
        label: child,
      ),
      null => OutlinedButton(style: style, onPressed: onPressed, child: child),
    };
  }
}

/// 筆の下線を引いた文字リンク。控えめな寄り道に使う。
class FudeLink extends StatelessWidget {
  const FudeLink({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.night = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final style = FudaStyle.fude(night: night);
    return switch (icon) {
      final icon? => TextButton.icon(
        style: style,
        onPressed: onPressed,
        icon: icon,
        label: child,
      ),
      null => TextButton(style: style, onPressed: onPressed, child: child),
    };
  }
}

/// 画面の上に浮かぶ丸いボタン。朱の丸印（[sumi]なら和紙に墨の輪）。
class SealFab extends StatelessWidget {
  const SealFab({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.sumi = false,
    this.small = false,
    this.brush = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final bool sumi;
  final bool small;

  /// 内側の輪を、筆でひと息に描いた輪（円相）にする。
  final bool brush;

  @override
  Widget build(BuildContext context) {
    final size = small ? 48.0 : 60.0;
    final disc = CustomPaint(
      painter: _SealDiscPainter(sumi: sumi, brush: brush),
    );
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: sumi
                      ? disc
                      : InkWear(seed: 3, strength: 0.4, child: disc),
                ),
                IconTheme.merge(
                  data: IconThemeData(
                    size: small ? 22 : 28,
                    color: sumi ? Washi.ink : Washi.page,
                  ),
                  child: child,
                ),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onPressed,
                      splashColor: (sumi ? Washi.ink : Washi.page).withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 手で押した印のように、縁をごくわずかに揺らした丸。
Path _wobblyCircle(Offset center, double radius) {
  final path = Path();
  const steps = 72;
  for (var i = 0; i <= steps; i++) {
    final a = 2 * math.pi * i / steps;
    // 規則的な波にならないよう、周期の違う小さな揺れを重ねる。
    final r =
        radius -
        0.5 +
        math.sin(a * 3 + 0.7) * 0.35 +
        math.sin(a * 7 + 2.1) * 0.2 +
        math.sin(a * 11 + 4.0) * 0.12;
    final p = center + Offset(math.cos(a), math.sin(a)) * r;
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// 手で押した札のように、4辺をごくわずかに揺らした四角。
Path _wobblyRect(Rect rect) {
  final path = Path();
  const steps = 24;
  void edge(Offset from, Offset to, double phase) {
    final normal =
        Offset(-(to - from).dy, (to - from).dx) / (to - from).distance;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final sway =
          math.sin(t * math.pi * 3 + phase) * 0.5 * math.sin(t * math.pi);
      final p = Offset.lerp(from, to, t)! + normal * sway;
      path.lineTo(p.dx, p.dy);
    }
  }

  path.moveTo(rect.left, rect.top);
  edge(rect.topLeft, rect.topRight, 0.3);
  edge(rect.topRight, rect.bottomRight, 1.7);
  edge(rect.bottomRight, rect.bottomLeft, 2.9);
  edge(rect.bottomLeft, rect.topLeft, 4.1);
  return path..close();
}

class _SealDiscPainter extends CustomPainter {
  const _SealDiscPainter({required this.sumi, this.brush = false});

  final bool sumi;
  final bool brush;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (brush) {
      _paintBrushed(canvas, center, radius);
      return;
    }
    canvas.drawPath(
      _wobblyCircle(center, radius),
      Paint()..color = sumi ? Washi.page : Washi.shu,
    );
    canvas.drawCircle(
      center,
      radius - (sumi ? 3 : 5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = sumi ? 2.2 : 1.2
        ..color = sumi
            ? Washi.ink.withValues(alpha: 0.85)
            : Washi.page.withValues(alpha: 0.6),
    );
  }

  /// いちばん目立たせたい「＋」。朱の丸を、外側から墨の筆でひと息に描いた輪（円相）で囲む。
  /// 左上で筆を置いて太く入り、時計回りに細く抜け、始まりの少し手前で終わる。
  void _paintBrushed(Canvas canvas, Offset center, double radius) {
    Offset at(double angle, double r) =>
        center + Offset(math.cos(angle), math.sin(angle)) * r;

    canvas.drawPath(
      _wobblyCircle(center, radius * 0.84),
      Paint()..color = Washi.shu,
    );

    final ringRadius = radius * 0.88;
    final maxWidth = radius * 0.22;
    const start = -math.pi * 0.62;
    const sweep = math.pi * 1.88;
    const steps = 90;
    final outer = <Offset>[];
    final inner = <Offset>[];
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final a = start + sweep * t;
      final width =
          maxWidth *
          (t < 0.08 ? 0.7 + t / 0.08 * 0.3 : 1 - 0.7 * ((t - 0.08) / 0.92));
      final r = ringRadius + math.sin(t * math.pi * 2) * radius * 0.015;
      outer.add(at(a, r + width / 2));
      inner.add(at(a, r - width / 2));
    }
    final ring = Path()..moveTo(outer.first.dx, outer.first.dy);
    for (final p in outer.skip(1)) {
      ring.lineTo(p.dx, p.dy);
    }
    for (final p in inner.reversed) {
      ring.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      ring..close(),
      Paint()..color = Washi.ink.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_SealDiscPainter old) =>
      old.sumi != sumi || old.brush != brush;
}

/// 下のタブの真ん中に置く、記録を始める大きな判子。墨の丸に朱の筆の円相、和紙色の「＋」。
/// 朱の印が並ぶ印帳の上でも埋もれないよう、画面でいちばん濃い墨を地にする。
class RecordSealButton extends StatelessWidget {
  const RecordSealButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  static const size = 72.0;

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _RecordSealPainter()),
                ),
                const Icon(Icons.add, size: 36, color: Washi.page),
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onPressed,
                      splashColor: Washi.shuLight.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordSealPainter extends CustomPainter {
  const _RecordSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    canvas.drawPath(_wobblyCircle(center, radius), Paint()..color = Washi.ink);
    _paintEnso(
      canvas,
      center,
      ringRadius: radius * 0.74,
      maxWidth: radius * 0.16,
      wobble: radius * 0.015,
      color: Washi.shuLight,
    );
  }

  @override
  bool shouldRepaint(_RecordSealPainter old) => false;
}

/// 筆でひと息に描いた輪（円相）。左上で筆を置いて太く入り、時計回りに細く抜け、始まりの少し手前で終わる。
void _paintEnso(
  Canvas canvas,
  Offset center, {
  required double ringRadius,
  required double maxWidth,
  required double wobble,
  required Color color,
}) {
  Offset at(double angle, double r) =>
      center + Offset(math.cos(angle), math.sin(angle)) * r;
  const start = -math.pi * 0.62;
  const sweep = math.pi * 1.88;
  const steps = 90;
  final outer = <Offset>[];
  final inner = <Offset>[];
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final a = start + sweep * t;
    final width =
        maxWidth *
        (t < 0.08 ? 0.7 + t / 0.08 * 0.3 : 1 - 0.7 * ((t - 0.08) / 0.92));
    final r = ringRadius + math.sin(t * math.pi * 2) * wobble;
    outer.add(at(a, r + width / 2));
    inner.add(at(a, r - width / 2));
  }
  final ring = Path()..moveTo(outer.first.dx, outer.first.dy);
  for (final p in outer.skip(1)) {
    ring.lineTo(p.dx, p.dy);
  }
  for (final p in inner.reversed) {
    ring.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(ring..close(), Paint()..color = color);
}
