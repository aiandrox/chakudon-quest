import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/map/shop_pins.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';
import 'package:chakudon_quest/features/scoring/ranks.dart';

import '../../support/builders.dart';

void main() {
  DateTime day(int d) => DateTime(2026, 9, d, 12);

  test('位置のわかる店ごとに1本、杯数・撤退数・最後に行った日・ランクつきで立てる', () {
    final shop = buildShop(id: 'a', latitude: 35.0, longitude: 139.0);
    final pins = shopPins(
      scoreVisits([
        buildEntry(shop: shop, eatenAt: day(1), result: VisitResult.retreated),
        buildEntry(shop: shop, eatenAt: day(2)),
        buildEntry(shop: shop, eatenAt: day(5)),
      ]),
    );

    final pin = pins.single;
    expect(pin.shop.id, 'a');
    expect(pin.latitude, 35.0);
    expect(pin.longitude, 139.0);
    expect(pin.eatenCount, 2);
    expect(pin.retreatCount, 1);
    expect(pin.lastVisitAt, day(5));
    // 撤退のあとの初訪問: 10 + 10 + 15 = 35
    expect(pin.rank, ShopRank.b);
  });

  test('位置のわからない店は立てない。撤退だけの店はランクなし', () {
    final pins = shopPins(
      scoreVisits([
        buildEntry(
          shop: buildShop(id: 'unknown'),
          eatenAt: day(1),
        ),
        buildEntry(
          shop: buildShop(id: 'closed', latitude: 35.0, longitude: 139.0),
          eatenAt: day(2),
          result: VisitResult.retreated,
        ),
      ]),
    );

    expect(pins.map((p) => p.shop.id), ['closed']);
    expect(pins.single.rank, isNull);
    expect(pins.single.eatenCount, 0);
  });

  test('記録が無ければピンも無い', () {
    expect(shopPins(const []), isEmpty);
  });
}
