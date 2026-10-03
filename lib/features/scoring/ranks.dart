import '../records/models.dart';
import 'points.dart';

/// 段位。入門から初段〜九段を経て、師範代・免許皆伝へ。序盤ほど間隔を短くし、数杯で昇段できるようにする。
enum AdventurerRank {
  apprentice(0),
  dan1(50),
  dan2(120),
  dan3(200),
  dan4(300),
  dan5(450),
  dan6(650),
  dan7(900),
  dan8(1200),
  dan9(1600),
  master(2100),
  grandmaster(2800);

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
