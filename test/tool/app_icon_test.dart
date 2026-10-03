import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramen_in_cho/theme/washi.dart';

/// アプリのアイコンと起動画面の絵（藍の印帳の表紙に、丼の朱印）を作る。
///
/// ふだんは絵があるかだけを確かめる。絵を変えたら
/// `flutter test --dart-define=UPDATE_APP_ICON=true test/tool/app_icon_test.dart`
/// で作り直し、iOS のアイコンは透明の層を外す（App Store が受け付けないため）:
/// `python3 -c "import glob;from PIL import Image;[Image.open(p).convert('RGB').save(p) for p in glob.glob('ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png')]"`
const _update = bool.fromEnvironment('UPDATE_APP_ICON');

const _indigo = Color(0xFF26344A);
const _unit = 512.0;

enum _Layout {
  /// 和紙の地いっぱいに表紙を置く（iOS と、古い Android のアイコン）。
  full,

  /// 透明の地。丸く切り抜かれても表紙が欠けない大きさ（Android のアダプティブアイコン）。
  foreground,

  /// 透明の地。起動画面の真ん中に置く。
  splash,
}

const _scales = {
  _Layout.full: 1.0,
  _Layout.foreground: .6,
  _Layout.splash: .62,
};

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cover = RRect.fromRectAndRadius(
      const Rect.fromLTWH(100, 40, 312, 432),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      cover.shift(const Offset(8, 10)),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawRRect(cover, Paint()..color = _indigo);
    canvas.drawRect(
      const Rect.fromLTWH(322, 66, 64, 214),
      Paint()..color = Washi.page,
    );
    canvas.drawPath(
      _wobblyCircle(const Offset(220, 338), 92, 6),
      Paint()..color = Washi.shu,
    );
    _bowl(canvas, const Offset(220, 342), 110, Washi.page, 8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _wobblyCircle(Offset center, double radius, int seed) {
  final random = math.Random(seed);
  final phases = [for (var i = 0; i < 3; i++) random.nextDouble() * 6];
  final path = Path();
  for (var i = 0; i <= 240; i++) {
    final t = i / 240 * 2 * math.pi;
    final k =
        1 +
        .012 *
            (math.sin(3 * t + phases[0]) * .5 +
                math.sin(7 * t + phases[1]) * .3 +
                math.sin(17 * t + phases[2]) * .2);
    final point = center + Offset(math.cos(t), math.sin(t)) * radius * k;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

void _bowl(
  Canvas canvas,
  Offset rimCenter,
  double width,
  Color color,
  double stroke,
) {
  Paint line(double w) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final top = rimCenter.dy;
  final x = rimCenter.dx;
  canvas.drawPath(
    Path()
      ..moveTo(x - width / 2, top)
      ..quadraticBezierTo(x - width / 2, top + width * .48, x, top + width * .5)
      ..quadraticBezierTo(x + width / 2, top + width * .48, x + width / 2, top),
    line(stroke),
  );
  canvas.drawOval(
    Rect.fromCenter(center: rimCenter, width: width, height: width * .16),
    line(stroke),
  );
  canvas.drawLine(
    Offset(x - width * .16, top + width * .56),
    Offset(x + width * .16, top + width * .56),
    line(stroke),
  );
  for (var i = 0; i < 3; i++) {
    final start = x - width * .08 + i * width * .07;
    final noodle = Path()..moveTo(start, top);
    for (var y = 0.0; y <= width * .42; y += 2) {
      noodle.lineTo(
        start + math.sin(y / (width * .06) + i) * width * .025,
        top - y,
      );
    }
    canvas.drawPath(noodle, line(stroke * .7));
  }
  canvas.drawLine(
    Offset(x - width * .32, top - width * .5),
    Offset(x + width * .42, top - width * .32),
    line(stroke * .9),
  );
  canvas.drawLine(
    Offset(x - width * .3, top - width * .58),
    Offset(x + width * .44, top - width * .42),
    line(stroke * .9),
  );
}

Widget _icon(_Layout layout) {
  const style = TextStyle(
    fontFamily: Washi.brush,
    fontSize: 52,
    color: Washi.ink,
    height: 1,
  );
  return SizedBox.square(
    dimension: _unit,
    child: ColoredBox(
      color: layout == _Layout.full ? Washi.paper : Colors.transparent,
      child: Transform.scale(
        scale: _scales[layout]!,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _IconPainter())),
            Positioned(
              left: 322,
              top: 66,
              width: 64,
              height: 214,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final c in '麺印帳'.split('')) Text(c, style: style),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

const _android = 'android/app/src/main/res';
const _ios = 'ios/Runner/Assets.xcassets';
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// 作る絵: パス → (置き方, 一辺のピクセル)
Map<String, (_Layout, double)> get _targets => {
  for (final MapEntry(key: name, value: d) in _densities.entries) ...{
    '$_android/mipmap-$name/ic_launcher.png': (_Layout.full, 48 * d),
    '$_android/mipmap-$name/ic_launcher_foreground.png': (
      _Layout.foreground,
      108 * d,
    ),
    '$_android/drawable-$name/splash_logo.png': (_Layout.splash, 288 * d),
  },
  for (final (points, scales) in const [
    (20.0, [1, 2, 3]),
    (29.0, [1, 2, 3]),
    (40.0, [1, 2, 3]),
    (60.0, [2, 3]),
    (76.0, [1, 2]),
    (83.5, [2]),
    (1024.0, [1]),
  ])
    for (final s in scales)
      '$_ios/AppIcon.appiconset/Icon-App-${_points(points)}x${_points(points)}@${s}x.png':
          (_Layout.full, points * s),
  for (final (suffix, s) in const [('', 1), ('@2x', 2), ('@3x', 3)])
    '$_ios/LaunchImage.imageset/LaunchImage$suffix.png': (
      _Layout.splash,
      200.0 * s,
    ),
};

String _points(double points) => points == points.roundToDouble()
    ? points.toInt().toString()
    : points.toString();

void main() {
  testWidgets('アプリのアイコンと起動画面の絵', (tester) async {
    if (!_update) {
      for (final path in _targets.keys) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      return;
    }
    await (FontLoader(
      Washi.brush,
    )..addFont(rootBundle.load('assets/fonts/YujiSyuku-Regular.ttf'))).load();
    for (final layout in _Layout.values) {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(key: key, child: _icon(layout)),
          ),
        ),
      );
      for (final MapEntry(key: path, value: (target, pixels))
          in _targets.entries) {
        if (target != layout) continue;
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: pixels / _unit);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File(path)
            ..parent.createSync(recursive: true)
            ..writeAsBytesSync(data!.buffer.asUint8List());
        });
      }
    }
  });
}
