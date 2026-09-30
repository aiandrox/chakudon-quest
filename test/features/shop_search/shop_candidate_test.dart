import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/shop_candidate.dart';

const _here = GeoPoint(35.0, 139.0);

/// 緯度0.001度は約111m。
OverpassShop _found(String name, double northDegrees, {String? osmId}) =>
    OverpassShop(
      osmId: osmId ?? 'node/$name',
      name: name,
      location: GeoPoint(35.0 + northDegrees, 139.0),
    );

Shop _known(
  String name, {
  double? northDegrees,
  String? osmId,
  HoursType hoursType = HoursType.normal,
}) => Shop(
  id: 'shop-$name',
  name: name,
  latitude: northDegrees == null ? null : 35.0 + northDegrees,
  longitude: northDegrees == null ? null : 139.0,
  osmId: osmId,
  hoursType: hoursType,
  createdAt: DateTime(2026),
);

void main() {
  test('distanceMetersは緯度0.001度を約111mと計算する', () {
    expect(
      distanceMeters(_here, const GeoPoint(35.001, 139.0)),
      closeTo(111.2, 0.5),
    );
    expect(distanceMeters(_here, _here), 0);
  });

  group('rankShopCandidates', () {
    test('近い順に最大3件を返す', () {
      final candidates = rankShopCandidates(
        here: _here,
        found: [
          _found('遠い', 0.0025),
          _found('近い', 0.0005),
          _found('中くらい', 0.001),
          _found('やや遠い', 0.002),
        ],
        knownShops: const [],
      );

      expect(candidates.map((c) => c.name), ['近い', '中くらい', 'やや遠い']);
      expect(candidates.first.distanceMeters, closeTo(55.6, 0.5));
    });

    test('半径300mより遠い店は含めない', () {
      final candidates = rankShopCandidates(
        here: _here,
        found: [_found('圏内', 0.0026), _found('圏外', 0.0028)],
        knownShops: const [],
      );

      expect(candidates.map((c) => c.name), ['圏内']);
    });

    test('記録済みの店は、通信できず検索結果が空でも候補になる', () {
      final candidates = rankShopCandidates(
        here: _here,
        found: const [],
        knownShops: [
          _known('手入力の店', northDegrees: 0.001, hoursType: HoursType.fewDays),
          _known('位置のない店'),
          _known('遠くの店', northDegrees: 0.01),
        ],
      );

      expect(candidates.map((c) => c.name), ['手入力の店']);
      expect(candidates.single.shopId, 'shop-手入力の店');
      expect(candidates.single.hoursType, HoursType.fewDays);
    });

    test('同じ店が検索結果と記録済みの両方にあるときは記録済みの方を残す', () {
      final candidates = rankShopCandidates(
        here: _here,
        found: [
          _found('OSMの店', 0.001, osmId: 'node/1'),
          _found('手入力の店', 0.002),
          _found('初めての店', 0.0015),
        ],
        knownShops: [
          _known('OSMの店', northDegrees: 0.001, osmId: 'node/1'),
          _known('手入力の店', northDegrees: 0.002),
        ],
      );

      expect(candidates.map((c) => c.name), ['OSMの店', '初めての店', '手入力の店']);
      expect(candidates.map((c) => c.shopId), [
        'shop-OSMの店',
        null,
        'shop-手入力の店',
      ]);
    });
  });

  group('isSameShop', () {
    const here = GeoPoint(35.0, 139.0);
    const far = GeoPoint(35.01, 139.0);

    test('記録済みの店どうしはIDで比べる', () {
      expect(
        isSameShop(
          const ShopCandidate(shopId: 'a', name: '麺屋'),
          const ShopCandidate(shopId: 'a', name: '別の名前'),
        ),
        isTrue,
      );
      expect(
        isSameShop(
          const ShopCandidate(shopId: 'a', name: '麺屋'),
          const ShopCandidate(shopId: 'b', name: '麺屋'),
        ),
        isFalse,
      );
    });

    test('OSMの店どうしはOSMのIDで比べる', () {
      expect(
        isSameShop(
          const ShopCandidate(osmId: 'node/1', name: '一風堂'),
          const ShopCandidate(osmId: 'node/1', name: '一風堂'),
        ),
        isTrue,
      );
      expect(
        isSameShop(
          const ShopCandidate(osmId: 'node/1', name: '一風堂'),
          const ShopCandidate(osmId: 'node/2', name: '一風堂'),
        ),
        isFalse,
      );
    });

    test('IDで比べられないときは、同じ名前で近ければ同じ店', () {
      const manual = ShopCandidate(name: '麺屋', location: here);

      expect(
        isSameShop(
          manual,
          const ShopCandidate(osmId: 'node/1', name: '麺屋', location: here),
        ),
        isTrue,
      );
      expect(
        isSameShop(
          manual,
          const ShopCandidate(osmId: 'node/1', name: '麺屋', location: far),
        ),
        isFalse,
      );
      expect(isSameShop(manual, const ShopCandidate(name: '麺屋')), isTrue);
      expect(
        isSameShop(manual, const ShopCandidate(name: '別の店', location: here)),
        isFalse,
      );
    });
  });
}
