import 'package:flutter/material.dart';

/// 和紙と墨と朱の色、筆文字と明朝の書体。
abstract final class Washi {
  static const paper = Color(0xFFF3ECDF);
  static const desk = Color(0xFFE9E1D2);
  static const page = Color(0xFFFBF8F1);
  static const ink = Color(0xFF1D1A17);
  static const inkSoft = Color(0xFF5C554D);
  static const line = Color(0xFFCFC3AD);
  static const faded = Color(0xFF8A8175);
  static const shu = Color(0xFFB3261E);
  static const shuLight = Color(0xFFE46A5F);
  static const nightSoft = Color(0xFFC9BFAE);

  static const brush = 'YujiSyuku';
  static const mincho = 'ShipporiMincho';
}

/// 台紙に貼った写真のように、白い縁と薄い影をつけて少し傾ける。
class PastedPhoto extends StatelessWidget {
  const PastedPhoto({
    super.key,
    required this.child,
    this.angle = 0,
    this.border = 4,
  });

  final Widget child;
  final double angle;
  final double border;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(padding: EdgeInsets.all(border), child: child),
      ),
    );
  }
}

/// 縦書きの文字列。1文字ずつ縦に積み、長音などの横向きの記号は90度回す。
class VerticalText extends StatelessWidget {
  const VerticalText(
    this.text, {
    super.key,
    required this.style,
    this.maxChars,
  });

  final String text;
  final TextStyle style;

  /// これより長いときは末尾を「︙」にする。
  final int? maxChars;

  static const _rotated = {
    'ー',
    '－',
    '-',
    '〜',
    '～',
    '—',
    '…',
    '（',
    '）',
    '(',
    ')',
    '「',
    '」',
  };

  @override
  Widget build(BuildContext context) {
    var chars = [
      for (final rune in text.runes)
        if (String.fromCharCode(rune).trim().isNotEmpty)
          String.fromCharCode(rune),
    ];
    final max = maxChars;
    if (max != null && chars.length > max) {
      chars = [...chars.take(max - 1), '︙'];
    }
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final char in chars)
                _rotated.contains(char)
                    ? RotatedBox(
                        quarterTurns: 1,
                        child: Text(char, style: style.copyWith(height: 1.15)),
                      )
                    : Text(char, style: style.copyWith(height: 1.15)),
            ],
          ),
        ),
      ),
    );
  }
}
