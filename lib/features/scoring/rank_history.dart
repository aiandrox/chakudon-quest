import 'points.dart';
import 'ranks.dart';

/// 段位に上がった記録。[visit]は累計がその段位の必要点に届いた1杯。
/// 入門は最初の記録（記録が無ければnull）。
class RankAttainment {
  const RankAttainment({required this.rank, required this.visit});

  final AdventurerRank rank;
  final ScoredVisit? visit;

  DateTime? get reachedAt => visit?.visit.eatenAt;
}

/// これまでに上がった段位を、低い順に返す。1杯で複数の段位を越えたときは、
/// 越えた段位すべてにその1杯をつける。[scored]は古い順（[scoreVisits]の結果）。
List<RankAttainment> rankHistory(List<ScoredVisit> scored) {
  final history = [
    RankAttainment(
      rank: AdventurerRank.apprentice,
      visit: scored.isEmpty ? null : scored.first,
    ),
  ];
  var total = 0;
  for (final entry in scored) {
    total += entry.points.total;
    for (
      var next = history.last.rank.next;
      next != null && total >= next.requiredPoints;
      next = next.next
    ) {
      history.add(RankAttainment(rank: next, visit: entry));
    }
  }
  return history;
}
