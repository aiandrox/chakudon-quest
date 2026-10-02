import '../records/models.dart';
import '../records/wait_time.dart';
import '../wishes/wishes.dart';

/// 1件の記録で得たポイントの内訳。撤退は全て0。
class PointsBreakdown {
  const PointsBreakdown({
    required this.base,
    required this.waitBonus,
    required this.limitedBonus,
    required this.firstVisitBonus,
    required this.retryBonus,
    required this.hoursConditions,
  });

  static const zero = PointsBreakdown(
    base: 0,
    waitBonus: 0,
    limitedBonus: 0,
    firstVisitBonus: 0,
    retryBonus: 0,
    hoursConditions: {},
  );

  final int base;
  final int waitBonus;
  final int limitedBonus;
  final int firstVisitBonus;
  final int retryBonus;
  final Set<HoursCondition> hoursConditions;

  int get subtotal =>
      base + waitBonus + limitedBonus + firstVisitBonus + retryBonus;

  /// 倍率をかけたあとの小数は切り捨てる。
  int get total => subtotal * _multiplierTenths(hoursConditions) ~/ 10;
}

const basePoints = 10;
const waitBonusPerTenMinutes = 5;
const limitedBonus = 20;
const firstVisitBonus = 10;
const retryBonus = 15;

/// 攻略しにくさの条件ごとの倍率の上乗せ（10分の1単位）。条件の分だけ足し、上限で止める。
const hoursConditionWeights = <HoursCondition, int>{
  HoursCondition.lunchOnly: 3,
  HoursCondition.nightOnly: 2,
  HoursCondition.weekdaysOnly: 5,
  HoursCondition.weekendsOnly: 2,
  HoursCondition.fewDays: 5,
  HoursCondition.irregular: 5,
  HoursCondition.badAccess: 5,
};
const _maxMultiplierTenths = 25;

/// 倍率（×1〜×2.5）を整数で扱うため10倍した値。
int _multiplierTenths(Set<HoursCondition> conditions) {
  final total =
      10 +
      conditions.fold<int>(
        0,
        (sum, c) => sum + (hoursConditionWeights[c] ?? 0),
      );
  return total > _maxMultiplierTenths ? _maxMultiplierTenths : total;
}

/// 攻略しにくさの条件による倍率。条件ごとの上乗せを足し、最大×2.5。
double hoursMultiplier(Set<HoursCondition> conditions) =>
    _multiplierTenths(conditions) / 10;

PointsBreakdown calculatePoints({
  required Visit visit,
  required Set<HoursCondition> hoursConditions,
  required bool isFirstVisit,
  required bool isRetrySuccess,
}) {
  if (visit.result != VisitResult.eaten) return PointsBreakdown.zero;
  return PointsBreakdown(
    base: basePoints,
    waitBonus: (waitMinutes(visit) ?? 0) ~/ 10 * waitBonusPerTenMinutes,
    limitedBonus: visit.isLimited ? limitedBonus : 0,
    firstVisitBonus: isFirstVisit ? firstVisitBonus : 0,
    retryBonus: isRetrySuccess ? retryBonus : 0,
    hoursConditions: hoursConditions,
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
    this.fulfilledWish,
  });

  final Visit visit;
  final Shop shop;
  final PointsBreakdown points;

  /// その店で最初の「食べた」記録か。
  final bool isFirstVisit;

  /// 同じ店での直前の記録が撤退だったか。
  final bool isRetrySuccess;

  /// この1杯で叶った願（願を掛けたあと、その店で最初に食べた記録）。
  final Wish? fulfilledWish;
}

/// 全記録を採点し、古い順に返す。初訪問と再挑戦成功は店ごとの記録の順番で決まるため、
/// 1件だけでは採点できない。[wishes]を渡すと、どの1杯で願が叶ったかも求める。
List<ScoredVisit> scoreVisits(
  List<VisitWithShop> entries, {
  List<Wish> wishes = const [],
}) {
  final ordered = [...entries]
    ..sort((a, b) {
      final byEaten = a.visit.eatenAt.compareTo(b.visit.eatenAt);
      if (byEaten != 0) return byEaten;
      return a.visit.createdAt.compareTo(b.visit.createdAt);
    });
  final eatenShops = <String>{};
  final lastResult = <String, VisitResult>{};
  final scored = <ScoredVisit>[];
  final pendingWishes = [...wishes]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  for (final entry in ordered) {
    final visit = entry.visit;
    final isEaten = visit.result == VisitResult.eaten;
    final fulfilledWish = isEaten
        ? pendingWishes
              .where(
                (wish) =>
                    !wish.createdAt.isAfter(visit.eatenAt) &&
                    wishMatchesShop(wish, entry.shop),
              )
              .firstOrNull
        : null;
    if (fulfilledWish != null) pendingWishes.remove(fulfilledWish);
    final isFirstVisit = isEaten && !eatenShops.contains(visit.shopId);
    final isRetrySuccess =
        isEaten && lastResult[visit.shopId] == VisitResult.retreated;
    scored.add(
      ScoredVisit(
        visit: visit,
        shop: entry.shop,
        points: calculatePoints(
          visit: visit,
          hoursConditions: entry.shop.hoursConditions,
          isFirstVisit: isFirstVisit,
          isRetrySuccess: isRetrySuccess,
        ),
        isFirstVisit: isFirstVisit,
        isRetrySuccess: isRetrySuccess,
        fulfilledWish: fulfilledWish,
      ),
    );
    if (isEaten) eatenShops.add(visit.shopId);
    lastResult[visit.shopId] = visit.result;
  }
  return scored;
}

int totalPoints(List<ScoredVisit> scored) =>
    scored.fold(0, (sum, entry) => sum + entry.points.total);
