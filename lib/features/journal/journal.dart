import '../records/models.dart';
import '../scoring/points.dart';
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
    lines.add(pick(['通うこと$times度目。', '$times度目の来訪。']));
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
  lines.add('${dramatic ? 'ついに着丼。' : '着丼。'}$bowl、修行点 ${target.points.total}。');

  if (wish != null) {
    final days = daysToFulfill(wish, visit.eatenAt);
    lines.add(days == 0 ? '願を掛けたその日に、願成就。' : '$days日越しの願成就。');
  } else if (target.isRetrySuccess) {
    lines.add('再挑戦、成功。');
  } else {
    lines.add('今年 ${_yearNumber(target, all)}杯目。');
  }
  return lines;
}

bool _isEaten(Visit visit) => visit.result == VisitResult.eaten;

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
