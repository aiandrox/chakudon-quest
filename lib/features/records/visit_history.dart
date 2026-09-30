import 'models.dart';

/// 同じ店での、[visit]のひとつ前の記録。無ければnull。
VisitWithShop? previousVisitAtShop(List<VisitWithShop> all, Visit visit) {
  VisitWithShop? previous;
  for (final entry in all) {
    final other = entry.visit;
    if (other.id == visit.id || other.shopId != visit.shopId) continue;
    if (!_isBefore(other, visit)) continue;
    if (previous == null || _isBefore(previous.visit, other)) previous = entry;
  }
  return previous;
}

bool _isBefore(Visit a, Visit b) {
  final byEaten = a.eatenAt.compareTo(b.eatenAt);
  if (byEaten != 0) return byEaten < 0;
  return a.createdAt.isBefore(b.createdAt);
}
