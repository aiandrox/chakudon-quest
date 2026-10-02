import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../records/models.dart';
import '../records/record_repository.dart';
import '../wishes/wish_repository.dart';
import 'geo.dart';
import 'location_service.dart';
import 'nearby_shop_finder.dart';
import 'overpass.dart';
import 'shop_candidate.dart';

final shopSearchServiceProvider = Provider<ShopSearchService>(
  (ref) => ShopSearchService(
    location: ref.watch(locationServiceProvider),
    finder: ref.watch(nearbyShopFinderProvider),
    repository: ref.watch(recordRepositoryProvider),
    wishes: ref.watch(wishRepositoryProvider),
  ),
);

enum ShopSearchFailure { noLocation, searchFailed }

class ShopSearchResult {
  const ShopSearchResult({this.here, this.candidates = const [], this.failure});

  final GeoPoint? here;
  final List<ShopCandidate> candidates;
  final ShopSearchFailure? failure;
}

/// 現在地（または[near]）の近くの店を、検索結果と記録済みの店から探す。
/// 失敗は例外にせず結果で返す。
class ShopSearchService {
  ShopSearchService({
    required this._location,
    required this._finder,
    required this._repository,
    required this._wishes,
  });

  final LocationService _location;
  final NearbyShopFinder _finder;
  final RecordRepository _repository;
  final WishRepository _wishes;

  Future<ShopSearchResult> search({
    required bool requestPermission,
    GeoPoint? near,
  }) async {
    final here =
        near ??
        await _location.currentPosition(requestPermission: requestPermission);
    if (here == null) {
      return const ShopSearchResult(failure: ShopSearchFailure.noLocation);
    }
    var found = const <FoundShop>[];
    ShopSearchFailure? failure;
    try {
      found = await _finder.searchNearby(here);
    } catch (e) {
      debugPrint('Shop search failed: $e');
      failure = ShopSearchFailure.searchFailed;
    }
    var knownShops = const <Shop>[];
    try {
      knownShops = await _repository.allShops();
    } catch (e) {
      debugPrint('Known shops load failed: $e');
    }
    var wishes = const <Wish>[];
    try {
      wishes = await _wishes.pendingWishes();
    } catch (e) {
      debugPrint('Wishes load failed: $e');
    }
    return ShopSearchResult(
      here: here,
      failure: failure,
      candidates: rankShopCandidates(
        here: here,
        found: found,
        knownShops: knownShops,
        wishes: wishes,
      ),
    );
  }
}
