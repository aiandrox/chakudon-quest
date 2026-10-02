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
