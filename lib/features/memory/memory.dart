import '../records/models.dart';
import '../scoring/points.dart';

/// 何年か前の今日に食べた1杯。
class DayMemory {
  const DayMemory({
    required this.scored,
    required this.yearsAgo,
    required this.notVisitedSince,
  });

  final ScoredVisit scored;
  final int yearsAgo;

  /// あれからその店で一度も食べていないか。
  final bool notVisitedSince;
}

/// [today]と同じ月日に、前の年に食べた1杯。いちばん近い年のものを返す。無ければnull。
DayMemory? memoryOfTheDay(List<ScoredVisit> scored, DateTime today) {
  ScoredVisit? best;
  for (final entry in scored) {
    final at = entry.visit.eatenAt;
    if (entry.visit.result != VisitResult.eaten) continue;
    if (at.month != today.month || at.day != today.day) continue;
    if (at.year >= today.year) continue;
    if (best == null || at.year > best.visit.eatenAt.year) best = entry;
  }
  final memory = best;
  if (memory == null) return null;
  final since = memory.visit.eatenAt;
  return DayMemory(
    scored: memory,
    yearsAgo: today.year - since.year,
    notVisitedSince: !scored.any(
      (e) =>
          e.visit.result == VisitResult.eaten &&
          e.visit.shopId == memory.visit.shopId &&
          e.visit.eatenAt.isAfter(since),
    ),
  );
}
