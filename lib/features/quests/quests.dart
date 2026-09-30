import '../records/models.dart';
import '../records/wait_time.dart';
import '../scoring/points.dart';
import '../scoring/ranks.dart';

/// 常設: 回数を重ねるごとにレベルが上がる。スポット: 1回達成すれば終わり。
enum QuestKind { standing, spot }

/// クエスト（お題）の定義。追加・変更はこの一覧だけを書き換える。
///
/// 達成状況は保存せず、毎回記録から[Quest.count]で数える。[Quest.count]は記録が増えても
/// 減らない数にすること（達成した日を求めるのに使うため）。
const quests = <Quest>[
  Quest(
    id: 'bowls',
    kind: QuestKind.standing,
    title: '着丼の道',
    description: '食べた杯数',
    unit: '杯',
    // 1杯目は「はじめての着丼」で祝うので、Lv.1 は5杯から。
    thresholds: [5, 10, 30, 50, 100, 200],
    count: _eatenCount,
  ),
  Quest(
    id: 'shops',
    kind: QuestKind.standing,
    title: '開拓者',
    description: '食べたことのある店の数',
    unit: '軒',
    thresholds: [3, 10, 30, 50, 100],
    count: _eatenShopCount,
  ),
  Quest(
    id: 'queue',
    kind: QuestKind.standing,
    title: '行列の覇者',
    description: '30分以上並んで食べた回数',
    unit: '回',
    thresholds: [1, 5, 10, 30],
    count: _waited30Count,
  ),
  Quest(
    id: 'limited',
    kind: QuestKind.standing,
    title: '限定ハンター',
    description: '限定メニューを食べた回数',
    unit: '杯',
    thresholds: [1, 5, 10, 30],
    count: _limitedCount,
  ),
  Quest(
    id: 'retry',
    kind: QuestKind.standing,
    title: '不屈の挑戦者',
    description: '撤退した店で、あとから食べた回数',
    unit: '回',
    thresholds: [1, 3, 10],
    count: _retryCount,
  ),
  Quest(
    id: 'boss',
    kind: QuestKind.standing,
    title: '大物討伐',
    description: 'Sランクにした店の数',
    unit: '軒',
    thresholds: [1, 3, 10],
    count: _rankSShopCount,
  ),
  Quest(
    id: 'styles',
    kind: QuestKind.standing,
    title: '系統の探究',
    description: '食べた系統の数（「その他」を除く7系統）。7系統で全系統制覇',
    unit: '系統',
    thresholds: [3, 5, 7],
    count: _styleCount,
  ),
  Quest(
    id: 'first_bowl',
    kind: QuestKind.spot,
    title: 'はじめての着丼',
    description: '最初の1杯を記録する',
    unit: '杯',
    thresholds: [1],
    count: _eatenCount,
  ),
  Quest(
    id: 'queue_60',
    kind: QuestKind.spot,
    title: '60分の試練',
    description: '60分以上並んで食べる',
    unit: '回',
    thresholds: [1],
    count: _waited60Count,
  ),
  Quest(
    id: 'queue_90',
    kind: QuestKind.spot,
    title: '90分の死闘',
    description: '90分以上並んで食べる',
    unit: '回',
    thresholds: [1],
    count: _waited90Count,
  ),
  Quest(
    id: 'double_bowl',
    kind: QuestKind.spot,
    title: '一日二杯',
    description: '同じ日に2杯食べる',
    unit: '日',
    thresholds: [1],
    count: _doubleBowlDays,
  ),
  Quest(
    id: 'third_time',
    kind: QuestKind.spot,
    title: '三度目の正直',
    description: '同じ店で2回撤退したあと、その店で食べる',
    unit: '回',
    thresholds: [1],
    count: _thirdTimeCount,
  ),
  Quest(
    id: 'rare_shop',
    kind: QuestKind.spot,
    title: '幻の店',
    description: '営業の条件が2つ以上ある店で食べる',
    unit: '回',
    thresholds: [1],
    count: _rareShopCount,
  ),
];

class Quest {
  const Quest({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.unit,
    required this.thresholds,
    required this.count,
  });

  final String id;
  final QuestKind kind;
  final String title;
  final String description;

  /// 数の単位（杯・軒・回など）。
  final String unit;

  /// レベルごとに必要な数（小さい順）。スポットは1つだけ。
  final List<int> thresholds;

  /// 採点済みの記録（古い順）から、今の数を数える。
  final int Function(List<ScoredVisit> scored) count;

  int get maxLevel => thresholds.length;
}

class QuestProgress {
  const QuestProgress({
    required this.quest,
    required this.current,
    required this.levelAchievedAt,
  });

  final Quest quest;

  /// 今の数。
  final int current;

  /// 到達したレベルごとの、到達した記録の日時（古い順）。長さが今のレベル。
  final List<DateTime> levelAchievedAt;

  int get level => levelAchievedAt.length;

  bool get isMaxLevel => level >= quest.maxLevel;

  /// スポットは達成済みか。常設はLv.1以上か。
  bool get isAchieved => level > 0;

  /// 次のレベルに必要な数。最高レベルならnull。
  int? get nextThreshold => isMaxLevel ? null : quest.thresholds[level];
}

/// あるクエストが、あるレベルに届いたこと。
class QuestLevelUp {
  const QuestLevelUp({required this.quest, required this.level});

  final Quest quest;
  final int level;
}

/// すべてのクエストの達成状況を、定義の順に返す。[scored]は古い順。
List<QuestProgress> evaluateQuests(
  List<ScoredVisit> scored, {
  List<Quest> definitions = quests,
}) => [for (final quest in definitions) _evaluate(quest, scored)];

/// [before]から[after]で新しく届いたレベル。1回で2つ上がったら、上のレベルだけを返す。
List<QuestLevelUp> newlyAchievedLevels({
  required List<QuestProgress> before,
  required List<QuestProgress> after,
}) {
  final levelBefore = {
    for (final progress in before) progress.quest.id: progress.level,
  };
  return [
    for (final progress in after)
      if (progress.level > (levelBefore[progress.quest.id] ?? 0))
        QuestLevelUp(quest: progress.quest, level: progress.level),
  ];
}

QuestProgress _evaluate(Quest quest, List<ScoredVisit> scored) {
  final count = quest.count(scored);
  return QuestProgress(
    quest: quest,
    current: count,
    levelAchievedAt: [
      for (final threshold in quest.thresholds)
        if (count >= threshold) _reachedAt(quest, scored, threshold),
    ],
  );
}

/// 記録が増えても数は減らないので、[threshold]に届いた記録を二分探索で求められる。
DateTime _reachedAt(Quest quest, List<ScoredVisit> scored, int threshold) {
  var low = 1;
  var high = scored.length;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (quest.count(scored.sublist(0, middle)) >= threshold) {
      high = middle;
    } else {
      low = middle + 1;
    }
  }
  return scored[low - 1].visit.eatenAt;
}

bool _isEaten(ScoredVisit entry) => entry.visit.result == VisitResult.eaten;

int _eatenCount(List<ScoredVisit> scored) => scored.where(_isEaten).length;

int _eatenShopCount(List<ScoredVisit> scored) => {
  for (final entry in scored)
    if (_isEaten(entry)) entry.visit.shopId,
}.length;

int _waitedCount(List<ScoredVisit> scored, int minutes) =>
    scored.where((e) => (waitMinutes(e.visit) ?? 0) >= minutes).length;

int _waited30Count(List<ScoredVisit> scored) => _waitedCount(scored, 30);

int _waited60Count(List<ScoredVisit> scored) => _waitedCount(scored, 60);

int _waited90Count(List<ScoredVisit> scored) => _waitedCount(scored, 90);

int _styleCount(List<ScoredVisit> scored) => {
  for (final entry in scored)
    if (_isEaten(entry) &&
        entry.visit.style != null &&
        entry.visit.style != RamenStyle.other)
      entry.visit.style,
}.length;

int _limitedCount(List<ScoredVisit> scored) =>
    scored.where((e) => _isEaten(e) && e.visit.isLimited).length;

/// 撤退のあと、同じ店で食べた（再挑戦成功した）回数。撤退1回につき1回まで数える。
int _retryCount(List<ScoredVisit> scored) =>
    scored.where((entry) => entry.isRetrySuccess).length;

/// 同じ店で2回以上撤退したあと、その店で食べた記録の数。
int _thirdTimeCount(List<ScoredVisit> scored) {
  final retreats = <String, int>{};
  var count = 0;
  for (final entry in scored) {
    final shopId = entry.visit.shopId;
    if (entry.visit.result == VisitResult.retreated) {
      retreats.update(shopId, (n) => n + 1, ifAbsent: () => 1);
    } else if ((retreats[shopId] ?? 0) >= 2) {
      count++;
    }
  }
  return count;
}

/// 2杯以上食べた日の数。
int _doubleBowlDays(List<ScoredVisit> scored) {
  final perDay = <DateTime, int>{};
  for (final entry in scored.where(_isEaten)) {
    final at = entry.visit.eatenAt;
    perDay.update(
      DateTime(at.year, at.month, at.day),
      (n) => n + 1,
      ifAbsent: () => 1,
    );
  }
  return perDay.values.where((n) => n >= 2).length;
}

int _rareShopCount(List<ScoredVisit> scored) => scored
    .where((e) => _isEaten(e) && e.shop.hoursConditions.length >= 2)
    .length;

int _rankSShopCount(List<ScoredVisit> scored) =>
    shopRanks(scored).values.where((rank) => rank == ShopRank.s).length;
