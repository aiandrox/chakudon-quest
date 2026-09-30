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

  group('updateVisit', () {
    Future<void> update(
      Visit visit, {
      required String shopName,
      HoursType? hoursType,
      int? rating = 4,
      String memo = '',
    }) => repository.updateVisit(
      visitId: visit.id,
      shopName: shopName,
      hoursType: hoursType,
      eatenAt: visit.eatenAt,
      rating: rating,
      style: visit.style,
      isLimited: visit.isLimited,
      hasTicket: visit.hasTicket,
      memo: memo,
      now: DateTime(2026, 10, 1),
    );

    test('記録の内容と店の営業時間の種類を書き換える', () async {
      final visit = await save(const ShopInput(name: '麺屋'));

      await repository.updateVisit(
        visitId: visit.id,
        shopName: '麺屋',
        hoursType: HoursType.lunchOnly,
        eatenAt: DateTime(2026, 9, 29, 11),
        rating: 2,
        style: RamenStyle.miso,
        isLimited: true,
        hasTicket: true,
        memo: '書き直した',
        now: DateTime(2026, 10, 1),
      );

      final entry = (await repository.watchVisits().first).single;
      expect(entry.visit.id, visit.id);
      expect(entry.visit.eatenAt, DateTime(2026, 9, 29, 11));
      expect(entry.visit.rating, 2);
      expect(entry.visit.style, RamenStyle.miso);
      expect(entry.visit.isLimited, isTrue);
      expect(entry.visit.hasTicket, isTrue);
      expect(entry.visit.memo, '書き直した');
      expect(entry.shop.hoursType, HoursType.lunchOnly);
    });

    test('ほかに記録の無い手入力の店は、位置を残したまま名前を直す', () async {
      final visit = await save(
        const ShopInput(name: '麺やテスト', latitude: 35.0, longitude: 139.0),
      );

      await update(visit, shopName: ' 麺屋テスト ');

      final shop = (await repository.allShops()).single;
      expect(shop.id, visit.shopId);
      expect(shop.name, '麺屋テスト');
      expect(shop.latitude, 35.0);
    });

    test('ほかにも記録のある店の名前を変えると、その記録だけを新しい店に付け替える', () async {
      final first = await save(const ShopInput(name: '麺屋'));
      final second = await save(const ShopInput(name: '麺屋'));

      await update(second, shopName: '別の店');

      final visits = await repository.watchVisits().first;
      final names = {for (final v in visits) v.visit.id: v.shop.name};
      expect(names, {first.id: '麺屋', second.id: '別の店'});
      expect(await repository.allShops(), hasLength(2));
    });

    test('OSMの店を選び間違えたときは、元の店を書き換えずに付け替える', () async {
      final visit = await save(const ShopInput(osmId: 'node/1', name: '一風堂'));

      await update(visit, shopName: '本当に行った店');

      final shop = (await repository.allShops()).single;
      expect(shop.name, '本当に行った店');
      expect(shop.osmId, isNull);
    });

    test('記録済みの店の名前に変えると、その店の記録になる', () async {
      final known = await save(const ShopInput(osmId: 'node/1', name: '一風堂'));
      final visit = await save(const ShopInput(name: 'いっぷうどう'));

      await update(visit, shopName: '一風堂');

      final visits = await repository.watchVisits().first;
      expect(visits.map((v) => v.shop.id).toSet(), {known.shopId});
      expect(await repository.allShops(), hasLength(1));
    });

    test('営業時間の種類を変えずに別の店へ付け替えても、その店の値を変えない', () async {
      await save(const ShopInput(name: '週2日の店'), hoursType: HoursType.fewDays);
      await save(const ShopInput(name: '週2日の店'));
      final typo = await save(const ShopInput(name: '週2日のみせ'));

      await update(typo, shopName: '週2日の店');

      final shop = (await repository.allShops()).single;
      expect(shop.hoursType, HoursType.fewDays);
    });

    test('新しい店に付け替えるときは、元の店の営業時間の種類を引き継ぐ', () async {
      await save(const ShopInput(name: '麺屋'), hoursType: HoursType.lunchOnly);
      final second = await save(const ShopInput(name: '麺屋'));

      await update(second, shopName: '別の店');

      final shops = await repository.allShops();
      expect(
        {for (final shop in shops) shop.name: shop.hoursType},
        {'麺屋': HoursType.lunchOnly, '別の店': HoursType.lunchOnly},
      );
    });

    test('同じ名前の支店が複数あるときは、元の店に近い方へ付け替える', () async {
      final far = await save(
        const ShopInput(name: '一蘭', latitude: 35.05, longitude: 139.0),
      );
      final near = await save(
        const ShopInput(name: '一蘭', latitude: 35.001, longitude: 139.0),
      );
      final typo = await save(
        const ShopInput(name: 'いちらん', latitude: 35.0, longitude: 139.0),
      );

      await update(typo, shopName: '一蘭');

      final visits = await repository.watchVisits().first;
      final moved = visits.firstWhere((v) => v.visit.id == typo.id);
      expect(moved.shop.id, near.shopId);
      expect(moved.shop.id, isNot(far.shopId));
    });

    test('店名を空にしても元の店のままにする', () async {
      final visit = await save(const ShopInput(name: '麺屋'));

      await update(visit, shopName: '  ');

      expect((await repository.allShops()).single.name, '麺屋');
    });
  });

  group('deleteVisit', () {
    test('記録を削除して写真のパスを返し、記録の無くなった店も消す', () async {
      final visit = await repository.saveEatenVisit(
        shop: const ShopInput(name: '麺屋'),
        eatenAt: DateTime(2026, 9, 30),
        rating: 3,
        photoPath: 'photos/a.jpg',
        now: DateTime(2026, 9, 30),
      );

      expect(await repository.deleteVisit(visit.id), 'photos/a.jpg');
      expect(await repository.watchVisits().first, isEmpty);
      expect(await repository.allShops(), isEmpty);
    });

    test('ほかに記録のある店は残す', () async {
      final first = await save(const ShopInput(name: '麺屋'));
      final second = await save(const ShopInput(name: '麺屋'));

      await repository.deleteVisit(second.id);

      final visits = await repository.watchVisits().first;
      expect(visits.single.visit.id, first.id);
      expect(await repository.allShops(), hasLength(1));
    });

    test('無い記録の削除は何もしない', () async {
      expect(await repository.deleteVisit('missing'), isNull);
    });
  });

  group('チェックイン', () {
    final checkedInAt = DateTime(2026, 9, 30, 11, 20);
    const shop = ShopInput(
      osmId: 'node/1',
      name: '麺屋',
      latitude: 35.0,
      longitude: 139.0,
    );

    test('チェックインすると並んでいる店と時刻を読み出せ、取り消すと無くなる', () async {
      expect(await repository.activeCheckin(), isNull);

      await repository.checkIn(shop: shop, at: checkedInAt);

      final checkin = (await repository.activeCheckin())!;
      expect(checkin.name, '麺屋');
      expect(checkin.osmId, 'node/1');
      expect(checkin.latitude, 35.0);
      expect(checkin.checkedInAt, checkedInAt);
      expect((await repository.watchActiveCheckin().first)!.name, '麺屋');
      // チェックインだけでは店も記録も増やさない。
      expect(await repository.allShops(), isEmpty);

      await repository.cancelCheckin();
      expect(await repository.activeCheckin(), isNull);
      expect(await repository.watchActiveCheckin().first, isNull);
    });

    test('チェックイン中に別の店へチェックインすると置き換える', () async {
      await repository.checkIn(shop: shop, at: checkedInAt);
      await repository.checkIn(
        shop: const ShopInput(name: '別の店'),
        at: checkedInAt.add(const Duration(minutes: 5)),
      );

      expect((await repository.activeCheckin())!.name, '別の店');
    });

    test('チェックイン時刻つきで食べた記録を保存すると、チェックインを終える', () async {
      await repository.checkIn(shop: shop, at: checkedInAt);

      final visit = await repository.saveEatenVisit(
        shop: shop,
        eatenAt: checkedInAt.add(const Duration(minutes: 35)),
        checkedInAt: checkedInAt,
        rating: 4,
        now: checkedInAt.add(const Duration(minutes: 40)),
      );

      expect(visit.checkedInAt, checkedInAt);
      expect(await repository.activeCheckin(), isNull);
      final saved = (await repository.watchVisits().first).single.visit;
      expect(saved.checkedInAt, checkedInAt);
    });

    test('チェックイン時刻なしで別の店の記録を保存しても、チェックインは続く', () async {
      await repository.checkIn(shop: shop, at: checkedInAt);

      await save(const ShopInput(name: '別の店'));

      expect((await repository.activeCheckin())!.name, '麺屋');
    });

    test('撤退すると、食べられなかった記録を残してチェックインを終える', () async {
      await repository.checkIn(shop: shop, at: checkedInAt);
      final checkin = (await repository.activeCheckin())!;
      final now = checkedInAt.add(const Duration(minutes: 50));

      await repository.saveRetreat(checkin: checkin, memo: '売り切れ', now: now);

      final entry = (await repository.watchVisits().first).single;
      expect(entry.visit.result, VisitResult.retreated);
      expect(entry.visit.checkedInAt, checkedInAt);
      expect(entry.visit.eatenAt, now);
      expect(entry.visit.rating, isNull);
      expect(entry.visit.photoPath, isNull);
      expect(entry.visit.memo, '売り切れ');
      expect(entry.shop.name, '麺屋');
      expect(entry.shop.osmId, 'node/1');
      expect(await repository.activeCheckin(), isNull);
    });

    test('撤退した店で次に食べると、同じ店の記録になる', () async {
      await repository.checkIn(shop: shop, at: checkedInAt);
      final retreat = await repository.saveRetreat(
        checkin: (await repository.activeCheckin())!,
        now: checkedInAt,
      );

      final eaten = await save(shop);

      expect(eaten.shopId, retreat.shopId);
      expect(await repository.allShops(), hasLength(1));
    });
  });
}
