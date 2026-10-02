import 'dart:convert';

import 'found_shop.dart';
import 'geo.dart';

/// OpenPOI の /v1/search は語を OR で探す。「麺」だけだとパスタやフォーも拾うため、ラーメンらしい語に絞る。
const openPoiKeywords = 'ラーメン らーめん らぁ麺 拉麺 中華そば つけ麺 まぜそば 油そば 麺屋';

Uri buildOpenPoiUri(
  GeoPoint center, {
  int radiusMeters = shopSearchRadiusMeters,
  int limit = 100,
}) {
  return Uri.https('api.openpoiapi.com', '/v1/search', {
    'q': openPoiKeywords,
    'center': '${center.longitude},${center.latitude}',
    'radius': '$radiusMeters',
    'limit': '$limit',
  });
}

/// 住所から位置を推定した施設は、精度が町丁目（level 3）以下だと数百 m ずれるため捨てる。
const _minGeocodingLevel = 8;

List<FoundShop> parseOpenPoiResponse(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('OpenPOIの応答がオブジェクトではありません');
  }
  final results = decoded['results'];
  if (results is! List) {
    throw const FormatException('OpenPOIの応答にresultsがありません');
  }
  final shops = <FoundShop>[];
  for (final result in results) {
    if (result is! Map<String, dynamic>) continue;
    final name = result['name'];
    if (name is! String || name.trim().isEmpty) continue;
    final lat = result['lat'];
    final lng = result['lng'];
    if (lat is! num || lng is! num) continue;
    final level = result['level'];
    if (level is num && level < _minGeocodingLevel) continue;
    shops.add(
      FoundShop(
        name: name.trim(),
        location: GeoPoint(lat.toDouble(), lng.toDouble()),
      ),
    );
  }
  return shops;
}
