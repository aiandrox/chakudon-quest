import '../records/models.dart';
import 'points.dart';

enum AdventurerRank {
  apprentice(0),
  traveler(200),
  hero(600),
  legend(1500);

  const AdventurerRank(this.requiredPoints);

  final int requiredPoints;

  /// 次のランク。最高ランクならnull。
  AdventurerRank? get next =>
      index + 1 < values.length ? values[index + 1] : null;
}

AdventurerRank adventurerRankFor(int totalPoints) => AdventurerRank.values
    .lastWhere((rank) => totalPoints >= rank.requiredPoints);

enum ShopRank {
  s(60),
  a(40),
  b(25),
  c(0);

  const ShopRank(this.requiredPoints);

  final int requiredPoints;
}

ShopRank shopRankFor(int bestPoints) =>
    ShopRank.values.firstWhere((rank) => bestPoints >= rank.requiredPoints);

/// 店ごとのランク。その店で得た最高ポイントで決まる。食べた記録の無い店は含めない。
Map<String, ShopRank> shopRanks(List<ScoredVisit> scored) {
  final best = <String, int>{};
  for (final entry in scored) {
    if (entry.visit.result != VisitResult.eaten) continue;
    final shopId = entry.visit.shopId;
    final points = entry.points.total;
    if (points > (best[shopId] ?? -1)) best[shopId] = points;
  }
  return best.map((shopId, points) => MapEntry(shopId, shopRankFor(points)));
}
