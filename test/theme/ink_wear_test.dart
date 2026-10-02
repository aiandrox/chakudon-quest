import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/theme/ink_wear.dart';

void main() {
  test('同じ記録の印は、いつ作っても同じかすれ方になる', () {
    final first = inkWearPattern(inkSeed('visit-1'));
    final again = inkWearPattern(inkSeed('visit-1'));

    expect(again.fadeAngle, first.fadeAngle);
    expect(again.fadeStrength, first.fadeStrength);
    expect(again.marks, first.marks);
    expect(again.streaks, first.streaks);
  });

  test('ちがう記録の印は、かすれ方がちがう', () {
    final a = inkWearPattern(inkSeed('visit-1'));
    final b = inkWearPattern(inkSeed('visit-2'));

    expect(b.marks, isNot(a.marks));
  });

  test('かすれは印の中に収まり、強さは0〜1', () {
    for (final key in ['a', 'visit-1', '0f8e1c2a-uuid', '']) {
      final pattern = inkWearPattern(inkSeed(key));
      expect(pattern.fadeStrength, inInclusiveRange(0, 1));
      for (final mark in pattern.marks) {
        expect(mark.x, inInclusiveRange(0, 1));
        expect(mark.y, inInclusiveRange(0, 1));
        expect(mark.strength, inInclusiveRange(0, 1));
      }
      for (final streak in pattern.streaks) {
        expect(streak.strength, inInclusiveRange(0, 1));
      }
    }
  });
}
