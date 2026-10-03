import 'dart:convert';

import '../records/models.dart';
import 'found_shop.dart';
import 'geo.dart';

/// 1語ずつ別に探して結果をまとめる。/v1/search に複数の語を空白でつないで渡すと、
/// 「ラーメン」のような分類に当たる語があるとほかの語が無視され、「麺屋藤ろう」などを取りこぼすため。
/// 「麺」だけだとパスタやフォーも拾うので、ラーメンらしい語に絞る（「らーめん」は「ラーメン」と同じ結果になる）。
const openPoiKeywords = ['ラーメン', 'らぁ麺', '中華そば', 'つけ麺', 'まぜそば', '油そば', '麺屋'];

/// 「麺屋」で拾ってしまうパスタの店を除く。
const _notRamenNameParts = ['洋麺', 'パスタ', 'スパゲッティ'];

Uri buildOpenPoiUri(
  GeoPoint center,
  String keyword, {
  int radiusMeters = shopSearchRadiusMeters,
  int limit = 100,
}) {
  return Uri.https('api.openpoiapi.com', '/v1/search', {
    'q': keyword,
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
    if (_notRamenNameParts.any(name.contains)) continue;
    final lat = result['lat'];
    final lng = result['lng'];
    if (lat is! num || lng is! num) continue;
    final level = result['level'];
    if (level is num && level < _minGeocodingLevel) continue;
    shops.add(
      FoundShop(
        name: name.trim(),
        location: GeoPoint(lat.toDouble(), lng.toDouble()),
        dataSource: ShopSource(
          licenses: _strings(result['licenses']),
          attributions: _strings(result['attributions']),
        ),
        address: _address(result),
      ),
    );
  }
  return shops;
}

List<String> _strings(Object? value) =>
    value is List ? [...value.whereType<String>()] : const [];

/// 住所があればそれを、無ければ都道府県と市区町村をつなぐ。
String? _address(Map<String, dynamic> result) {
  String text(String key) =>
      result[key] is String ? (result[key] as String).trim() : '';
  final address = text('address');
  if (address.isNotEmpty) return address;
  final area = '${text('prefecture')}${text('city')}';
  return area.isEmpty ? null : area;
}

/// 店名で探す（全国）。[near]があれば、そこから近い順に並ぶ。
Uri buildOpenPoiNameUri(String name, {GeoPoint? near}) =>
    Uri.https('api.openpoiapi.com', '/v1/search', {
      'q': name.trim(),
      'limit': '30',
      if (near != null) 'center': '${near.longitude},${near.latitude}',
      // 既定の50kmより広く、国内のどこでも見つかるようにする。
      if (near != null) 'radius': '2000000',
    });

/// 位置のまわりの施設を数件だけ取り、その場所の市区町村を知るための問い合わせ。
Uri buildOpenPoiAreaUri(GeoPoint location) =>
    Uri.https('api.openpoiapi.com', '/v1/search', {
      'center': '${location.longitude},${location.latitude}',
      'radius': '300',
      'limit': '10',
    });

/// まわりの施設でいちばん多い市区町村。わからなければnull。
String? parseOpenPoiArea(String body) {
  final decoded = jsonDecode(body);
  final results = decoded is Map<String, dynamic> ? decoded['results'] : null;
  if (results is! List) return null;
  final counts = <String, int>{};
  for (final result in results) {
    if (result is! Map<String, dynamic>) continue;
    final city = result['city'];
    if (city is! String || city.trim().isEmpty) continue;
    counts.update(city.trim(), (n) => n + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}
