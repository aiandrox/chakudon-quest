import '../records/models.dart';
import 'points.dart';

/// 段位。入門から五級〜一級、初段〜九段を経て、師範代・免許皆伝へ。
/// 序盤ほど間隔を短くし、1杯目で五級、そのあとも1〜2杯ごとに昇級できるようにする。
enum AdventurerRank {
  apprentice(0),
  kyu5(15),
  kyu4(40),
  kyu3(70),
  kyu2(110),
  kyu1(160),
  dan1(220),
  dan2(300),
  dan3(400),
  dan4(520),
  dan5(660),
  dan6(820),
  dan7(1000),
  dan8(1300),
  dan9(1650),
  master(2100),
  grandmaster(2800);

  const AdventurerRank(this.requiredPoints);

  final int requiredPoints;

  /// 級（五級〜一級）か。
  bool get isKyu => index >= kyu5.index && index <= kyu1.index;

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
