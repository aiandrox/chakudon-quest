import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/openpoi.dart';

void main() {
  group('parseOpenPoiResponse', () {
    final sample = File('test/fixtures/openpoi_shinjuku.json')
        .readAsStringSync();

    test('保存した応答から名前と位置のある店を取り出す', () {
      final shops = parseOpenPoiResponse(sample);

      final hayashida = shops.firstWhere((s) => s.name == 'らぁ麺　はやし田');
      expect(hayashida.osmId, isNull);
      expect(hayashida.location.latitude, closeTo(35.690633647, 1e-9));
      expect(hayashida.dataSource!.licenses, [
        'CC BY 4.0',
        'CDLA-Permissive-2.0',
      ]);
      expect(
        hayashida.dataSource!.attributions,
        contains('東京都新宿区食品等営業許可・届出一覧'),
      );
    });

    test('位置が町丁目までしかわからない施設は捨てる', () {
      final shops = parseOpenPoiResponse(sample);

      // 23件のうち「♯新宿地下ラーメン」だけが level 3。
      expect(shops, hasLength(22));
      expect(shops.map((s) => s.name), isNot(contains('♯新宿地下ラーメン')));
    });

    test('座標の無い施設は捨てる', () {
      const body =
          '{"results":[{"name":"位置なし","lat":"","lng":""},'
          '{"name":"","lat":35.0,"lng":139.0},'
          '{"name":"麺屋","lat":35.0,"lng":139.0,"level":""}]}';

      expect(parseOpenPoiResponse(body).single.name, '麺屋');
    });

    test('想定外の応答は失敗として扱う', () {
      expect(() => parseOpenPoiResponse('[]'), throwsFormatException);
      expect(() => parseOpenPoiResponse('{}'), throwsFormatException);
    });
  });

  test('buildOpenPoiUri は経度・緯度の順で中心を渡す', () {
    final uri = buildOpenPoiUri(
      const GeoPoint(35.69, 139.70),
      radiusMeters: 1000,
    );

    expect(uri.host, 'api.openpoiapi.com');
    expect(uri.queryParameters['center'], '139.7,35.69');
    expect(uri.queryParameters['radius'], '1000');
    expect(uri.queryParameters['q'], contains('ラーメン'));
  });
}
