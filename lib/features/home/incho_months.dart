import '../records/models.dart';

/// 印帳の1か月分（見出しの下に、その月の1杯を並べる）。
class InchoMonth {
  const InchoMonth({required this.month, required this.entries});

  /// その月の1日。
  final DateTime month;
  final List<VisitWithShop> entries;
}

/// 新しい順の記録を、月ごとにまとめる（新しい月から）。
List<InchoMonth> inchoMonths(List<VisitWithShop> entries) {
  final months = <InchoMonth>[];
  for (final entry in entries) {
    final at = entry.visit.eatenAt;
    final month = DateTime(at.year, at.month);
    if (months.isEmpty || months.last.month != month) {
      months.add(InchoMonth(month: month, entries: [entry]));
    } else {
      months.last.entries.add(entry);
    }
  }
  return months;
}
