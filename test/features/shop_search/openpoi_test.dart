import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/openpoi.dart';
import 'package:chakudon_quest/features/shop_search/openpoi_client.dart';

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

    test('「麺屋」で拾ったパスタの店は除く', () {
      const body =
          '{"results":[{"name":"洋麺屋五右衛門 新宿東口店","lat":35.0,"lng":139.0},'
          '{"name":"麺屋海神","lat":35.0,"lng":139.0}]}';

      expect(parseOpenPoiResponse(body).single.name, '麺屋海神');
    });

    test('想定外の応答は失敗として扱う', () {
      expect(() => parseOpenPoiResponse('[]'), throwsFormatException);
      expect(() => parseOpenPoiResponse('{}'), throwsFormatException);
    });
  });

  test('buildOpenPoiUri は経度・緯度の順で中心を渡す', () {
    final uri = buildOpenPoiUri(
      const GeoPoint(35.69, 139.70),
      '中華そば',
      radiusMeters: 1000,
    );

    expect(uri.host, 'api.openpoiapi.com');
    expect(uri.queryParameters['center'], '139.7,35.69');
    expect(uri.queryParameters['radius'], '1000');
    expect(uri.queryParameters['q'], '中華そば');
  });

  group('OpenPoiClient', () {
    http.Response respond(List<Map<String, Object>> results) =>
        http.Response.bytes(utf8.encode(jsonEncode({'results': results})), 200);

    test('語ごとに探し、同じ店をまとめる', () async {
      final keywords = <String>[];
      final client = OpenPoiClient(
        MockClient((request) async {
          final keyword = request.url.queryParameters['q']!;
          keywords.add(keyword);
          return respond([
            if (keyword == 'ラーメン') {'name': '晴っぴ', 'lat': 35.0, 'lng': 139.0},
            if (keyword == '麺屋') ...[
              {'name': '麺屋藤ろう', 'lat': 35.001, 'lng': 139.0},
              {'name': '晴っぴ', 'lat': 35.0, 'lng': 139.0},
            ],
          ]);
        }),
      );

      final shops = await client.searchNearby(const GeoPoint(35.0, 139.0));

      expect(keywords, unorderedEquals(openPoiKeywords));
      expect(shops.map((s) => s.name), ['晴っぴ', '麺屋藤ろう']);
    });

    test('一部の語が失敗しても、ほかの語の結果を返す', () async {
      final client = OpenPoiClient(
        MockClient((request) async {
          if (request.url.queryParameters['q'] != '麺屋') {
            return http.Response('', 503);
          }
          return respond([
            {'name': '麺屋藤ろう', 'lat': 35.0, 'lng': 139.0},
          ]);
        }),
      );

      final shops = await client.searchNearby(const GeoPoint(35.0, 139.0));

      expect(shops.single.name, '麺屋藤ろう');
    });

    test('すべての語が失敗したら失敗にする', () {
      final client = OpenPoiClient(
        MockClient((_) async => http.Response('', 503)),
      );

      expect(
        client.searchNearby(const GeoPoint(35.0, 139.0)),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
