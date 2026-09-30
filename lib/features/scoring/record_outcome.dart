import '../quests/quests.dart';
import '../records/models.dart';
import 'points.dart';
import 'ranks.dart';

/// 1件の記録を保存した結果。得たポイントと、累計・ランクの変化。
class RecordOutcome {
  const RecordOutcome({
    required this.scored,
    required this.totalBefore,
    required this.totalAfter,
    this.achievedQuests = const [],
  });

  final ScoredVisit scored;
  final int totalBefore;
  final int totalAfter;

  /// この記録で新しく達成したクエスト。
  final List<Quest> achievedQuests;

  AdventurerRank get rankBefore => adventurerRankFor(totalBefore);

  AdventurerRank get rankAfter => adventurerRankFor(totalAfter);

  bool get isRankUp => rankAfter.index > rankBefore.index;
}

/// [visitId]の記録が無ければnull。累計の変化は、その記録が無かった場合との差で求める
/// （過去の日時の記録を足すと、ほかの記録の初訪問ボーナスが動くことがあるため）。
RecordOutcome? computeRecordOutcome(List<VisitWithShop> all, String visitId) {
  final scoredAll = scoreVisits(all);
  final scored = scoredAll.where((e) => e.visit.id == visitId).firstOrNull;
  if (scored == null) return null;
  final others = [
    for (final entry in all)
      if (entry.visit.id != visitId) entry,
  ];
  final scoredOthers = scoreVisits(others);
  return RecordOutcome(
    scored: scored,
    totalBefore: totalPoints(scoredOthers),
    totalAfter: totalPoints(scoredAll),
    achievedQuests: newlyAchievedQuests(
      before: evaluateQuests(scoredOthers),
      after: evaluateQuests(scoredAll),
    ),
  );
}
