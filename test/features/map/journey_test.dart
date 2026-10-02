import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/map/journey.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/scoring/points.dart';

import '../../support/builders.dart';

void main() {
  // 緯度0.01度は約1.1km。
  final home = buildShop(id: 'home', latitude: 35.0, longitude: 139.0);
  final near = buildShop(id: 'near', latitude: 35.01, longitude: 139.0);
  final far = buildShop(id: 'far', latitude: 35.3, longitude: 139.0);
  final unknown = buildShop(id: 'unknown');
  DateTime day(int month, int d) => DateTime(2026, month, d, 12);

  List<ScoredVisit> scored(List<VisitWithShop> entries) => scoreVisits(entries);

  test('食べた店を順に並べ、位置のわからない店と撤退と、続けて同じ店は除く', () {
    final stops = journeyStops(
      scored([
        buildEntry(shop: home, eatenAt: day(1, 1)),
        buildEntry(shop: home, eatenAt: day(1, 2)),
        buildEntry(shop: unknown, eatenAt: day(1, 3)),
        buildEntry(
          shop: near,
          result: VisitResult.retreated,
          eatenAt: day(1, 4),
        ),
        buildEntry(shop: near, eatenAt: day(1, 5)),
        buildEntry(shop: home, eatenAt: day(1, 6)),
      ]),
    );

    expect(stops.map((s) => s.shop.id), ['home', 'near', 'home']);
    expect(journeyKilometers(stops), closeTo(2.22, 0.02));
  });

  test('年で絞り込める', () {
    final stops = journeyStops(
      scored([
        buildEntry(shop: home, eatenAt: DateTime(2025, 12, 31, 12)),
        buildEntry(shop: near, eatenAt: day(1, 1)),
      ]),
      year: 2026,
    );

    expect(stops.map((s) => s.shop.id), ['near']);
  });

  test('いちばん通う店から20km以上離れた店で食べた日を、遠征としてまとめる', () {
    final list = expeditions(
      journeyStops(
        scored([
          buildEntry(shop: home, eatenAt: day(1, 1)),
          buildEntry(shop: home, eatenAt: day(1, 8)),
          buildEntry(shop: far, eatenAt: day(2, 1)),
          buildEntry(shop: near, eatenAt: day(2, 2)),
        ]),
      ),
    );

    expect(list.single.day, DateTime(2026, 2, 1));
    expect(list.single.stops.single.shop.id, 'far');
  });

  test('記録が無ければ遠征も無い', () {
    expect(expeditions(const []), isEmpty);
  });
}
