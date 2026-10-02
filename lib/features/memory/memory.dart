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
/// うるう年でない年の2月28日には、2月29日の1杯も思い出す。
DayMemory? memoryOfTheDay(List<ScoredVisit> scored, DateTime today) {
  ScoredVisit? best;
  for (final entry in scored) {
    final at = entry.visit.eatenAt;
    if (entry.visit.result != VisitResult.eaten) continue;
    if (!_sameDay(at, today)) continue;
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

bool _sameDay(DateTime at, DateTime today) {
  if (at.month == today.month && at.day == today.day) return true;
  final isLeapYear = DateTime(today.year, 2, 29).month == 2;
  return !isLeapYear &&
      today.month == 2 &&
      today.day == 28 &&
      at.month == 2 &&
      at.day == 29;
}
