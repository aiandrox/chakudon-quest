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

  final verdict = _verdicts[visit.rating];
  if (verdict != null) lines.add(pick(verdict));

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
    >= 5 && < 11 => ['朝の澄んだ空気の中、朝ラーの暖簾へ。', '一日の始まりは一杯から。'],
    >= 11 && < 15 => ['昼どきの喧騒をくぐり抜けて。', '腹の虫が鳴る昼下がり。'],
    >= 15 && < 18 => ['中休み前のすき間を狙って。', '夕暮れ前のひと休み。'],
    >= 18 && < 23 => ['一日の終わりに、夜の暖簾へ。', '夜風に誘われて。'],
    _ => ['真夜中の一杯は、背徳の味。', '眠らない街の灯りの下で。'],
  };
  final weekend = at.weekday >= DateTime.saturday
      ? ['休日の気ままな一杯。']
      : const <String>[];
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
