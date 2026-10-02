import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/journal/journal.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';

import '../../support/builders.dart';

void main() {
  final shop = buildShop(id: 'shop', name: 'はやし田');
  DateTime day(int month, int d) => DateTime(2026, month, d, 12);

  List<String> journalOf(
    List<VisitWithShop> entries, {
    List<Wish> wishes = const [],
  }) {
    final scored = scoreVisits(entries, wishes: wishes);
    return buildJournal(scored.last, scored);
  }

  test('願を掛けた店で、撤退のあと並んで食べた1杯を物語にする', () {
    final retreat = buildEntry(
      shop: shop,
      result: VisitResult.retreated,
      eatenAt: day(9, 10),
      memo: '売り切れ',
    );
    final eaten = buildEntry(
      shop: shop,
      eatenAt: day(10, 3),
      waitMinutes: 45,
      style: RamenStyle.shoyu,
    );
    final lines = journalOf(
      [retreat, eaten],
      wishes: [
        Wish(
          id: 'wish',
          name: 'はやし田',
          trigger: '同僚に聞いた',
          createdAt: day(9, 1),
          fulfilledVisitId: eaten.visit.id,
        ),
      ],
    );

    expect(lines.first, '9月1日、願を掛けた店。きっかけは「同僚に聞いた」。');
    expect(lines, contains('前回は「売り切れ」に阻まれ、撤退した。'));
    expect(lines.any((l) => l.contains('45分')), isTrue);
    expect(lines.any((l) => l.startsWith('ついに着丼。醤油の一杯、修行点 ')), isTrue);
    expect(lines.last, '32日越しの願成就。');
  });

  test('初めての店は何軒目の道場かを、いつもの1杯は今年何杯目かを添える', () {
    final other = buildEntry(
      shop: buildShop(id: 'other'),
      eatenAt: day(1, 5),
    );
    final first = buildEntry(shop: shop, eatenAt: day(2, 1));
    final lines = journalOf([other, first]);

    expect(lines.first, contains('2軒目'));
    expect(lines.first, isNot(contains('願')));
    expect(lines.last, '今年 2杯目。');
  });

  test('2回目は来訪の回数を、撤退が続いたあとの1杯は再挑戦成功を添える', () {
    final lines = journalOf([
      buildEntry(shop: shop, eatenAt: day(1, 1)),
      buildEntry(shop: shop, result: VisitResult.retreated, eatenAt: day(1, 2)),
      buildEntry(shop: shop, result: VisitResult.retreated, eatenAt: day(1, 3)),
      buildEntry(shop: shop, eatenAt: day(1, 4)),
    ]);

    expect(lines.first, contains('2度目'));
    expect(lines, contains('2度の撤退を越えて、ここまで来た。'));
    expect(lines.last, '再挑戦、成功。');
  });

  test('撤退の記録は、阻まれた理由と次への一言で終える', () {
    final lines = journalOf([
      buildEntry(
        shop: shop,
        result: VisitResult.retreated,
        eatenAt: day(3, 1),
        waitMinutes: 20,
        memo: '臨時休業',
      ),
    ]);

    expect(lines, contains('20分並んだが、'));
    expect(lines, contains('「臨時休業」に阻まれ、撤退。'));
    expect(lines.last, anyOf('次こそは。', 'この借りは、必ず返す。'));
  });

  test('同じ記録なら、何度組み立てても同じ文になる', () {
    final entry = buildEntry(shop: shop, eatenAt: day(4, 1));
    expect(journalOf([entry]), journalOf([entry]));
  });

  test('願を掛ける前の1杯を叶えたことにしても、願の話は入れない', () {
    final eaten = buildEntry(shop: shop, eatenAt: day(5, 10));
    final lines = journalOf(
      [eaten],
      wishes: [
        Wish(
          id: 'wish',
          name: 'はやし田',
          createdAt: day(10, 3),
          fulfilledVisitId: eaten.visit.id,
        ),
      ],
    );

    expect(lines.any((l) => l.contains('願')), isFalse);
  });
}
