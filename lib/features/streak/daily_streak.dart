import '../records/models.dart';
import '../scoring/points.dart';

/// 隠し要素「毎日ラーメン健康生活」が出る連続日数。
const healthyLifeDays = 7;

/// 毎日続けて食べた日数の最高記録（同じ日に何杯食べても1日）。
int bestDailyStreak(List<ScoredVisit> scored) {
  final days = {
    for (final entry in scored)
      if (entry.visit.result == VisitResult.eaten)
        DateTime.utc(
          entry.visit.eatenAt.year,
          entry.visit.eatenAt.month,
          entry.visit.eatenAt.day,
        ),
  }.toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    run = previous != null && day.difference(previous).inDays == 1
        ? run + 1
        : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}
