import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'geo.dart';
import 'found_shop.dart';
import 'openpoi.dart';
import 'overpass_client.dart';

final openPoiClientProvider = Provider<OpenPoiClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenPoiClient(client);
});

class OpenPoiClient {
  OpenPoiClient(this._client);

  final http.Client _client;

  /// 語ごとに同時に探し、同じ店をまとめて返す。1語でも答えが返れば、その結果を使う。
  /// すべて失敗したときだけ例外にする。
  Future<List<FoundShop>> searchNearby(
    GeoPoint center, {
    int radiusMeters = shopSearchRadiusMeters,
    Duration timeout = OverpassClient.timeout,
  }) async {
    Object? lastError;
    final results = await Future.wait([
      for (final keyword in openPoiKeywords)
        _search(
          buildOpenPoiUri(center, keyword, radiusMeters: radiusMeters),
          timeout,
        ).then<List<FoundShop>?>(
          (shops) => shops,
          onError: (Object e) {
            lastError = e;
            return null;
          },
        ),
    ]);
    if (results.every((shops) => shops == null)) throw lastError!;
    return mergeFoundShops(const [], [for (final shops in results) ...?shops]);
  }

  /// 店名で全国から探す（過去の1杯を、あとから地図に載せるため）。
  Future<List<FoundShop>> searchByName(
    String name, {
    GeoPoint? near,
    Duration timeout = OverpassClient.timeout,
  }) async {
    final uri = buildOpenPoiNameUri(name, near: near);
    final response = await _client
        .get(uri, headers: const {'User-Agent': shopSearchUserAgent})
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'OpenPOI API: HTTP ${response.statusCode}',
        uri,
      );
    }
    return mergeFoundShops(
      const [],
      parseOpenPoiNameResults(utf8.decode(response.bodyBytes)),
    );
  }

  /// [location]のある市区町村（道中記で地名に触れるため）。わからなければnull。
  Future<String?> areaAt(
    GeoPoint location, {
    Duration timeout = OverpassClient.timeout,
  }) async {
    final uri = buildOpenPoiAreaUri(location);
    final response = await _client
        .get(uri, headers: const {'User-Agent': shopSearchUserAgent})
        .timeout(timeout);
    if (response.statusCode != 200) return null;
    return parseOpenPoiArea(utf8.decode(response.bodyBytes));
  }

  Future<List<FoundShop>> _search(Uri uri, Duration timeout) async {
    final response = await _client
        .get(uri, headers: const {'User-Agent': shopSearchUserAgent})
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'OpenPOI API: HTTP ${response.statusCode}',
        uri,
      );
    }
    // charset の無い application/json で返るため、http の既定（Latin-1）ではなく UTF-8 で読む。
    return parseOpenPoiResponse(utf8.decode(response.bodyBytes));
  }
}
