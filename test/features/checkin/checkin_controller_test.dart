import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/checkin/checkin_controller.dart';
import 'package:chakudon_quest/features/database/app_database.dart';
import 'package:chakudon_quest/features/records/clock.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/nearby_shop_finder.dart';
import 'package:chakudon_quest/features/shop_search/shop_search_service.dart';

import '../../support/fakes.dart';

const _here = GeoPoint(35.0, 139.0);

void main() {
  late FakeLocationService location;
  late FakeShopFinder overpass;
  late ProviderContainer container;
  var now = DateTime(2026, 9, 30, 11);

  setUp(() {
    now = DateTime(2026, 9, 30, 11);
    location = FakeLocationService(position: _here);
    overpass = FakeShopFinder(
      shops: const [
        // 約56m
        FoundShop(
          osmId: 'node/near',
          name: '近い店',
          location: GeoPoint(35.0005, 139.0),
        ),
        // 約222m
        FoundShop(
          osmId: 'node/far',
          name: '遠い店',
          location: GeoPoint(35.002, 139.0),
        ),
      ],
    );
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(createTestDatabase()),
        locationServiceProvider.overrideWithValue(location),
        nearbyShopFinderProvider.overrideWithValue(overpass),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    container.listen(checkinControllerProvider, (_, _) {});
  });

  CheckinController controller() =>
      container.read(checkinControllerProvider.notifier);
  CheckinState state() => container.read(checkinControllerProvider);
  RecordRepository repository() => container.read(recordRepositoryProvider);

  test('100m以内の店にチェックインできる', () async {
    await controller().search();
    final near = state().result!.candidates.first;

    expect(near.name, '近い店');
    expect(await controller().checkIn(near), isTrue);

    final checkin = (await repository().activeCheckin())!;
    expect(checkin.name, '近い店');
    expect(checkin.osmId, 'node/near');
    expect(checkin.checkedInAt, now);
  });

  test('100mより遠い店にはチェックインできない', () async {
    await controller().search();
    final far = state().result!.candidates.last;

    expect(far.name, '遠い店');
    expect(await controller().checkIn(far), isFalse);
    expect(await repository().activeCheckin(), isNull);
  });

  test('通信できなくても、現在地がわかれば店名の手入力でチェックインできる', () async {
    overpass.error = const SocketException('offline');
    await controller().search();

    expect(state().result!.failure, ShopSearchFailure.searchFailed);
    expect(state().canCheckInManually, isTrue);
    expect(await controller().checkInManually(' 電波のない店 '), isTrue);

    final checkin = (await repository().activeCheckin())!;
    expect(checkin.name, '電波のない店');
    expect(checkin.latitude, 35.0);
    expect(checkin.longitude, 139.0);
  });

  test('現在地がわからないときはチェックインできない', () async {
    location.position = null;
    await controller().search();

    expect(state().result!.failure, ShopSearchFailure.noLocation);
    expect(state().canCheckInManually, isFalse);
    expect(await controller().checkInManually('麺屋'), isFalse);
    expect(await repository().activeCheckin(), isNull);
  });

  test('店名が空ではチェックインできない', () async {
    await controller().search();

    expect(await controller().checkInManually('  '), isFalse);
  });

  group('activeCheckinProvider', () {
    Future<void> checkInNearShop() async {
      await controller().search();
      await controller().checkIn(state().result!.candidates.first);
      // 購読が無いとproviderが止まったままになる。
      container.listen(activeCheckinProvider, (_, _) {});
    }

    test('3時間以内のチェックインを返す', () async {
      await checkInNearShop();
      now = now.add(const Duration(hours: 3));

      final checkin = await container.read(activeCheckinProvider.future);

      expect(checkin!.name, '近い店');
    });

    test('3時間を超えたチェックインは自動で取り消す', () async {
      await checkInNearShop();
      now = now.add(const Duration(hours: 3, minutes: 1));

      final checkin = await container.read(activeCheckinProvider.future);

      expect(checkin, isNull);
      expect(await repository().activeCheckin(), isNull);
    });
  });
}
