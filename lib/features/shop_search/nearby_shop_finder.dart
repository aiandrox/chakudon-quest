import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geo.dart';
import 'openpoi_client.dart';
import 'overpass.dart';
import 'overpass_client.dart';

final nearbyShopFinderProvider = Provider<NearbyShopFinder>(
  (ref) => NearbyShopFinder(
    overpass: ref.watch(overpassClientProvider),
    openPoi: ref.watch(openPoiClientProvider),
  ),
);

/// Overpass と OpenPOI を同時に探し、結果を1つにまとめる。
/// OpenStreetMap に載っていない個人店を OpenPOI（食品営業許可のデータを含む）で補う。
class NearbyShopFinder {
  NearbyShopFinder({required this._overpass, required this._openPoi});

  final OverpassClient _overpass;
  final OpenPoiClient _openPoi;

  /// 片方が失敗しても、もう片方の結果を返す。両方失敗したときだけ例外にする。
  Future<List<FoundShop>> searchNearby(
    GeoPoint center, {
    int radiusMeters = shopSearchRadiusMeters,
    Duration timeout = OverpassClient.timeout,
  }) async {
    Future<List<FoundShop>?> attempt(
      String label,
      Future<List<FoundShop>> Function() search,
    ) async {
      try {
        return await search();
      } catch (e) {
        debugPrint('$label search failed: $e');
        return null;
      }
    }

    final [osm, poi] = await Future.wait([
      attempt(
        'Overpass',
        () => _overpass.searchNearby(
          center,
          radiusMeters: radiusMeters,
          timeout: timeout,
        ),
      ),
      attempt(
        'OpenPOI',
        () => _openPoi.searchNearby(
          center,
          radiusMeters: radiusMeters,
          timeout: timeout,
        ),
      ),
    ]);
    if (osm == null && poi == null) {
      throw StateError('Overpass と OpenPOI の検索がどちらも失敗しました');
    }
    return mergeFoundShops(osm ?? const [], poi ?? const []);
  }
}

/// 同じ店とみなす距離。同じ名前の別の支店（数百 m 離れている）と混ざらない程度に狭くする。
const _sameShopMeters = 100;

/// OpenStreetMap の店を優先し（ID があるため）、OpenPOI の店は重ならないものだけ足す。
/// OpenPOI には ID が無く、同じ店が業種違いで複数件になることもあるため、名前と近さで重なりを判定する。
List<FoundShop> mergeFoundShops(List<FoundShop> osm, List<FoundShop> poi) {
  final merged = [...osm];
  for (final shop in poi) {
    if (merged.any((other) => _looksSame(shop, other))) continue;
    merged.add(shop);
  }
  return merged;
}

bool _looksSame(FoundShop a, FoundShop b) {
  if (distanceMeters(a.location, b.location) > _sameShopMeters) return false;
  final aName = normalizeShopName(a.name);
  final bName = normalizeShopName(b.name);
  final (shorter, longer) = aName.length <= bName.length
      ? (aName, bName)
      : (bName, aName);
  return shorter.length >= 2 && longer.contains(shorter);
}

/// 空白を除き、全角英数を半角に、英字を小文字にそろえる（「鴨 to 葱」と「らーめん鴨to葱」を比べるため）。
@visibleForTesting
String normalizeShopName(String name) {
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    if (rune == 0x20 || rune == 0x3000) continue;
    final ascii = rune >= 0xFF01 && rune <= 0xFF5E ? rune - 0xFEE0 : rune;
    buffer.writeCharCode(ascii);
  }
  return buffer.toString().toLowerCase();
}
