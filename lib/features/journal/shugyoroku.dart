import '../scoring/points.dart';
import 'journal.dart';

/// 修行録の1ページ（1杯）。
class ShugyorokuEntry {
  const ShugyorokuEntry({required this.scored, required this.journal});

  final ScoredVisit scored;
  final List<String> journal;
}

/// 修行録の1章（1か月）。
class ShugyorokuMonth {
  const ShugyorokuMonth({required this.month, required this.entries});

  final int month;
  final List<ShugyorokuEntry> entries;
}

/// 記録のある年（新しい順）。
List<int> shugyorokuYears(List<ScoredVisit> scored) =>
    {for (final entry in scored) entry.visit.eatenAt.year}.toList()
      ..sort((a, b) => b.compareTo(a));

/// [year]の道中記を、古い順に月ごとにまとめる（本のように頭から読めるように）。
/// 道中記は、その年より前も含めた全記録から組み立てる（何軒目・何度目などのため）。
List<ShugyorokuMonth> shugyoroku(List<ScoredVisit> scored, int year) {
  final months = <int, List<ShugyorokuEntry>>{};
  for (final entry in scored) {
    final at = entry.visit.eatenAt;
    if (at.year != year) continue;
    (months[at.month] ??= []).add(
      ShugyorokuEntry(scored: entry, journal: buildJournal(entry, scored)),
    );
  }
  return [
    for (final month in months.keys.toList()..sort())
      ShugyorokuMonth(month: month, entries: months[month]!),
  ];
}
