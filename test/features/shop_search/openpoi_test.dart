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

  group('店名で探す', () {
    test('全国から探し、近い順の基準があれば中心を渡す', () {
      final nationwide = buildOpenPoiNameUri(' 藤ろう ');
      expect(nationwide.queryParameters['q'], '藤ろう');
      expect(nationwide.queryParameters.containsKey('center'), isFalse);

      final near = buildOpenPoiNameUri(
        '藤ろう',
        near: const GeoPoint(35.69, 139.70),
      );
      expect(near.queryParameters['center'], '139.7,35.69');
    });

    test('同じ店をまとめ、住所が無ければ都道府県と市区町村を添える', () async {
      final client = OpenPoiClient(
        MockClient(
          (_) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'suggestions': [
                  {
                    'name': '麺屋藤ろう',
                    'prefecture': '神奈川県',
                    'city': '厚木市',
                    'address': '',
                    'lat': 35.44,
                    'lng': 139.36,
                  },
                  {
                    'name': '麺屋 藤ろう',
                    'address': '神奈川県厚木市中町',
                    'lat': 35.4401,
                    'lng': 139.36,
                  },
                  {
                    'name': '藤ろう',
                    'address': '埼玉県加須市',
                    'lat': 36.1,
                    'lng': 139.6,
                  },
                ],
              }),
            ),
            200,
          ),
        ),
      );

      final shops = await client.searchByName('藤ろう');

      expect(shops.map((s) => s.name), ['麺屋藤ろう', '藤ろう']);
      expect(shops.first.address, '神奈川県厚木市');
      expect(shops.last.address, '埼玉県加須市');
    });
  });

  test('まわりの施設でいちばん多い市区町村を、その場所の地名にする', () {
    expect(
      parseOpenPoiArea(
        '{"results":[{"city":"厚木市"},{"city":""},{"city":"厚木市"},'
        '{"city":"海老名市"}]}',
      ),
      '厚木市',
    );
    expect(parseOpenPoiArea('{"results":[]}'), isNull);
    expect(
      buildOpenPoiAreaUri(const GeoPoint(35.44, 139.36)).queryParameters,
      containsPair('center', '139.36,35.44'),
    );
  });

  test('店名で探した結果は、飲食店でない施設を除き、ラーメン屋らしい店を先に並べる', () {
    final shops = parseOpenPoiNameResults(
      jsonEncode({
        'suggestions': [
          {'name': '藤の家', 'category': 'restaurant', 'lat': 35.0, 'lng': 139.0},
          {
            'name': '藤森工業',
            'category': 'retail_other',
            'lat': 35.0,
            'lng': 139.0,
          },
          {'name': '藤井施術院', 'category': 'medical', 'lat': 35.0, 'lng': 139.0},
          {
            'name': '麺屋藤ろう',
            'category': 'restaurant',
            'lat': 35.1,
            'lng': 139.0,
          },
          {'name': '藤ストアー', 'category': 'unknown', 'lat': 35.2, 'lng': 139.0},
        ],
      }),
    );

    expect(shops.map((s) => s.name), ['麺屋藤ろう', '藤の家', '藤ストアー']);
  });

  test('店名で探すときは、すべての語に合う店だけを返す窓口を使う', () {
    final uri = buildOpenPoiNameUri('麺屋 藤ろう');
    expect(uri.path, '/v1/suggest');
    expect(uri.queryParameters['q'], '麺屋 藤ろう');
  });
}
