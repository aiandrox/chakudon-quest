import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/visit_history.dart';

import '../../support/builders.dart';

void main() {
  final shopA = buildShop(id: 'a');
  final shopB = buildShop(id: 'b');
  DateTime day(int d) => DateTime(2026, 9, d, 12);

  test('同じ店の、ひとつ前の記録を返す', () {
    final first = buildEntry(shop: shopA, eatenAt: day(1));
    final second = buildEntry(shop: shopA, eatenAt: day(10));
    final other = buildEntry(shop: shopB, eatenAt: day(15));
    final third = buildEntry(shop: shopA, eatenAt: day(20));
    final all = [third, other, second, first];

    expect(previousVisitAtShop(all, third.visit), same(second));
    expect(previousVisitAtShop(all, second.visit), same(first));
  });

  test('その店で最初の記録には前回が無い', () {
    final first = buildEntry(shop: shopA, eatenAt: day(1));
    final other = buildEntry(shop: shopB, eatenAt: day(1));

    expect(previousVisitAtShop([first, other], first.visit), isNull);
  });

  test('撤退の記録も前回として返す', () {
    final retreat = buildEntry(
      shop: shopA,
      eatenAt: day(1),
      result: VisitResult.retreated,
    );
    final eaten = buildEntry(shop: shopA, eatenAt: day(2));

    expect(previousVisitAtShop([eaten, retreat], eaten.visit), same(retreat));
  });
}
