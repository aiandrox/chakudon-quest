import '../records/models.dart';
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

/// これまでに上がった段位を、低い順に返す。[scored]は古い順（[scoreVisits]の結果）。
/// 1杯で上がれるのは1つだけ（飛び級しない）。累計が先の段位に届いていても、
/// 次に食べた1杯ごとに1つずつ上がる。撤退の記録では上がらない。
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
    if (entry.visit.result != VisitResult.eaten) continue;
    final next = history.last.rank.next;
    if (next != null && total >= next.requiredPoints) {
      history.add(RankAttainment(rank: next, visit: entry));
    }
  }
  return history;
}

/// 今の段位。
AdventurerRank currentRank(List<ScoredVisit> scored) =>
    rankHistory(scored).last.rank;
