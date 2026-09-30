import '../records/models.dart';
import 'geo.dart';
import 'overpass.dart';

const maxShopCandidates = 3;

class ShopCandidate {
  const ShopCandidate({
    this.shopId,
    this.osmId,
    required this.name,
    this.location,
    this.distanceMeters,
    this.hoursConditions,
    this.strategyMemo = '',
  });

  factory ShopCandidate.fromShop(Shop shop, {double? distanceMeters}) {
    final latitude = shop.latitude;
    final longitude = shop.longitude;
    return ShopCandidate(
      shopId: shop.id,
      osmId: shop.osmId,
      name: shop.name,
      location: latitude != null && longitude != null
          ? GeoPoint(latitude, longitude)
          : null,
      distanceMeters: distanceMeters,
      hoursConditions: shop.hoursConditions,
      strategyMemo: shop.strategyMemo,
    );
  }

  /// 記録済みの店のID。初めての店はnull。
  final String? shopId;
  final String? osmId;
  final String name;
  final GeoPoint? location;
  final double? distanceMeters;

  /// 記録済みの店の営業の条件。初めての店はnull。
  final Set<HoursCondition>? hoursConditions;

  /// 記録済みの店の攻略メモ。
  final String strategyMemo;
}

/// 2つの候補が同じ店を指すか。IDで比べられないときは、名前と近さで判断する。
bool isSameShop(ShopCandidate a, ShopCandidate b) {
  if (a.shopId != null && b.shopId != null) return a.shopId == b.shopId;
  if (a.osmId != null && b.osmId != null) return a.osmId == b.osmId;
  if (a.name != b.name) return false;
  final aLocation = a.location;
  final bLocation = b.location;
  if (aLocation == null || bLocation == null) return true;
  return distanceMeters(aLocation, bLocation) <= shopSearchRadiusMeters;
}

/// 検索結果と記録済みの店を合わせ、半径内のものを近い順に最大[limit]件返す。
/// 同じ店が両方にあるときは記録済みの方を残す。
List<ShopCandidate> rankShopCandidates({
  required GeoPoint here,
  required List<OverpassShop> found,
  required List<Shop> knownShops,
  int radiusMeters = shopSearchRadiusMeters,
  int limit = maxShopCandidates,
}) {
  final candidates = <ShopCandidate>[];
  final knownOsmIds = <String>{};
  final knownNames = <String>{};
  for (final shop in knownShops) {
    final candidate = ShopCandidate.fromShop(shop);
    final location = candidate.location;
    if (location == null) continue;
    final distance = distanceMeters(here, location);
    if (distance > radiusMeters) continue;
    candidates.add(ShopCandidate.fromShop(shop, distanceMeters: distance));
    if (shop.osmId != null) knownOsmIds.add(shop.osmId!);
    knownNames.add(shop.name);
  }
  for (final shop in found) {
    if (knownOsmIds.contains(shop.osmId)) continue;
    if (knownNames.contains(shop.name)) continue;
    final distance = distanceMeters(here, shop.location);
    if (distance > radiusMeters) continue;
    candidates.add(
      ShopCandidate(
        osmId: shop.osmId,
        name: shop.name,
        location: shop.location,
        distanceMeters: distance,
      ),
    );
  }
  candidates.sort((a, b) => a.distanceMeters!.compareTo(b.distanceMeters!));
  return candidates.take(limit).toList();
}
