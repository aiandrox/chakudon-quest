import '../map/journey.dart';
import '../quests/quests.dart';
import '../records/models.dart';
import '../scoring/points.dart';
import '../scoring/rank_history.dart';
import '../stats/stats.dart';

/// その年に届いた型・奥義。型は、その年に上がったいちばん上の段。
class QuestReached {
  const QuestReached({required this.quest, required this.level});

  final Quest quest;
  final int level;
}

/// 1年の振り返り。保存せず、記録から毎回計算する。
class YearReview {
  const YearReview({
    required this.year,
    required this.stamps,
    required this.bowls,
    required this.shops,
    required this.retreats,
    required this.points,
    required this.favoriteShop,
    required this.highestPoints,
    required this.longestWait,
    required this.styles,
    required this.monthlyBowls,
    required this.ranks,
    required this.quests,
    required this.wishesFulfilled,
    required this.expeditions,
  });

  final int year;

  /// その年に食べた1杯（古い順）。印を順に押していくのに使う。
  final List<ScoredVisit> stamps;

  /// 食べた杯数（撤退は数えない）。
  final int bowls;

  /// 食べた店の数。
  final int shops;
  final int retreats;

  /// その年に得た修行点の合計。
  final int points;

  /// その年にいちばん多く食べた店（2杯以上の店が無ければnull）。
  final FrequentShop? favoriteShop;
  final PersonalBest? highestPoints;
  final PersonalBest? longestWait;
  final List<StyleShare> styles;

  /// 1月〜12月の杯数（長さ12）。
  final List<int> monthlyBowls;

  /// その年に上がった段位（入門は除く）。
  final List<RankAttainment> ranks;
  final List<QuestReached> quests;
  final int wishesFulfilled;
  final List<Expedition> expeditions;

  bool get isEmpty => bowls == 0 && retreats == 0;

  bool get hasAchievements =>
      ranks.isNotEmpty ||
      quests.isNotEmpty ||
      wishesFulfilled > 0 ||
      expeditions.isNotEmpty;
}

/// [year]の1年を振り返る。[scored]は古い順の全記録（初訪問や段位の判定に前の年の記録も使うため）。
/// [questProgress]は全記録から求めた達成状況（[evaluateQuests]の結果）。
YearReview yearReview(
  List<ScoredVisit> scored,
  int year, {
  required List<QuestProgress> questProgress,
}) {
  final inYear = [
    for (final entry in scored)
      if (entry.visit.eatenAt.year == year) entry,
  ];
  final eaten = [
    for (final entry in inYear)
      if (entry.visit.result == VisitResult.eaten) entry,
  ];
  final monthly = List.filled(12, 0);
  for (final entry in eaten) {
    monthly[entry.visit.eatenAt.month - 1]++;
  }
  final bests = personalBests(eaten);
  return YearReview(
    year: year,
    stamps: eaten,
    bowls: eaten.length,
    shops: {for (final entry in eaten) entry.visit.shopId}.length,
    retreats: inYear.length - eaten.length,
    points: eaten.fold(0, (sum, entry) => sum + entry.points.total),
    favoriteShop: frequentShops(eaten, limit: 1).firstOrNull,
    highestPoints: bests.highestPoints,
    longestWait: bests.longestWait,
    styles: styleShares(eaten),
    monthlyBowls: monthly,
    ranks: [
      for (final attained in rankHistory(scored).skip(1))
        if (attained.reachedAt?.year == year) attained,
    ],
    quests: [
      for (final progress in questProgress)
        if (_lastLevelInYear(progress, year) case final level?)
          QuestReached(quest: progress.quest, level: level),
    ],
    wishesFulfilled: eaten.where((e) => e.fulfilledWish != null).length,
    expeditions: expeditions(scored, year: year),
  );
}

int? _lastLevelInYear(QuestProgress progress, int year) {
  int? level;
  for (final (i, at) in progress.levelAchievedAt.indexed) {
    if (at.year == year) level = i + 1;
  }
  return level;
}

/// 記録（撤退も含む）のある年。新しい順。
List<int> reviewYears(List<ScoredVisit> scored) =>
    {for (final entry in scored) entry.visit.eatenAt.year}.toList()
      ..sort((a, b) => b.compareTo(a));

/// 一覧で振り返りを勧める年。12月はその年、1月は前の年。ほかの月はnull。
int? reviewSeasonYear(DateTime now) => switch (now.month) {
  12 => now.year,
  1 => now.year - 1,
  _ => null,
};
