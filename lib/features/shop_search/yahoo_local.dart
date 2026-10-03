import 'dart:convert';

import '../records/models.dart';
import 'found_shop.dart';
import 'geo.dart';

/// Yahoo! ローカルサーチの Client ID。リポジトリは公開なのでコードには書かず、
/// ビルドのときに `--dart-define-from-file=env/local.json` で渡す。無ければ Yahoo! では探さない。
const yahooAppId = String.fromEnvironment('YAHOO_APP_ID');

bool get isYahooEnabled => yahooAppId.isNotEmpty;

/// 業種コード「グルメ > ラーメン」（ラーメン・つけ麺）。
const _ramenGenre = '0106';

const yahooAttribution = 'Web Services by Yahoo! JAPAN';

/// [center]から[radiusMeters]以内のラーメン店を、近い順に探す。
Uri buildYahooNearbyUri(
  GeoPoint center, {
  required int radiusMeters,
  String appId = yahooAppId,
}) => Uri.https('map.yahooapis.jp', '/search/local/V1/localSearch', {
  'appid': appId,
  'lat': '${center.latitude}',
  'lon': '${center.longitude}',
  // 半径は km で、最大 20km。
  'dist': '${(radiusMeters / 1000).clamp(0.1, 20)}',
  'gc': _ramenGenre,
  'sort': 'dist',
  'results': '100',
  'output': 'json',
});

/// 店名で全国のラーメン店を探す。[near]があれば近い順に並べる。
Uri buildYahooNameUri(
  String name, {
  GeoPoint? near,
  String appId = yahooAppId,
}) => Uri.https('map.yahooapis.jp', '/search/local/V1/localSearch', {
  'appid': appId,
  'query': name.trim(),
  'gc': _ramenGenre,
  'results': '30',
  'output': 'json',
  if (near != null) ...{
    'lat': '${near.latitude}',
    'lon': '${near.longitude}',
    'sort': 'dist',
  },
});

List<FoundShop> parseYahooLocal(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Yahoo!の応答がオブジェクトではありません');
  }
  // 見つからないときは Feature が無い。
  final features = decoded['Feature'] ?? const [];
  if (features is! List) {
    throw const FormatException('Yahoo!の応答のFeatureが読めません');
  }
  final shops = <FoundShop>[];
  for (final feature in features) {
    if (feature is! Map<String, dynamic>) continue;
    final name = feature['Name'];
    if (name is! String || name.trim().isEmpty) continue;
    final geometry = feature['Geometry'];
    final coordinates = geometry is Map<String, dynamic>
        ? geometry['Coordinates']
        : null;
    if (coordinates is! String) continue;
    // 「経度,緯度」の順。
    final parts = coordinates.split(',');
    if (parts.length != 2) continue;
    final lon = double.tryParse(parts[0]);
    final lat = double.tryParse(parts[1]);
    if (lat == null || lon == null) continue;
    final property = feature['Property'];
    if (!_isRamenShop(name, property)) continue;
    final address = property is Map<String, dynamic>
        ? property['Address']
        : null;
    shops.add(
      FoundShop(
        name: name.trim(),
        location: GeoPoint(lat, lon),
        address: address is String && address.trim().isNotEmpty
            ? address.trim()
            : null,
        dataSource: const ShopSource(attributions: [yahooAttribution]),
      ),
    );
  }
  return shops;
}

/// 業種でラーメンに絞っても、ラーメンも出す居酒屋などが混ざるため、
/// 主な業種（最初の業種）がラーメンの店か、名前がラーメン屋らしい店だけを残す。
bool _isRamenShop(String name, Object? property) {
  if (_ramenName.hasMatch(name)) return true;
  final genres = property is Map<String, dynamic> ? property['Genre'] : null;
  if (genres is! List || genres.isEmpty) return true;
  final first = genres.first;
  final code = first is Map<String, dynamic> ? first['Code'] : null;
  return code is String && code.startsWith(_ramenGenre);
}

final _ramenName = RegExp('ラーメン|らーめん|らぁ麺|らぁ麵|拉麺|中華そば|つけ麺|まぜそば|油そば|麺|麵');
