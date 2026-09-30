import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';

import '../../support/fakes.dart';

void main() {
  late RecordRepository repository;

  setUp(() {
    repository = RecordRepository(createTestDatabase());
  });

  Future<Visit> save(
    ShopInput shop, {
    DateTime? eatenAt,
    HoursType? hoursType,
  }) => repository.saveEatenVisit(
    shop: shop,
    hoursType: hoursType,
    eatenAt: eatenAt ?? DateTime(2026, 9, 30, 12),
    rating: 4,
    now: DateTime(2026, 9, 30, 12, 5),
  );

  test('記録を保存すると店と一緒に読み出せる', () async {
    await repository.saveEatenVisit(
      shop: const ShopInput(
        osmId: 'node/1',
        name: '麺屋テスト',
        latitude: 35.0,
        longitude: 139.0,
      ),
      hoursType: HoursType.lunchOnly,
      eatenAt: DateTime(2026, 9, 30, 12),
      rating: 5,
      photoPath: 'photos/a.jpg',
      style: RamenStyle.shoyu,
      isLimited: true,
      hasTicket: true,
      memo: 'うまい',
      now: DateTime(2026, 9, 30, 12, 5),
    );

    final entry = (await repository.watchVisits().first).single;

    expect(entry.shop.name, '麺屋テスト');
    expect(entry.shop.osmId, 'node/1');
    expect(entry.shop.latitude, 35.0);
    expect(entry.shop.hoursType, HoursType.lunchOnly);
    expect(entry.visit.result, VisitResult.eaten);
    expect(entry.visit.photoPath, 'photos/a.jpg');
    expect(entry.visit.eatenAt, DateTime(2026, 9, 30, 12));
    expect(entry.visit.checkedInAt, isNull);
    expect(entry.visit.style, RamenStyle.shoyu);
    expect(entry.visit.rating, 5);
    expect(entry.visit.isLimited, isTrue);
    expect(entry.visit.hasTicket, isTrue);
    expect(entry.visit.memo, 'うまい');
  });

  test('任意の項目を省いた手入力の店の記録を保存できる', () async {
    await save(const ShopInput(name: ' 手入力の店 '));

    final entry = (await repository.watchVisits().first).single;

    expect(entry.shop.name, '手入力の店');
    expect(entry.shop.osmId, isNull);
    expect(entry.shop.latitude, isNull);
    expect(entry.visit.photoPath, isNull);
    expect(entry.visit.style, isNull);
    expect(entry.visit.isLimited, isFalse);
    expect(entry.visit.memo, '');
  });

  test('記録は食べた時刻の新しい順に並ぶ', () async {
    await save(const ShopInput(name: '古い'), eatenAt: DateTime(2026, 9, 1));
    await save(const ShopInput(name: '新しい'), eatenAt: DateTime(2026, 9, 30));
    await save(const ShopInput(name: '中間'), eatenAt: DateTime(2026, 9, 15));

    final visits = await repository.watchVisits().first;

    expect(visits.map((v) => v.shop.name), ['新しい', '中間', '古い']);
  });

  test('同じOSMの店の2回目は店を増やさない', () async {
    final first = await save(const ShopInput(osmId: 'node/1', name: '麺屋'));
    final second = await save(const ShopInput(osmId: 'node/1', name: '麺屋'));

    expect(second.shopId, first.shopId);
    expect(await repository.allShops(), hasLength(1));
  });

  test('同じ名前の手入力の店の2回目は店を増やさない', () async {
    final first = await save(const ShopInput(name: '手入力の店'));
    final second = await save(const ShopInput(name: '手入力の店 '));
    final other = await save(const ShopInput(name: '別の店'));

    expect(second.shopId, first.shopId);
    expect(other.shopId, isNot(first.shopId));
    expect(await repository.allShops(), hasLength(2));
  });

  test('営業時間の種類を選ばずに保存しても、記録済みの店の値は変えない', () async {
    await save(const ShopInput(name: '麺屋'), hoursType: HoursType.fewDays);
    await save(const ShopInput(name: '麺屋'));

    expect((await repository.allShops()).single.hoursType, HoursType.fewDays);
  });

  test('同じ名前でも300mより離れた手入力の店は別の店にする', () async {
    const here = ShopInput(name: '一蘭', latitude: 35.0, longitude: 139.0);
    const near = ShopInput(name: '一蘭', latitude: 35.002, longitude: 139.0);
    const far = ShopInput(name: '一蘭', latitude: 35.01, longitude: 139.0);
    final first = await save(here);

    expect((await save(near)).shopId, first.shopId);
    expect((await save(far)).shopId, isNot(first.shopId));
    expect(await repository.allShops(), hasLength(2));
  });

  test('位置のわからない手入力の店は、同じ名前の店と同じ店として扱う', () async {
    final first = await save(
      const ShopInput(name: '麺屋', latitude: 35.0, longitude: 139.0),
    );

    expect((await save(const ShopInput(name: '麺屋'))).shopId, first.shopId);
  });

  test('手入力で記録した店をあとから検索結果で選ぶと、同じ店に位置とIDを補う', () async {
    final first = await save(const ShopInput(name: '麺屋'));
    final second = await save(
      const ShopInput(
        osmId: 'node/1',
        name: '麺屋',
        latitude: 35.0,
        longitude: 139.0,
      ),
    );

    final shop = (await repository.allShops()).single;
    expect(second.shopId, first.shopId);
    expect(shop.osmId, 'node/1');
    expect(shop.latitude, 35.0);
  });

  test('同じ名前でも別のOSMの店は別の店にする', () async {
    final first = await save(const ShopInput(osmId: 'node/1', name: '一風堂'));
    final second = await save(const ShopInput(osmId: 'node/2', name: '一風堂'));

    expect(second.shopId, isNot(first.shopId));
  });

  test('記録済みの店をIDで指定でき、営業時間の種類の変更は店に反映する', () async {
    final first = await save(const ShopInput(name: '麺屋'));
    final second = await save(
      ShopInput(shopId: first.shopId, name: '麺屋'),
      hoursType: HoursType.fewDays,
    );

    final shops = await repository.allShops();
    expect(second.shopId, first.shopId);
    expect(shops.single.hoursType, HoursType.fewDays);
  });
}
