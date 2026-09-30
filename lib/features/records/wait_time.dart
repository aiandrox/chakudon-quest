import 'models.dart';

/// 並んでから食べるまでの分数（端数切り捨て）。チェックインしていない記録と撤退はnull。
int? waitMinutes(Visit visit) {
  final checkedInAt = visit.checkedInAt;
  if (checkedInAt == null || visit.result != VisitResult.eaten) return null;
  final minutes = visit.eatenAt.difference(checkedInAt).inMinutes;
  return minutes < 0 ? 0 : minutes;
}
