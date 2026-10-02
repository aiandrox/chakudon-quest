import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/theme/washi.dart';

List<String> _joined(List<List<String>> lines) => [
  for (final line in lines) line.join(),
];

void main() {
  group('verticalLines', () {
    test('収まるときは1行。空白は詰める', () {
      expect(_joined(verticalLines('麺処 たつみ', maxChars: 6)), ['麺処たつみ']);
      expect(_joined(verticalLines('とても長い店の名前', maxChars: null)), [
        'とても長い店の名前',
      ]);
    });

    test('収まらないときは、空白で分けられればそこで2行にする', () {
      expect(_joined(verticalLines('中華そば 千歳屋本店', maxChars: 6)), [
        '中華そば',
        '千歳屋本店',
      ]);
    });

    test('空白で分けても収まらなければ、文字数で折り返す', () {
      expect(_joined(verticalLines('らーめん専門店かいざん', maxChars: 6)), [
        'らーめん専門',
        '店かいざん',
      ]);
      expect(_joined(verticalLines('麺 らーめん専門店かいざん', maxChars: 6)), [
        '麺らーめん専',
        '門店かいざん',
      ]);
    });

    test('2行にも収まらなければ、最後を「…」にする', () {
      expect(_joined(verticalLines('一二三四五六七八九十壱弐参', maxChars: 6)), [
        '一二三四五六',
        '七八九十壱…',
      ]);
    });

    test('ちょうど2行分なら「…」にしない', () {
      expect(_joined(verticalLines('一二三四五六七八九十壱弐', maxChars: 6)), [
        '一二三四五六',
        '七八九十壱弐',
      ]);
    });
  });
}
