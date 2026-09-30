import '../records/models.dart';
import '../records/wait_time.dart';

/// 1件の記録で得たポイントの内訳。撤退は全て0。
class PointsBreakdown {
  const PointsBreakdown({
    required this.base,
    required this.waitBonus,
    required this.limitedBonus,
    required this.ticketBonus,
    required this.firstVisitBonus,
    required this.retryBonus,
    required this.hoursType,
  });

  static const zero = PointsBreakdown(
    base: 0,
    waitBonus: 0,
    limitedBonus: 0,
    ticketBonus: 0,
    firstVisitBonus: 0,
    retryBonus: 0,
    hoursType: HoursType.normal,
  );

  final int base;
  final int waitBonus;
  final int limitedBonus;
  final int ticketBonus;
  final int firstVisitBonus;
  final int retryBonus;
  final HoursType hoursType;

  int get subtotal =>
      base +
      waitBonus +
      limitedBonus +
      ticketBonus +
      firstVisitBonus +
      retryBonus;

  /// 倍率をかけたあとの小数は切り捨てる。
  int get total => subtotal * _doubledMultiplier(hoursType) ~/ 2;
}

const basePoints = 10;
const waitBonusPerTenMinutes = 5;
const limitedBonus = 20;
const ticketBonus = 20;
const firstVisitBonus = 10;
const retryBonus = 15;

/// 倍率（×1 / ×1.5 / ×2）を整数で扱うため2倍した値。
int _doubledMultiplier(HoursType type) => switch (type) {
  HoursType.normal => 2,
  HoursType.lunchOnly => 3,
  HoursType.fewDays => 4,
};

double hoursMultiplier(HoursType type) => _doubledMultiplier(type) / 2;

PointsBreakdown calculatePoints({
  required Visit visit,
  required HoursType hoursType,
  required bool isFirstVisit,
  required bool isRetrySuccess,
}) {
  if (visit.result != VisitResult.eaten) return PointsBreakdown.zero;
  return PointsBreakdown(
    base: basePoints,
    waitBonus: (waitMinutes(visit) ?? 0) ~/ 10 * waitBonusPerTenMinutes,
    limitedBonus: visit.isLimited ? limitedBonus : 0,
    ticketBonus: visit.hasTicket ? ticketBonus : 0,
    firstVisitBonus: isFirstVisit ? firstVisitBonus : 0,
    retryBonus: isRetrySuccess ? retryBonus : 0,
    hoursType: hoursType,
  );
}

/// 記録1件ごとの採点結果。
class ScoredVisit {
  const ScoredVisit({
    required this.visit,
    required this.shop,
    required this.points,
    required this.isFirstVisit,
    required this.isRetrySuccess,
  });

  final Visit visit;
  final Shop shop;
  final PointsBreakdown points;

  /// その店で最初の「食べた」記録か。
  final bool isFirstVisit;

  /// 同じ店での直前の記録が撤退だったか。
  final bool isRetrySuccess;
}

/// 全記録を採点し、古い順に返す。初訪問と再挑戦成功は店ごとの記録の順番で決まるため、
/// 1件だけでは採点できない。
List<ScoredVisit> scoreVisits(List<VisitWithShop> entries) {
  final ordered = [...entries]
    ..sort((a, b) {
      final byEaten = a.visit.eatenAt.compareTo(b.visit.eatenAt);
      if (byEaten != 0) return byEaten;
      return a.visit.createdAt.compareTo(b.visit.createdAt);
    });
  final eatenShops = <String>{};
  final lastResult = <String, VisitResult>{};
  final scored = <ScoredVisit>[];
  for (final entry in ordered) {
    final visit = entry.visit;
    final isEaten = visit.result == VisitResult.eaten;
    final isFirstVisit = isEaten && !eatenShops.contains(visit.shopId);
    final isRetrySuccess =
        isEaten && lastResult[visit.shopId] == VisitResult.retreated;
    scored.add(
      ScoredVisit(
        visit: visit,
        shop: entry.shop,
        points: calculatePoints(
          visit: visit,
          hoursType: entry.shop.hoursType,
          isFirstVisit: isFirstVisit,
          isRetrySuccess: isRetrySuccess,
        ),
        isFirstVisit: isFirstVisit,
        isRetrySuccess: isRetrySuccess,
      ),
    );
    if (isEaten) eatenShops.add(visit.shopId);
    lastResult[visit.shopId] = visit.result;
  }
  return scored;
}

int totalPoints(List<ScoredVisit> scored) =>
    scored.fold(0, (sum, entry) => sum + entry.points.total);
