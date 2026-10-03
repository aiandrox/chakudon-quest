import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../records/models.dart';
import 'builtin_shops.dart';
import 'found_shop.dart';
import 'geo.dart';
import 'overpass_client.dart';

/// 麺印帳のサーバー（Cloudflare Pages、issue #172）。`--dart-define=RAMEN_IN_CHO_API=` で空にすると使わない。
const ramenInChoApiBase = String.fromEnvironment(
  'RAMEN_IN_CHO_API',
  defaultValue: 'https://ramen-in-cho.aiandrox.com/api/v1',
);

final ramenInChoApiProvider = Provider<RamenInChoApi?>((ref) {
  if (ramenInChoApiBase.isEmpty) return null;
  final client = http.Client();
  ref.onDispose(client.close);
  return RamenInChoApi(client, base: Uri.parse(ramenInChoApiBase));
});

/// サーバーの応答（手で持つ店の一覧）。[shops]がnullなら、前に取った一覧から変わっていない（304）。
class CuratedShopsResponse {
  const CuratedShopsResponse({this.shops, this.etag});

  final List<BuiltinShop>? shops;
  final String? etag;
}

class RamenInChoApi {
  RamenInChoApi(this._client, {required this._base});

  /// 落ちているときに、端末から直接の検索へ早めに切り替えるため短くする。
  static const timeout = Duration(seconds: 6);

  final http.Client _client;
  final Uri _base;

  Uri _uri(String path, [Map<String, String>? query]) =>
      _base.replace(path: '${_base.path}$path', queryParameters: query);

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String> headers = const {},
    Duration timeout = RamenInChoApi.timeout,
  }) async {
    final response = await _client
        .get(uri, headers: {'User-Agent': shopSearchUserAgent, ...headers})
        .timeout(timeout);
    if (response.statusCode != 200 && response.statusCode != 304) {
      throw http.ClientException(
        'Ramen-In-Cho API: HTTP ${response.statusCode}',
        uri,
      );
    }
    return response;
  }

  /// 手で持つ店の一覧。[etag]が変わっていなければ一覧は返さない。
  Future<CuratedShopsResponse> curatedShops({String? etag}) async {
    final response = await _get(
      _uri('/curated-shops'),
      headers: {'If-None-Match': ?etag},
    );
    final newEtag = response.headers['etag'] ?? etag;
    if (response.statusCode == 304) return CuratedShopsResponse(etag: newEtag);
    return CuratedShopsResponse(
      shops: parseCuratedShops(utf8.decode(response.bodyBytes)),
      etag: newEtag,
    );
  }

  /// 近くの店（サーバーが手で持つ店・Overpass・OpenPOI・Yahoo! をまとめて返す）。
  Future<List<FoundShop>> searchNearby(
    GeoPoint center, {
    int radiusMeters = shopSearchRadiusMeters,
    Duration timeout = RamenInChoApi.timeout,
  }) async {
    final response = await _get(
      _uri('/shops/nearby', {
        'lat': '${center.latitude}',
        'lon': '${center.longitude}',
        'radius': '$radiusMeters',
      }),
      timeout: timeout,
    );
    return parseApiShops(utf8.decode(response.bodyBytes));
  }

  /// 店名で探す（空白の言い換えもサーバーで行う）。
  Future<List<FoundShop>> searchByName(
    String name, {
    GeoPoint? near,
    Duration timeout = RamenInChoApi.timeout,
  }) async {
    final response = await _get(
      _uri('/shops/search', {
        'q': name.trim(),
        if (near != null) 'lat': '${near.latitude}',
        if (near != null) 'lon': '${near.longitude}',
      }),
      timeout: timeout,
    );
    return parseApiShops(utf8.decode(response.bodyBytes));
  }
}

/// `/curated-shops` の応答。形の崩れた店は捨てる。
List<BuiltinShop> parseCuratedShops(String body) {
  final decoded = jsonDecode(body);
  final shops = decoded is Map<String, dynamic> ? decoded['shops'] : null;
  if (shops is! List) {
    throw const FormatException('curated-shops の応答に shops がありません');
  }
  return [
    for (final shop in shops)
      if (shop is Map<String, dynamic>) ?BuiltinShop.fromJson(shop),
  ];
}

/// `/shops/nearby`・`/shops/search` の応答。名前か位置の無い店は捨てる。
List<FoundShop> parseApiShops(String body) {
  final decoded = jsonDecode(body);
  final shops = decoded is Map<String, dynamic> ? decoded['shops'] : null;
  if (shops is! List) {
    throw const FormatException('店の検索の応答に shops がありません');
  }
  String? text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  List<String> strings(Object? value) => [
    if (value is List)
      for (final item in value)
        if (item is String) item,
  ];
  return [
    for (final shop in shops)
      if (shop is Map<String, dynamic>)
        if ((text(shop['name']), shop['latitude'], shop['longitude']) case (
          final String name,
          final num lat,
          final num lon,
        ))
          FoundShop(
            osmId: text(shop['osmId']),
            name: name,
            location: GeoPoint(lat.toDouble(), lon.toDouble()),
            address: text(shop['address']),
            openingHours: text(shop['openingHours']),
            dataSource: switch (shop['dataSource']) {
              final Map<String, dynamic> source => ShopSource(
                licenses: strings(source['licenses']),
                attributions: strings(source['attributions']),
              ),
              _ => null,
            },
          ),
  ];
}
