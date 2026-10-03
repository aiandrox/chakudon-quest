import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'geo.dart';
import 'openpoi_client.dart';
import 'overpass.dart';
import 'overpass_client.dart';
import 'yahoo_local_client.dart';

final nearbyShopFinderProvider = Provider<NearbyShopFinder>(
  (ref) => NearbyShopFinder(
    overpass: ref.watch(overpassClientProvider),
    openPoi: ref.watch(openPoiClientProvider),
    yahoo: ref.watch(yahooLocalClientProvider),
  ),
);

/// Overpass・Yahoo!・OpenPOI を同時に探し、結果を1つにまとめる。
/// OpenStreetMap に載っていない個人店を、Yahoo!（ラーメン店の業種で絞れる）と
/// OpenPOI（食品営業許可のデータを含む）で補う。Yahoo! は Client ID があるときだけ使う。
class NearbyShopFinder {
  NearbyShopFinder({
    required this._overpass,
    required this._openPoi,
    this._yahoo,
  });

  final OverpassClient _overpass;
  final OpenPoiClient _openPoi;
  final YahooLocalClient? _yahoo;

  /// どれかが失敗しても、ほかの結果を返す。すべて失敗したときだけ例外にする。
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

    final yahoo = _yahoo;
    final [osm, poi, yahooShops] = await Future.wait([
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
      if (yahoo == null)
        Future<List<FoundShop>?>.value()
      else
        attempt(
          'Yahoo',
          () => yahoo.searchNearby(
            center,
            radiusMeters: radiusMeters,
            timeout: timeout,
          ),
        ),
    ]);
    if (osm == null && poi == null && yahooShops == null) {
      throw StateError('店の検索がすべて失敗しました');
    }
    // OpenStreetMap の店を優先し（IDがあるため）、次に Yahoo!、最後に OpenPOI。
    return mergeFoundShops(osm ?? const [], [...?yahooShops, ...?poi]);
  }
}
