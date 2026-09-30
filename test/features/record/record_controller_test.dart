import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:chakudon_quest/features/database/app_database.dart';
import 'package:chakudon_quest/features/record/photo_picker.dart';
import 'package:chakudon_quest/features/record/record_controller.dart';
import 'package:chakudon_quest/features/record/record_state.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/overpass_client.dart';

import '../../support/fakes.dart';

const _here = GeoPoint(35.0, 139.0);
final _photoTime = DateTime(2026, 9, 30, 12);

void main() {
  late Directory documents;
  late FakeLocationService location;
  late FakeOverpassClient overpass;
  late FakePhotoPicker picker;
  late ProviderContainer container;

  setUp(() {
    documents = createTempDirectory();
    final photo = File(p.join(createTempDirectory().path, 'camera.jpg'))
      ..writeAsBytesSync([1, 2, 3]);
    location = FakeLocationService(position: _here);
    overpass = FakeOverpassClient(
      shops: const [
        OverpassShop(
          osmId: 'node/1',
          name: '麺屋テスト',
          location: GeoPoint(35.001, 139.0),
        ),
      ],
    );
    picker = FakePhotoPicker(cameraPath: photo.path, galleryPath: photo.path);
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(createTestDatabase()),
        documentsDirectoryProvider.overrideWithValue(documents),
        locationServiceProvider.overrideWithValue(location),
        overpassClientProvider.overrideWithValue(overpass),
        photoPickerProvider.overrideWithValue(picker),
        clockProvider.overrideWithValue(() => _photoTime),
      ],
    );
    addTearDown(container.dispose);
    // autoDisposeのため、テスト中は購読して破棄されないようにする。
    container.listen(recordControllerProvider, (_, _) {});
  });

  RecordController controller() =>
      container.read(recordControllerProvider.notifier);
  RecordState state() => container.read(recordControllerProvider);
  Future<List<VisitWithShop>> visits() =>
      container.read(recordRepositoryProvider).watchVisits().first;

  test('写真を撮ると近くの店が候補に出て、選んで★をつければ保存できる', () async {
    await controller().start();
    await pumpEventQueue();

    expect(state().photoPath, isNotNull);
    expect(state().searchStatus, ShopSearchStatus.done);
    expect(state().candidates.single.name, '麺屋テスト');
    expect(state().canSave, isFalse);

    controller().selectShop(state().candidates.single);
    expect(state().canSave, isFalse);
    controller().setRating(4);
    expect(state().canSave, isTrue);

    expect(await controller().save(), isTrue);

    final entry = (await visits()).single;
    expect(entry.shop.name, '麺屋テスト');
    expect(entry.shop.osmId, 'node/1');
    expect(entry.shop.latitude, 35.001);
    expect(entry.visit.rating, 4);
    expect(entry.visit.eatenAt, _photoTime);
    final photo = File(p.join(documents.path, entry.visit.photoPath!));
    expect(photo.readAsBytesSync(), [1, 2, 3]);
  });

  test('通信できないときは手入力で保存でき、現在地が店の位置になる', () async {
    overpass.error = const SocketException('offline');

    await controller().start();
    await pumpEventQueue();

    expect(state().searchStatus, ShopSearchStatus.done);
    expect(state().searchFailure, ShopSearchFailure.searchFailed);
    expect(state().candidates, isEmpty);

    controller().setManualName('電波のない店');
    controller().setRating(3);
    expect(await controller().save(), isTrue);

    final entry = (await visits()).single;
    expect(entry.shop.name, '電波のない店');
    expect(entry.shop.osmId, isNull);
    expect(entry.shop.latitude, 35.0);
    expect(entry.shop.longitude, 139.0);
  });

  test('検索が時間切れでも手入力で保存できる', () async {
    overpass.error = TimeoutException('timeout');

    await controller().start();
    await pumpEventQueue();
    controller().setManualName('遅い回線の店');
    controller().setRating(3);

    expect(state().searchFailure, ShopSearchFailure.searchFailed);
    expect(await controller().save(), isTrue);
    expect((await visits()).single.shop.name, '遅い回線の店');
  });

  test('位置情報が取れないときは検索せず、手入力で保存できる', () async {
    location
      ..ready = false
      ..position = null;

    await controller().start();
    await pumpEventQueue();

    expect(location.requests, [true]);
    expect(overpass.calls, 0);
    expect(state().searchFailure, ShopSearchFailure.noLocation);

    controller().setManualName('手入力の店');
    controller().setRating(5);
    expect(await controller().save(), isTrue);

    final entry = (await visits()).single;
    expect(entry.shop.name, '手入力の店');
    expect(entry.shop.latitude, isNull);
  });

  test('位置情報が許可済みなら、許可を尋ねずにカメラと並行して検索する', () async {
    await controller().start();
    await pumpEventQueue();

    expect(location.requests, [false]);
    expect(overpass.calls, 1);
  });

  test('候補が0件でも手入力で保存できる', () async {
    overpass.shops = const [];

    await controller().start();
    await pumpEventQueue();

    expect(state().candidates, isEmpty);
    expect(state().searchFailure, isNull);

    controller().setManualName('地図にない店');
    controller().setRating(2);
    expect(await controller().save(), isTrue);
  });

  test('カメラをキャンセルしても、写真なしで保存できる', () async {
    picker.cameraPath = null;

    await controller().start();
    await pumpEventQueue();

    expect(state().photoPath, isNull);
    expect(state().photoStepDone, isTrue);

    controller().setManualName('写真なしの店');
    controller().setRating(3);
    expect(await controller().save(), isTrue);

    final entry = (await visits()).single;
    expect(entry.visit.photoPath, isNull);
    expect(entry.visit.eatenAt, _photoTime);
  });

  test('ギャラリーから選んだ写真では、現在地を手入力の店の位置にしない', () async {
    picker.cameraPath = null;

    await controller().start();
    await controller().pickFromGallery();
    await pumpEventQueue();
    controller().setManualName('家で記録した店');
    controller().setRating(3);
    await controller().save();

    final entry = (await visits()).single;
    expect(entry.visit.photoPath, isNotNull);
    expect(entry.shop.latitude, isNull);
  });

  test('店名を入力すると候補の選択は外れ、記録済みの店が名前の候補に出る', () async {
    await container
        .read(recordRepositoryProvider)
        .saveEatenVisit(
          shop: const ShopInput(name: '行きつけの麺屋'),
          hoursType: HoursType.fewDays,
          eatenAt: DateTime(2026, 9, 1),
          rating: 5,
          now: DateTime(2026, 9, 1),
        );

    await controller().start();
    await pumpEventQueue();
    controller().selectShop(state().candidates.single);
    controller().setManualName('行きつけ');

    expect(state().selectedShop, isNull);
    expect(state().nameMatches.single.name, '行きつけの麺屋');

    controller().selectShop(state().nameMatches.single);
    controller().setRating(4);

    expect(state().manualName, '');
    expect(state().hoursType, HoursType.fewDays);
    expect(await controller().save(), isTrue);
    expect(
      await container.read(recordRepositoryProvider).allShops(),
      hasLength(1),
    );
    expect(await visits(), hasLength(2));
  });

  test('店と★が揃うまでは保存しない', () async {
    await controller().start();
    await pumpEventQueue();

    expect(await controller().save(), isFalse);
    controller().setRating(3);
    expect(await controller().save(), isFalse);
    controller().setManualName('   ');
    expect(await controller().save(), isFalse);
    expect(await visits(), isEmpty);
  });

  test('保存に失敗したら、コピーした写真を消して入力を続けられる', () async {
    await controller().start();
    await pumpEventQueue();
    controller().setManualName('麺屋');
    controller().setRating(3);
    await container.read(appDatabaseProvider).close();

    expect(await controller().save(), isFalse);

    expect(state().isSaving, isFalse);
    expect(state().canSave, isTrue);
    final photos = Directory(p.join(documents.path, 'photos'));
    expect(photos.listSync(), isEmpty);
  });
}
