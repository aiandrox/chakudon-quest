import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/quests/quests.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';
import 'package:chakudon_quest/features/wishes/wishes.dart';

import '../../support/builders.dart';

Wish _wish({
  String id = 'wish',
  String? shopId,
  String? osmId,
  String name = 'はやし田',
  double? latitude,
  double? longitude,
  required DateTime createdAt,
  String? fulfilledVisitId,
}) => Wish(
  id: id,
  shopId: shopId,
  osmId: osmId,
  name: name,
  latitude: latitude,
  longitude: longitude,
  createdAt: createdAt,
  fulfilledVisitId: fulfilledVisitId,
);

void main() {
  final shop = buildShop(
    id: 'shop',
    name: 'らぁ麺 はやし田',
    latitude: 35.0,
    longitude: 139.0,
  );

  group('wishMatchesShop', () {
    test('記録済みの店のIDが同じなら同じ店', () {
      expect(
        wishMatchesShop(
          _wish(shopId: 'shop', name: '別名', createdAt: DateTime(2026)),
          shop,
        ),
        isTrue,
      );
    });

    test('まだ行っていない店は、表記の少し違う名前と近さで照らし合わせる', () {
      expect(
        wishMatchesShop(
          _wish(latitude: 35.0003, longitude: 139.0, createdAt: DateTime(2026)),
          shop,
        ),
        isTrue,
      );
      expect(
        wishMatchesShop(
          _wish(latitude: 35.01, longitude: 139.0, createdAt: DateTime(2026)),
          shop,
        ),
        isFalse,
      );
    });

    test('店名だけで書き留めた願は、表記の少し違う名前の店とも照らし合わせる', () {
      expect(
        wishMatchesShop(
          _wish(name: 'らぁ麺 はやし田', createdAt: DateTime(2026)),
          shop,
        ),
        isTrue,
      );
      expect(
        wishMatchesShop(_wish(name: 'はやし田', createdAt: DateTime(2026)), shop),
        isTrue,
      );
      expect(
        wishMatchesShop(_wish(name: '豚山', createdAt: DateTime(2026)), shop),
        isFalse,
      );
    });
  });

  group('scoreVisits の願成就', () {
    test('願と結び付いた1杯だけに、叶った願を添える', () {
      final first = buildEntry(shop: shop, eatenAt: DateTime(2026, 10, 3));
      final second = buildEntry(shop: shop, eatenAt: DateTime(2026, 10, 20));
      final scored = scoreVisits(
        [first, second],
        wishes: [
          _wish(
            createdAt: DateTime(2026, 9, 1),
            fulfilledVisitId: first.visit.id,
          ),
          _wish(id: 'pending', createdAt: DateTime(2026, 9, 2)),
        ],
      );

      expect(scored.map((e) => e.fulfilledWish?.id), ['wish', null]);
      expect(
        daysToFulfill(scored.first.fulfilledWish!, first.visit.eatenAt),
        32,
      );
    });

    test('願を掛ける前の写真で記録しても、日数は0にする', () {
      expect(
        daysToFulfill(
          _wish(createdAt: DateTime(2026, 10, 3)),
          DateTime(2026, 9, 1),
        ),
        0,
      );
    });
  });

  group('願掛けのクエスト', () {
    QuestProgress progress(List<ScoredVisit> scored, String id) =>
        evaluateQuests(scored).firstWhere((p) => p.quest.id == id);

    test('願成就の数で「願掛け」の段が上がる', () {
      final entry = buildEntry(shop: shop, eatenAt: DateTime(2026, 10, 3));
      final scored = scoreVisits(
        [entry],
        wishes: [
          _wish(
            createdAt: DateTime(2026, 9, 1),
            fulfilledVisitId: entry.visit.id,
          ),
        ],
      );

      expect(progress(scored, 'wishes').level, 1);
    });

    test('「百日越しの願」は99日では届かず、100日で届く', () {
      final created = DateTime(2026, 1, 1, 20);
      List<ScoredVisit> after(int days) {
        final entry = buildEntry(
          shop: shop,
          eatenAt: DateTime(2026, 1, 1 + days, 12),
        );
        return scoreVisits(
          [entry],
          wishes: [_wish(createdAt: created, fulfilledVisitId: entry.visit.id)],
        );
      }

      expect(progress(after(99), 'long_wish').isAchieved, isFalse);
      expect(progress(after(100), 'long_wish').isAchieved, isTrue);
    });
  });
}
