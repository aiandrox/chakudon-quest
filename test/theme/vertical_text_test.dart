import 'package:flutter_test/flutter_test.dart';

import 'package:ramen_in_cho/theme/washi.dart';

List<String> _lines(String text, {int? maxChars}) => [
  for (final line in verticalLines(text, maxChars: maxChars)) line.join(),
];

void main() {
  group('verticalLines', () {
    test('収まるときは1行。区切りの空白はすき間として残す', () {
      expect(_lines('麺処 たつみ', maxChars: 6), ['麺処 たつみ']);
      expect(_lines('とても長い店の名前'), ['とても長い店の名前']);
    });

    test('区切りの空白があれば、そこで分ける', () {
      expect(_lines('中華そば 千歳屋本店', maxChars: 6), ['中華そば', '千歳屋本店']);
      expect(_lines('ラーメン二郎 関内店', maxChars: 6), ['ラーメン二郎', '関内店']);
    });

    test('きりのいい空白なら、1文字だけ長くても分ける', () {
      expect(_lines('煮干らぁめん 瀧川', maxChars: 5), ['煮干らぁめん', '瀧川']);
    });

    test('空白が無ければ、文字の種類の変わり目で分ける', () {
      expect(_lines('ラーメン二郎関内店', maxChars: 6), ['ラーメン', '二郎関内店']);
      expect(_lines('らーめん専門店かいざん', maxChars: 6), ['らーめん専門店', 'かいざん']);
      expect(_lines('煮干らぁめん瀧川', maxChars: 5), ['煮干らぁめん', '瀧川']);
    });

    test('小さい「ぁ」や「ー」「ん」で行を始めない', () {
      for (final name in ['煮干らぁめん瀧川', 'ニュータンタンメン', 'とんこつらーめん']) {
        final lines = _lines(name, maxChars: 5);
        expect(lines, hasLength(2), reason: name);
        expect(
          lines.last[0],
          isNot(anyOf('ぁ', 'ー', 'ん', 'ン', 'ゃ')),
          reason: name,
        );
      }
    });

    test('2行にも収まらなければ、最後を「…」にする', () {
      expect(_lines('一二三四五六七八九十壱弐参', maxChars: 6), ['一二三四五六', '七八九十壱…']);
    });

    test('ちょうど2行分なら「…」にしない', () {
      expect(_lines('一二三四五六七八九十壱弐', maxChars: 6), ['一二三四五六', '七八九十壱弐']);
    });
  });
}
