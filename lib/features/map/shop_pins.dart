import '../records/models.dart';
import '../scoring/points.dart';
import '../scoring/ranks.dart';

class ShopPin {
  const ShopPin({
    required this.shop,
    required this.latitude,
    required this.longitude,
    required this.eatenCount,
    required this.retreatCount,
    required this.lastVisitAt,
    this.rank,
  });

  final Shop shop;
  final double latitude;
  final double longitude;
  final int eatenCount;
  final int retreatCount;
  final DateTime lastVisitAt;

  /// 食べたことの無い（撤退だけの）店はnull。
  final ShopRank? rank;
}

/// 地図に立てるピン。位置のわからない店（ギャラリーの写真から手入力した店など）は出せない。
List<ShopPin> shopPins(List<ScoredVisit> scored) {
  final ranks = shopRanks(scored);
  final byShop = <String, List<ScoredVisit>>{};
  for (final entry in scored) {
    (byShop[entry.visit.shopId] ??= []).add(entry);
  }
  return [
    for (final entries in byShop.values)
      if (entries.first.shop case Shop(:final latitude?, :final longitude?))
        ShopPin(
          shop: entries.first.shop,
          latitude: latitude,
          longitude: longitude,
          eatenCount: entries
              .where((e) => e.visit.result == VisitResult.eaten)
              .length,
          retreatCount: entries
              .where((e) => e.visit.result == VisitResult.retreated)
              .length,
          lastVisitAt: entries
              .map((e) => e.visit.eatenAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          rank: ranks[entries.first.visit.shopId],
        ),
  ];
}
