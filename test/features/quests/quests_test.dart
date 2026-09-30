import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/quests/quests.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';

import '../../support/builders.dart';

DateTime _day(int d) => DateTime(2026, 1, 1, 12).add(Duration(days: d));

QuestProgress _progress(String id, List<VisitWithShop> entries) =>
    evaluateQuests(scoreVisits(entries)).firstWhere((p) => p.quest.id == id);

void main() {
  final shop = buildShop(id: 'shop');

  test('クエストは8件で、IDが重複しない', () {
    expect(quests, hasLength(8));
    expect(quests.map((q) => q.id).toSet(), hasLength(8));
    expect(quests.map((q) => q.title), [
      'はじめての着丼',
      '行列に挑む者',
      '60分の試練',
      '全系統制覇',
      '限定を狩れ',
      '再挑戦',
      '大物討伐',
      '百杯の道',
    ]);
  });

  test('記録が無ければ、すべて未達成', () {
    final all = evaluateQuests(const []);

    expect(all.map((p) => p.status).toSet(), {QuestStatus.notStarted});
    expect(all.map((p) => p.current).toSet(), {0});
    expect(all.map((p) => p.achievedAt).toSet(), {null});
  });

  group('はじめての着丼', () {
    test('食べた記録が1件で達成。達成日はその記録の日時', () {
      final progress = _progress('first_bowl', [
        buildEntry(shop: shop, eatenAt: _day(3)),
        buildEntry(shop: shop, eatenAt: _day(5)),
      ]);

      expect(progress.status, QuestStatus.achieved);
      expect(progress.current, 1);
      expect(progress.achievedAt, _day(3));
    });

    test('撤退だけでは達成しない', () {
      final progress = _progress('first_bowl', [
        buildEntry(shop: shop, result: VisitResult.retreated),
      ]);

      expect(progress.status, QuestStatus.notStarted);
    });
  });

  group('待ち時間のクエスト', () {
    test('29分では「行列に挑む者」を達成せず、30分で達成する', () {
      expect(
        _progress('queue_30', [buildEntry(shop: shop, waitMinutes: 29)]).status,
        QuestStatus.notStarted,
      );
      expect(
        _progress('queue_30', [buildEntry(shop: shop, waitMinutes: 30)]).status,
        QuestStatus.achieved,
      );
    });

    test('59分では「60分の試練」を達成せず、60分で達成する', () {
      expect(
        _progress('queue_60', [buildEntry(shop: shop, waitMinutes: 59)]).status,
        QuestStatus.notStarted,
      );
      expect(
        _progress('queue_60', [buildEntry(shop: shop, waitMinutes: 60)]).status,
        QuestStatus.achieved,
      );
    });

    test('並んで撤退した記録は数えない', () {
      final progress = _progress('queue_60', [
        buildEntry(shop: shop, waitMinutes: 90, result: VisitResult.retreated),
      ]);

      expect(progress.status, QuestStatus.notStarted);
    });
  });

  group('全系統制覇', () {
    const sevenStyles = [
      RamenStyle.shoyu,
      RamenStyle.miso,
      RamenStyle.shio,
      RamenStyle.tonkotsu,
      RamenStyle.iekei,
      RamenStyle.jiro,
      RamenStyle.tsukemen,
    ];

    test('7系統すべてで達成。達成日は最後の系統を食べた日', () {
      final progress = _progress('all_styles', [
        for (var i = 0; i < 7; i++)
          buildEntry(shop: shop, eatenAt: _day(i), style: sevenStyles[i]),
        buildEntry(shop: shop, eatenAt: _day(10), style: RamenStyle.shoyu),
      ]);

      expect(progress.status, QuestStatus.achieved);
      expect(progress.current, 7);
      expect(progress.achievedAt, _day(6));
    });

    test('6系統では挑戦中。同じ系統・その他・系統なしは数えない', () {
      final progress = _progress('all_styles', [
        for (var i = 0; i < 6; i++)
          buildEntry(shop: shop, eatenAt: _day(i), style: sevenStyles[i]),
        buildEntry(shop: shop, eatenAt: _day(7), style: RamenStyle.shoyu),
        buildEntry(shop: shop, eatenAt: _day(8), style: RamenStyle.other),
        buildEntry(shop: shop, eatenAt: _day(9)),
      ]);

      expect(progress.status, QuestStatus.inProgress);
      expect(progress.current, 6);
      expect(progress.achievedAt, isNull);
    });
  });

  group('限定を狩れ', () {
    List<VisitWithShop> limited(int count) => [
      for (var i = 0; i < count; i++)
        buildEntry(shop: shop, eatenAt: _day(i), isLimited: true),
    ];

    test('4件では挑戦中、5件で達成', () {
      final four = _progress('limited_5', limited(4));
      final five = _progress('limited_5', limited(5));

      expect(four.status, QuestStatus.inProgress);
      expect(four.current, 4);
      expect(five.status, QuestStatus.achieved);
      expect(five.achievedAt, _day(4));
    });

    test('目標を超えても、表示する数は目標まで', () {
      expect(_progress('limited_5', limited(8)).current, 5);
    });
  });

  group('再挑戦', () {
    test('撤退した店で、そのあとに食べると達成', () {
      final progress = _progress('retry', [
        buildEntry(shop: shop, eatenAt: _day(1), result: VisitResult.retreated),
        buildEntry(shop: shop, eatenAt: _day(2)),
      ]);

      expect(progress.status, QuestStatus.achieved);
      expect(progress.achievedAt, _day(2));
    });

    test('食べたあとに撤退しただけ、別の店で食べただけでは達成しない', () {
      final other = buildShop(id: 'other');
      final progress = _progress('retry', [
        buildEntry(shop: shop, eatenAt: _day(1)),
        buildEntry(shop: shop, eatenAt: _day(2), result: VisitResult.retreated),
        buildEntry(shop: other, eatenAt: _day(3)),
      ]);

      expect(progress.status, QuestStatus.notStarted);
    });
  });

  group('大物討伐', () {
    test('1杯で60点以上の店があると達成', () {
      final rare = buildShop(
        id: 'rare',
        hoursConditions: {HoursCondition.weekdaysOnly, HoursCondition.fewDays},
      );
      // (10 + 10 + 20) × 2 = 80
      final progress = _progress('rank_s', [
        buildEntry(shop: shop, eatenAt: _day(1)),
        buildEntry(shop: rare, eatenAt: _day(2), isLimited: true),
      ]);

      expect(progress.status, QuestStatus.achieved);
      expect(progress.achievedAt, _day(2));
    });

    test('Aランクまでの店だけでは達成しない', () {
      // 10 + 10 + 20 + 15 = 55
      final progress = _progress('rank_s', [
        buildEntry(shop: shop, isLimited: true, waitMinutes: 30),
      ]);

      expect(progress.status, QuestStatus.notStarted);
    });
  });

  group('百杯の道', () {
    List<VisitWithShop> bowls(int count) => [
      for (var i = 0; i < count; i++) buildEntry(shop: shop, eatenAt: _day(i)),
    ];

    test('99杯では挑戦中、100杯で達成', () {
      final ninetyNine = _progress('bowls_100', bowls(99));
      final hundred = _progress('bowls_100', bowls(100));

      expect(ninetyNine.status, QuestStatus.inProgress);
      expect(ninetyNine.current, 99);
      expect(hundred.status, QuestStatus.achieved);
      expect(hundred.achievedAt, _day(99));
    });
  });

  group('newlyAchievedQuests', () {
    test('今回の記録で新しく達成したクエストだけを返す', () {
      final before = [buildEntry(shop: shop, eatenAt: _day(1))];
      final after = [
        ...before,
        buildEntry(shop: shop, eatenAt: _day(2), waitMinutes: 65),
      ];

      final achieved = newlyAchievedQuests(
        before: evaluateQuests(scoreVisits(before)),
        after: evaluateQuests(scoreVisits(after)),
      );

      expect(achieved.map((q) => q.id), ['queue_30', 'queue_60']);
    });

    test('最初の1杯では「はじめての着丼」を達成する', () {
      final achieved = newlyAchievedQuests(
        before: evaluateQuests(const []),
        after: evaluateQuests(scoreVisits([buildEntry(shop: shop)])),
      );

      expect(achieved.map((q) => q.id), ['first_bowl']);
    });

    test('達成済みのクエストは、もう一度知らせない', () {
      final before = [buildEntry(shop: shop, eatenAt: _day(1))];
      final after = [...before, buildEntry(shop: shop, eatenAt: _day(2))];

      final achieved = newlyAchievedQuests(
        before: evaluateQuests(scoreVisits(before)),
        after: evaluateQuests(scoreVisits(after)),
      );

      expect(achieved, isEmpty);
    });
  });
}
