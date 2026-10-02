import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/map/map_screen.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/wishes/wish_repository.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/nearby_shop_finder.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';
import '../../support/l10n.dart';

void main() {
  late FakeShopFinder overpass;
  late FakeLocationService location;

  setUp(() {
    location = FakeLocationService(position: const GeoPoint(35.0, 139.0));
    overpass = FakeShopFinder(
      shops: const [
        FoundShop(
          osmId: 'node/1',
          name: '行った店',
          location: GeoPoint(35.001, 139.0),
        ),
        FoundShop(
          osmId: 'node/2',
          name: 'まだ行っていない店',
          location: GeoPoint(35.002, 139.0),
        ),
      ],
    );
  });

  Future<void> pumpMap(WidgetTester tester, List<VisitWithShop> visits) async {
    // テストの文字は1文字が正方形で幅を取るため、出典の表示が収まるよう横を広くする。
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          visitsProvider.overrideWithValue(AsyncData(visits)),
          wishesProvider.overrideWithValue(const AsyncData([])),
          mapTilesEnabledProvider.overrideWithValue(false),
          locationServiceProvider.overrideWithValue(location),
          nearbyShopFinderProvider.overrideWithValue(overpass),
        ],
        child: localizedApp(home: const MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('行った店が無くても地図を出し、周辺を探せることを案内する', (tester) async {
    await pumpMap(tester, [buildEntry(shop: buildShop(id: 'no-location'))]);

    expect(find.text(ja.mapEmpty), findsOneWidget);
    expect(find.text(ja.mapSearchHere), findsOneWidget);
    expect(location.requests, [true]);
  });

  testWidgets('「このあたりを探す」で1km以内を探し、まだ行っていない店だけをピンで出す', (tester) async {
    final visited = buildShop(
      id: 'visited',
      name: '行った店',
      osmId: 'node/1',
      latitude: 35.001,
      longitude: 139.0,
    );
    await pumpMap(tester, [buildEntry(shop: visited)]);

    await tester.tap(find.text(ja.mapSearchHere));
    await tester.pumpAndSettle();

    expect(overpass.radii, [nearbySearchRadiusMeters]);
    expect(find.text(ja.mapNearbyFound(1)), findsOneWidget);
    expect(find.bySemanticsLabel('まだ行っていない店'), findsOneWidget);
    expect(find.text(ja.openPoiAttribution), findsOneWidget);
  });

  testWidgets('位置のわからない手入力の店や、撤退しただけの店は「まだ行っていない店」に出さない', (tester) async {
    await pumpMap(tester, [
      buildEntry(
        shop: buildShop(id: 'typed', name: '行った店'),
      ),
      buildEntry(
        shop: buildShop(
          id: 'retreated',
          name: 'まだ行っていない店',
          osmId: 'node/2',
          latitude: 35.002,
          longitude: 139.0,
        ),
        result: VisitResult.retreated,
      ),
    ]);

    await tester.tap(find.text(ja.mapSearchHere));
    await tester.pumpAndSettle();

    expect(find.text(ja.mapNearbyNone), findsOneWidget);
  });

  testWidgets('検索に失敗したら知らせる', (tester) async {
    overpass.error = StateError('offline');
    await pumpMap(tester, const []);

    await tester.tap(find.text(ja.mapSearchHere));
    await tester.pumpAndSettle();

    expect(find.text(ja.mapSearchFailed), findsOneWidget);
  });
}
