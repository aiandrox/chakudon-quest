import 'dart:math' as math;

import '../records/models.dart';
import '../scoring/points.dart';
import '../scoring/ranks.dart';

/// 印の形。1杯の修行点が高いほど格の高い形になる。撤退は灰色の印。
enum InkanShape { circle, doubleCircle, square, filled, retreat }

InkanShape inkanShapeFor(ScoredVisit scored) {
  if (scored.visit.result == VisitResult.retreated) return InkanShape.retreat;
  return switch (shopRankFor(scored.points.total)) {
    ShopRank.c => InkanShape.circle,
    ShopRank.b => InkanShape.doubleCircle,
    ShopRank.a => InkanShape.square,
    ShopRank.s => InkanShape.filled,
  };
}

const _kanjiDigits = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

/// 1〜99を漢数字にする（十・二十一 など）。範囲外はアラビア数字のまま。
String kanjiNumber(int value) {
  if (value < 0 || value >= 100) return '$value';
  if (value < 10) return _kanjiDigits[value];
  final tens = value ~/ 10;
  final ones = value % 10;
  return '${tens == 1 ? '' : _kanjiDigits[tens]}十'
      '${ones == 0 ? '' : _kanjiDigits[ones]}';
}

/// 令和の年（2019年が1）。
int reiwaYear(DateTime date) => date.year - 2018;

/// 印の傾き（ラジアン）。押すたびに少しずつ違うよう、記録のIDから決める。
double inkanAngle(String visitId) {
  final hash = visitId.codeUnits.fold<int>(
    0,
    (sum, unit) => (sum * 31 + unit) & 0x7fffffff,
  );
  return ((hash % 17) - 8) * math.pi / 180;
}
