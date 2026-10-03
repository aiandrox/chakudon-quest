import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'found_shop.dart';
import 'geo.dart';
import 'overpass_client.dart';
import 'yahoo_local.dart';

final yahooLocalClientProvider = Provider<YahooLocalClient>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return YahooLocalClient(client);
});

/// Yahoo! ローカルサーチ。Client ID が無ければ問い合わせず、何も見つからなかったことにする。
class YahooLocalClient {
  YahooLocalClient(this._client, {this.appId = yahooAppId});

  final http.Client _client;
  final String appId;

  Future<List<FoundShop>> searchNearby(
    GeoPoint center, {
    int radiusMeters = shopSearchRadiusMeters,
    Duration timeout = OverpassClient.timeout,
  }) {
    if (appId.isEmpty) return Future.value(const []);
    return _get(
      buildYahooNearbyUri(center, radiusMeters: radiusMeters, appId: appId),
      timeout,
    );
  }

  Future<List<FoundShop>> searchByName(
    String name, {
    GeoPoint? near,
    Duration timeout = OverpassClient.timeout,
  }) {
    if (appId.isEmpty) return Future.value(const []);
    return _get(buildYahooNameUri(name, near: near, appId: appId), timeout);
  }

  Future<List<FoundShop>> _get(Uri uri, Duration timeout) async {
    final response = await _client
        .get(uri, headers: const {'User-Agent': shopSearchUserAgent})
        .timeout(timeout);
    if (response.statusCode != 200) {
      // 失敗の知らせに Client ID が入らないよう、アドレスは渡さない。
      throw http.ClientException(
        'Yahoo! local search: HTTP ${response.statusCode}',
      );
    }
    return parseYahooLocal(utf8.decode(response.bodyBytes));
  }
}
