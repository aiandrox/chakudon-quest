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
/// 1行に収まらないときは、右から左へ2行目に折り返す。
class VerticalText extends StatelessWidget {
  const VerticalText(
    this.text, {
    super.key,
    required this.style,
    this.maxChars,
    this.maxLines = 2,
  });

  final String text;
  final TextStyle style;

  /// 1行の最大の文字数。nullなら折り返さない。
  final int? maxChars;
  final int maxLines;

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
    final lines = verticalLines(text, maxChars: maxChars, maxLines: maxLines);
    final charStyle = style.copyWith(height: 1.15);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 縦書きは右の行から読むので、1行目を右に置く。
              for (final line in lines.reversed)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final char in line)
                      _rotated.contains(char)
                          ? RotatedBox(
                              quarterTurns: 1,
                              child: Text(char, style: charStyle),
                            )
                          : Text(char, style: charStyle),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 縦書きの行に分ける。区切りの空白で分けて収まるならそこで、収まらなければ文字数で
/// 折り返す。[maxLines]行に収まらないときは、最後の文字を「︙」にする。
List<List<String>> verticalLines(
  String text, {
  int? maxChars,
  int maxLines = 2,
}) {
  List<String> charsOf(String value) => [
    for (final rune in value.runes)
      if (String.fromCharCode(rune).trim().isNotEmpty)
        String.fromCharCode(rune),
  ];
  final chars = charsOf(text);
  if (maxChars == null || chars.length <= maxChars) return [chars];

  final words = [
    for (final word in text.trim().split(RegExp(r'[\s　]+')))
      if (word.isNotEmpty) charsOf(word),
  ];
  if (words.length > 1 && words.length <= maxLines) {
    if (words.every((word) => word.length <= maxChars)) return words;
  }

  final lines = <List<String>>[
    for (var i = 0; i < chars.length && i ~/ maxChars < maxLines; i += maxChars)
      chars.sublist(i, (i + maxChars).clamp(0, chars.length)),
  ];
  if (chars.length > maxChars * maxLines) {
    lines.last = [...lines.last.take(maxChars - 1), '︙'];
  }
  return lines;
}
