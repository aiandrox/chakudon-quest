import '../records/models.dart';
import '../records/wait_time.dart';
import '../scoring/points.dart';
import '../scoring/ranks.dart';

/// クエスト（お題）の定義。追加・変更はこの一覧だけを書き換える。
///
/// 達成状況は保存せず、毎回記録から[Quest.count]で数える。[Quest.count]は記録が増えても
/// 減らない数にすること（達成した日を求めるのに使うため）。
const quests = <Quest>[
  Quest(
    id: 'first_bowl',
    title: 'はじめての着丼',
    condition: '食べた記録が1件',
    target: 1,
    count: _eatenCount,
  ),
  Quest(
    id: 'queue_30',
    title: '行列に挑む者',
    condition: '待ち時間30分以上の記録が1件',
    target: 1,
    count: _waited30Count,
  ),
  Quest(
    id: 'queue_60',
    title: '60分の試練',
    condition: '待ち時間60分以上の記録が1件',
    target: 1,
    count: _waited60Count,
  ),
  Quest(
    id: 'all_styles',
    title: '全系統制覇',
    condition: '「その他」以外の7系統すべてに記録がある',
    target: 7,
    count: _styleCount,
  ),
  Quest(
    id: 'limited_5',
    title: '限定を狩れ',
    condition: '限定メニューの記録が5件',
    target: 5,
    count: _limitedCount,
  ),
  Quest(
    id: 'retry',
    title: '再挑戦',
    condition: '撤退した店で食べた記録が1件',
    target: 1,
    count: _retryCount,
  ),
  Quest(
    id: 'rank_s',
    title: '大物討伐',
    condition: 'Sランクの店が1軒',
    target: 1,
    count: _rankSShopCount,
  ),
  Quest(
    id: 'bowls_100',
    title: '百杯の道',
    condition: '食べた記録が100件',
    target: 100,
    count: _eatenCount,
  ),
];

class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.condition,
    required this.target,
    required this.count,
  });

  final String id;
  final String title;
  final String condition;

  /// 達成に必要な数。
  final int target;

  /// 採点済みの記録（古い順）から、今の数を数える。
  final int Function(List<ScoredVisit> scored) count;
}

enum QuestStatus { achieved, inProgress, notStarted }

class QuestProgress {
  const QuestProgress({
    required this.quest,
    required this.current,
    this.achievedAt,
  });

  final Quest quest;

  /// 今の数。目標を超えても目標の値までにする。
  final int current;

  /// 達成した記録の日時。未達成ならnull。
  final DateTime? achievedAt;

  QuestStatus get status {
    if (current >= quest.target) return QuestStatus.achieved;
    return current > 0 ? QuestStatus.inProgress : QuestStatus.notStarted;
  }
}

/// すべてのクエストの達成状況を、定義の順に返す。[scored]は古い順。
List<QuestProgress> evaluateQuests(
  List<ScoredVisit> scored, {
  List<Quest> definitions = quests,
}) => [for (final quest in definitions) _evaluate(quest, scored)];

/// [before]では未達成で[after]では達成しているクエスト。
List<Quest> newlyAchievedQuests({
  required List<QuestProgress> before,
  required List<QuestProgress> after,
}) {
  final achievedBefore = {
    for (final progress in before)
      if (progress.status == QuestStatus.achieved) progress.quest.id,
  };
  return [
    for (final progress in after)
      if (progress.status == QuestStatus.achieved &&
          !achievedBefore.contains(progress.quest.id))
        progress.quest,
  ];
}

QuestProgress _evaluate(Quest quest, List<ScoredVisit> scored) {
  final count = quest.count(scored);
  if (count < quest.target) return QuestProgress(quest: quest, current: count);
  // 記録が増えても数は減らないので、達成した時点を二分探索で求められる。
  var low = 1;
  var high = scored.length;
  while (low < high) {
    final middle = (low + high) ~/ 2;
    if (quest.count(scored.sublist(0, middle)) >= quest.target) {
      high = middle;
    } else {
      low = middle + 1;
    }
  }
  return QuestProgress(
    quest: quest,
    current: quest.target,
    achievedAt: scored.isEmpty ? null : scored[low - 1].visit.eatenAt,
  );
}

bool _isEaten(ScoredVisit entry) => entry.visit.result == VisitResult.eaten;

int _eatenCount(List<ScoredVisit> scored) => scored.where(_isEaten).length;

int _waitedCount(List<ScoredVisit> scored, int minutes) =>
    scored.where((e) => (waitMinutes(e.visit) ?? 0) >= minutes).length;

int _waited30Count(List<ScoredVisit> scored) => _waitedCount(scored, 30);

int _waited60Count(List<ScoredVisit> scored) => _waitedCount(scored, 60);

int _styleCount(List<ScoredVisit> scored) => {
  for (final entry in scored)
    if (_isEaten(entry) &&
        entry.visit.style != null &&
        entry.visit.style != RamenStyle.other)
      entry.visit.style,
}.length;

int _limitedCount(List<ScoredVisit> scored) =>
    scored.where((e) => _isEaten(e) && e.visit.isLimited).length;

/// 撤退したことのある店で、そのあとに食べた記録の数。
int _retryCount(List<ScoredVisit> scored) {
  final retreatedShops = <String>{};
  var count = 0;
  for (final entry in scored) {
    if (entry.visit.result == VisitResult.retreated) {
      retreatedShops.add(entry.visit.shopId);
    } else if (retreatedShops.contains(entry.visit.shopId)) {
      count++;
    }
  }
  return count;
}

int _rankSShopCount(List<ScoredVisit> scored) =>
    shopRanks(scored).values.where((rank) => rank == ShopRank.s).length;
