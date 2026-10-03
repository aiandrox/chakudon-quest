import '../records/models.dart';
import '../scoring/points.dart';
import '../shop_search/geo.dart';
import '../wishes/wishes.dart';

/// 1杯にたどり着くまでの短い物語（道中記）。保存せず、記録からその場で組み立てる。
///
/// 文のひな形はこのファイルにまとめる（クエストと同じく、足す・直すときはここだけを書き換える）。
/// 同じ材料でも言い回しを数通り用意し、記録のIDで1つに決める（開くたびに変わらないように）。
List<String> buildJournal(ScoredVisit target, List<ScoredVisit> all) {
  final visit = target.visit;
  final before = [
    for (final entry in all)
      if (entry.visit.shopId == visit.shopId && _isBefore(entry.visit, visit))
        entry.visit,
  ];
  final eatenBefore = before.where(_isEaten).length;
  final retreats = _retreatsSinceLastEaten(before);
  final pick = _Picker(visit.id);
  // 願を掛けるより前の1杯を叶えたことにしたときは、願の話は入れない。
  final fulfilled = target.fulfilledWish;
  final wish = fulfilled != null && wishPrecedes(fulfilled, visit.eatenAt)
      ? fulfilled
      : null;
  final checkedInAt = visit.checkedInAt;
  // 撤退でも、並んだ時間は物語に入れる。
  final waited = checkedInAt == null
      ? null
      : visit.eatenAt.difference(checkedInAt).inMinutes;

  final lines = <String>[];
  if (wish != null) {
    final trigger = wish.trigger;
    final day = _monthDay(wish.createdAt, visit.eatenAt);
    lines.add(
      trigger.isEmpty ? '$day、願を掛けた店。' : '$day、願を掛けた店。きっかけは「$trigger」。',
    );
  } else if (eatenBefore == 0 &&
      retreats.isEmpty &&
      visit.result == VisitResult.retreated) {
    lines.add(pick(['初めて挑む道場。', 'まだ見ぬ道場へ。']));
  } else if (eatenBefore == 0 && retreats.isEmpty) {
    final shops = _shopNumber(target, all);
    lines.add(
      pick(['まだ見ぬ$shops軒目の道場へ。', '$shops軒目の道場の暖簾をくぐる。', '新たな道場、$shops軒目。']),
    );
  } else if (eatenBefore > 0) {
    final times = eatenBefore + 1;
    lines.add(
      pick([
        '通うこと$times度目。',
        '$times度目の来訪。',
        'またこの暖簾をくぐる。$times度目。',
        '勝手知ったる道場、$times度目。',
      ]),
    );
  }

  // 節目・間隔・特別な日（当てはまるものを2つまで）。
  if (visit.result == VisitResult.eaten) {
    lines.addAll(_moments(target, all, eatenBefore).take(2));
  }

  if (wish == null && retreats.isEmpty) {
    // 何も起きなかった日にも彩りがあるよう、時間帯・曜日・季節の一文を添える（添えない日もある）。
    final scene = pick(_scenes(visit.eatenAt));
    if (scene.isNotEmpty) lines.add(scene);
  }

  // 地名は、あとから調べて分かることがあるため、ほかの言い回しとは別に決めて足すだけにする
  // （地名が分かっても、ほかの文は変わらない）。
  final area = target.shop.area;
  if (area != null && area.isNotEmpty) {
    final pickArea = _Picker('${visit.id}#area');
    if (_isFarFromHome(target, all)) {
      lines.add(pickArea(['遠く$areaまで足をのばして。', 'はるばる$areaへ。', '今日は$areaまで遠征。']));
    } else {
      final line = pickArea(['$areaの街で。', '$areaの空の下で。', '$areaにて。', '']);
      if (line.isNotEmpty) lines.add(line);
    }
  }

  if (retreats.length == 1) {
    lines.add('前回は${_reason(retreats.single)}に阻まれ、撤退した。');
  } else if (retreats.length > 1) {
    lines.add('${retreats.length}度の撤退を越えて、ここまで来た。');
  }

  if (visit.result == VisitResult.retreated) {
    if (waited != null && waited > 0) lines.add('$waited分並んだが、');
    lines.add('${_reason(visit)}に阻まれ、撤退。');
    lines.add(pick(['次こそは。', 'この借りは、必ず返す。']));
    return lines;
  }

  if (waited != null && waited >= 60) {
    lines.add(pick(['$waited分の長い行列を耐え抜き、', '並ぶこと$waited分。足が棒になっても、']));
  } else if (waited != null && waited > 0) {
    lines.add(pick(['行列に並ぶこと$waited分、', '$waited分の行列を越え、']));
  }

  final flavors = _flavors[visit.style];
  if (flavors != null) {
    final flavor = _Picker('${visit.id}#flavor')([...flavors, '']);
    if (flavor.isNotEmpty) lines.add(flavor);
  }

  final bowl = '${visit.isLimited ? '限定の' : ''}${_styleName(visit.style)}の一杯';
  final dramatic = wish != null || retreats.isNotEmpty || (waited ?? 0) >= 60;
  final points = target.points.total;
  // 共有カードで修行点を外すとき「、修行点 N」を消すので、この形は崩さない。
  lines.add(
    dramatic
        ? 'ついに着丼。$bowl、修行点 $points。'
        : pick([
            '着丼。$bowl、修行点 $points。',
            '丼が置かれた。$bowl、修行点 $points。',
            '湯気の向こうに$bowl、修行点 $points。',
            '待望の$bowl、修行点 $points。',
          ]),
  );

  lines.addAll(_records(target, all).take(1));

  final verdict = _verdicts[visit.rating];
  if (verdict != null) lines.add(pick(verdict));

  final memo = visit.memo.trim();
  if (memo.isNotEmpty && memo.length <= 20 && !memo.contains('\n')) {
    lines.add('――「$memo」と書き残す。');
  }

  if (wish != null) {
    final days = daysToFulfill(wish, visit.eatenAt);
    lines.add(days == 0 ? '願を掛けたその日に、願成就。' : '$days日越しの願成就。');
  } else if (target.isRetrySuccess) {
    lines.add('再挑戦、成功。');
  } else {
    final count = _yearNumber(target, all);
    lines.add(
      pick([
        '今年 $count杯目。',
        '今年 $count杯目の修行。',
        '修行は続く。今年 $count杯目。',
        '麺道、今年 $count杯目。',
      ]),
    );
  }
  return lines;
}

bool _isEaten(Visit visit) => visit.result == VisitResult.eaten;

/// 遠出とみなす、いつもの店からの距離。
const _farMeters = 20000;

/// この1杯の店が、いつもの店（この1杯までにいちばん多く食べた店）から遠いか。
/// あとから記録を足しても過去の道中記が変わらないよう、この1杯までの記録だけで決める。
bool _isFarFromHome(ScoredVisit target, List<ScoredVisit> all) {
  final counts = <String, int>{};
  final shops = <String, Shop>{};
  for (final entry in all) {
    if (!_isEaten(entry.visit)) continue;
    if (entry != target && !_isBefore(entry.visit, target.visit)) continue;
    counts.update(entry.shop.id, (n) => n + 1, ifAbsent: () => 1);
    shops[entry.shop.id] = entry.shop;
  }
  if (counts.isEmpty) return false;
  final home =
      shops[counts.entries.reduce((a, b) => b.value > a.value ? b : a).key]!;
  final here = target.shop;
  if (home.latitude == null ||
      home.longitude == null ||
      here.latitude == null ||
      here.longitude == null) {
    return false;
  }
  return distanceMeters(
        GeoPoint(home.latitude!, home.longitude!),
        GeoPoint(here.latitude!, here.longitude!),
      ) >=
      _farMeters;
}

bool _isBefore(Visit a, Visit b) {
  final byEaten = a.eatenAt.compareTo(b.eatenAt);
  if (byEaten != 0) return byEaten < 0;
  return a.createdAt.isBefore(b.createdAt);
}

/// 最後に食べたあとの撤退（古い順）。
List<Visit> _retreatsSinceLastEaten(List<Visit> before) {
  final retreats = <Visit>[];
  for (final visit in before) {
    if (_isEaten(visit)) {
      retreats.clear();
    } else {
      retreats.add(visit);
    }
  }
  return retreats;
}

String _reason(Visit retreat) {
  final memo = retreat.memo.trim();
  // 撤退の理由は「売り切れ」「臨時休業」など短い言葉で残る。長いメモは文に入れない。
  return memo.isNotEmpty && memo.length <= 10 ? '「$memo」' : '思わぬ壁';
}

String _monthDay(DateTime date, DateTime now) => date.year == now.year
    ? '${date.month}月${date.day}日'
    : '${date.year}年${date.month}月${date.day}日';

/// 食べたことのある店の数を、この1杯までで数える。
int _shopNumber(ScoredVisit target, List<ScoredVisit> all) => {
  for (final entry in all)
    if (_isEaten(entry.visit) &&
        (entry == target || _isBefore(entry.visit, target.visit)))
      entry.visit.shopId,
}.length;

int _yearNumber(ScoredVisit target, List<ScoredVisit> all) => all
    .where(
      (entry) =>
          _isEaten(entry.visit) &&
          entry.visit.eatenAt.year == target.visit.eatenAt.year &&
          (entry == target || _isBefore(entry.visit, target.visit)),
    )
    .length;

/// 通算の杯数の節目。
const _milestones = {10, 30, 50, 100, 200, 300, 500, 1000};

/// 節目・間隔・特別な日の一文（大事な順）。
List<String> _moments(
  ScoredVisit target,
  List<ScoredVisit> all,
  int eatenBefore,
) {
  final visit = target.visit;
  final at = visit.eatenAt;
  final upTo = [
    for (final entry in all)
      if (_isEaten(entry.visit) &&
          (entry == target || _isBefore(entry.visit, visit)))
        entry.visit,
  ];
  final moments = <String>[];
  if (at.month == 1 && at.day == 1) moments.add('年明け最初の一杯。');
  if (at.month == 12 && at.day == 31) moments.add('年納めの一杯。');
  if (_yearNumber(target, all) == 1 && upTo.length > 1) {
    moments.add('今年の初麺。');
  }
  if (_milestones.contains(upTo.length)) {
    moments.add('通算${upTo.length}杯目の節目。');
  }
  final sameDay = upTo.where((v) => _sameDate(v.eatenAt, at)).length;
  if (sameDay >= 2) moments.add('本日$sameDay杯目。');
  final streak = _dayStreak(upTo, at);
  if (streak >= 3) moments.add('$streak日連続の麺修行。');
  final lastHere = upTo
      .where((v) => v.shopId == visit.shopId && v.id != visit.id)
      .map((v) => v.eatenAt)
      .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
  if (lastHere != null) {
    final gap = _dateOnly(at).difference(_dateOnly(lastHere)).inDays;
    if (gap >= 365) {
      moments.add('${gap ~/ 365}年ぶりの再会。');
    } else if (gap >= 90) {
      moments.add('久しぶりの暖簾。');
    }
  }
  final times = eatenBefore + 1;
  if (times == 5) moments.add('常連の域に入った。');
  if (times == 10) moments.add('十度目。もはや第二の我が家。');
  return moments;
}

/// この1杯までで、何日続けて食べているか（同じ日に何杯食べても1日）。
int _dayStreak(List<Visit> upTo, DateTime at) {
  final days = {for (final v in upTo) _dateOnly(v.eatenAt)};
  var day = _dateOnly(at);
  var count = 0;
  while (days.contains(day)) {
    count++;
    day = DateTime.utc(day.year, day.month, day.day - 1);
  }
  return count;
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// 夏時間のある地域でも1日を24時間として数えるため、UTCの日付で比べる。
DateTime _dateOnly(DateTime at) => DateTime.utc(at.year, at.month, at.day);

/// 記録の更新（自己最高の修行点・この店で最長の待ち・この道場の印が極に）。
List<String> _records(ScoredVisit target, List<ScoredVisit> all) {
  final visit = target.visit;
  final before = [
    for (final entry in all)
      if (_isEaten(entry.visit) && _isBefore(entry.visit, visit)) entry,
  ];
  if (before.isEmpty) return const [];
  final points = target.points.total;
  final records = <String>[];
  if (points > before.map((e) => e.points.total).reduce(_max)) {
    records.add('自己最高の修行点を更新。');
  }
  final here = [
    for (final entry in before)
      if (entry.visit.shopId == visit.shopId) entry,
  ];
  if (here.isNotEmpty &&
      points >= _rankSPoints &&
      here.map((e) => e.points.total).reduce(_max) < _rankSPoints) {
    records.add('この道場の印は「極」に。');
  }
  final waited = _waitOf(visit);
  final waitsHere = [for (final e in here) ?_waitOf(e.visit)];
  if (waited != null &&
      waitsHere.isNotEmpty &&
      waited > waitsHere.reduce(_max)) {
    records.add('この店で最長の待ち。');
  }
  return records;
}

/// 店ランク「極」になる修行点（ranks.dart の ShopRank.s と同じ）。
const _rankSPoints = 60;

int _max(int a, int b) => a > b ? a : b;

int? _waitOf(Visit visit) {
  final checkedInAt = visit.checkedInAt;
  return checkedInAt == null
      ? null
      : visit.eatenAt.difference(checkedInAt).inMinutes;
}

/// 系統ごとの一文の候補。
const _flavors = <RamenStyle, List<String>>{
  RamenStyle.shoyu: ['澄んだ醤油の香りが立つ。', '黄金色のスープに顔が映る。'],
  RamenStyle.miso: ['濃厚な湯気に包まれる。', '味噌の香りが鼻をくすぐる。'],
  RamenStyle.shio: ['透きとおるスープをひと口。', '塩の一杯は、ごまかしがきかない。'],
  RamenStyle.tonkotsu: ['白濁のスープが香り立つ。', '替え玉の誘惑と戦う。'],
  RamenStyle.iekei: ['海苔をスープに浸して。', '「お好みは？」に「硬め濃いめ多め」。'],
  RamenStyle.jiro: ['「ニンニク入れますか？」に静かに頷く。', '野菜の山を崩しにかかる。'],
  RamenStyle.tsukemen: ['麺をつけ汁にくぐらせて。', '最後はスープ割りで締める。'],
  RamenStyle.shirunashi: ['底からよく混ぜて。', '追い飯まで抜かりなく。'],
};

/// ★の数ごとの、食べ終わったあとのひとこと。★がまだ無ければ何も言わない。
const _verdicts = <int, List<String>>{
  5: ['文句なしの一杯。また必ず来る。', 'これぞ求めていた味。', '箸が止まらなかった。', 'スープまで一滴残らず。'],
  4: ['満足の一杯。', 'いい道場に出会えた。', 'また来たいと思える味。'],
  3: ['悪くない。', '可もなく不可もなく、それもまた修行。', 'いつもの安心する味。'],
  2: ['今日はあと一歩。', '好みとは少し違った。'],
  1: ['これもまた修行。', '合わない味を知るのも道のうち。'],
};

/// 食べた時間帯・曜日・季節に合う一文の候補。空文字は「添えない」。
List<String> _scenes(DateTime at) {
  final hour = at.hour;
  final time = switch (hour) {
    6 => ['明け六つ、朝一番の一杯。', '朝の澄んだ空気の中、朝ラーの暖簾へ。'],
    18 => ['暮れ六つの鐘とともに。', '一日の終わりに、夜の暖簾へ。'],
    2 => ['丑三つ時の一杯。', '真夜中の一杯は、背徳の味。'],
    >= 5 && < 11 => ['朝の澄んだ空気の中、朝ラーの暖簾へ。', '一日の始まりは一杯から。'],
    >= 11 && < 15 => ['昼どきの喧騒をくぐり抜けて。', '腹の虫が鳴る昼下がり。'],
    >= 15 && < 18 => ['中休み前のすき間を狙って。', '夕暮れ前のひと休み。'],
    >= 18 && < 23 => ['一日の終わりに、夜の暖簾へ。', '夜風に誘われて。'],
    _ => ['真夜中の一杯は、背徳の味。', '眠らない街の灯りの下で。'],
  };
  final weekend = switch (at.weekday) {
    DateTime.saturday || DateTime.sunday => ['休日の気ままな一杯。'],
    DateTime.friday when hour >= 18 => ['花金の一杯。'],
    DateTime.monday => ['週の始まりに気合を入れる。'],
    _ => const <String>[],
  };
  final season = switch (at.month) {
    12 || 1 || 2 => ['冷えた体に湯気がしみる。'],
    6 || 7 || 8 => ['汗をぬぐいながらすする。'],
    3 || 4 || 5 => ['春の陽気に誘われて。'],
    _ => ['秋の夜長にもう一杯。'],
  };
  return [...time, ...weekend, ...season, '', ''];
}

String _styleName(RamenStyle? style) => switch (style) {
  RamenStyle.shoyu => '醤油',
  RamenStyle.miso => '味噌',
  RamenStyle.shio => '塩',
  RamenStyle.tonkotsu => '豚骨',
  RamenStyle.iekei => '家系',
  RamenStyle.jiro => '二郎系',
  RamenStyle.tsukemen => 'つけ麺',
  RamenStyle.shirunashi => '汁なし',
  RamenStyle.other || null => 'ラーメン',
};

class _Picker {
  _Picker(String visitId)
    : _seed = visitId.codeUnits.fold<int>(
        0,
        (sum, unit) => (sum * 31 + unit) & 0x7fffffff,
      );

  int _seed;

  String call(List<String> options) {
    final chosen = options[_seed % options.length];
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return chosen;
  }
}
