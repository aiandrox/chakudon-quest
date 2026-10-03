import 'package:flutter_test/flutter_test.dart';
import 'package:ramen_in_cho/features/shop_search/found_shop.dart';
import 'package:ramen_in_cho/features/shop_search/geo.dart';

void main() {
  group('nearestFirst', () {
    const shinjuku = GeoPoint(35.69, 139.70);
    const kichijoji = FoundShop(
      name: '麺屋武蔵 虎洞',
      location: GeoPoint(35.7039, 139.579),
    );
    const honten = FoundShop(
      name: '麺屋武蔵 本店',
      location: GeoPoint(35.6936, 139.6977),
    );

    test('場所があれば近い順に並べる', () {
      expect(nearestFirst([kichijoji, honten], shinjuku).map((s) => s.name), [
        '麺屋武蔵 本店',
        '麺屋武蔵 虎洞',
      ]);
    });

    test('場所が無ければ並びを変えない', () {
      expect(nearestFirst([kichijoji, honten], null).map((s) => s.name), [
        '麺屋武蔵 虎洞',
        '麺屋武蔵 本店',
      ]);
    });
  });
}
