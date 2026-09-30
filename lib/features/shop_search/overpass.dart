import 'dart:convert';

import 'geo.dart';

const shopSearchRadiusMeters = 300;

const _nameKeywords = 'ラーメン|らーめん|拉麺|中華そば|麺|つけ麺';

class OverpassShop {
  const OverpassShop({
    required this.osmId,
    required this.name,
    required this.location,
  });

  final String osmId;
  final String name;
  final GeoPoint location;
}

String buildOverpassQuery(GeoPoint center, {int timeoutSeconds = 10}) {
  final around =
      '(around:$shopSearchRadiusMeters,${center.latitude},${center.longitude})';
  return '[out:json][timeout:$timeoutSeconds];'
      '('
      'nwr["cuisine"~"ramen"]$around;'
      'nwr["amenity"~"^(restaurant|fast_food)\$"]["name"~"$_nameKeywords"]$around;'
      ');'
      'out center tags;';
}

/// 名前か位置が無い要素は候補にできないため捨てる。
List<OverpassShop> parseOverpassResponse(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Overpassの応答がオブジェクトではありません');
  }
  final elements = decoded['elements'];
  if (elements is! List) {
    throw const FormatException('Overpassの応答にelementsがありません');
  }
  final shops = <OverpassShop>[];
  final seen = <String>{};
  for (final element in elements) {
    if (element is! Map<String, dynamic>) continue;
    final type = element['type'];
    final id = element['id'];
    if (type is! String || id is! num) continue;
    final tags = element['tags'];
    if (tags is! Map<String, dynamic>) continue;
    final name = _nonEmpty(tags['name']) ?? _nonEmpty(tags['name:ja']);
    if (name == null) continue;
    final center = element['center'];
    final position = center is Map<String, dynamic> ? center : element;
    final lat = position['lat'];
    final lon = position['lon'];
    if (lat is! num || lon is! num) continue;
    final osmId = '$type/${id.toInt()}';
    if (!seen.add(osmId)) continue;
    shops.add(
      OverpassShop(
        osmId: osmId,
        name: name,
        location: GeoPoint(lat.toDouble(), lon.toDouble()),
      ),
    );
  }
  return shops;
}

String? _nonEmpty(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
