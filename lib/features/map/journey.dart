import '../records/models.dart';
import '../scoring/points.dart';
import '../shop_search/geo.dart';

/// 旅路の1か所（食べた店）。
class JourneyStop {
  const JourneyStop({
    required this.shop,
    required this.location,
    required this.eatenAt,
  });

  final Shop shop;
  final GeoPoint location;
  final DateTime eatenAt;
}

/// 食べた店を、食べた順に並べる。位置のわからない店は除き、同じ店が続くときは1つにまとめる。
/// [year]を渡すとその年だけ。
List<JourneyStop> journeyStops(List<ScoredVisit> scored, {int? year}) {
  final stops = <JourneyStop>[];
  for (final entry in scored) {
    final visit = entry.visit;
    if (visit.result != VisitResult.eaten) continue;
    if (year != null && visit.eatenAt.year != year) continue;
    final latitude = entry.shop.latitude;
    final longitude = entry.shop.longitude;
    if (latitude == null || longitude == null) continue;
    if (stops.isNotEmpty && stops.last.shop.id == entry.shop.id) continue;
    stops.add(
      JourneyStop(
        shop: entry.shop,
        location: GeoPoint(latitude, longitude),
        eatenAt: visit.eatenAt,
      ),
    );
  }
  return stops;
}

/// 旅路の長さ（店と店を直線でつないだ距離、km）。
double journeyKilometers(List<JourneyStop> stops) {
  var meters = 0.0;
  for (var i = 1; i < stops.length; i++) {
    meters += distanceMeters(stops[i - 1].location, stops[i].location);
  }
  return meters / 1000;
}

/// 遠征とみなす、拠点からの距離。
const expeditionKilometers = 20;

/// 拠点とみなす「同じあたり」の広さ（半径）と、そこで食べた杯数。
const homeBaseKilometers = 2;
const homeBaseBowls = 5;

/// 拠点。同じあたり（[homeBaseKilometers]以内）で[homeBaseBowls]杯以上食べると、そこが拠点になる。
class HomeBase {
  const HomeBase({
    required this.shop,
    required this.location,
    required this.bowls,
  });

  /// 拠点の中心にした店（まわりでいちばん多く食べた店）。
  final Shop shop;
  final GeoPoint location;

  /// 拠点のあたりで食べた杯数。
  final int bowls;
}

/// 全期間で見た拠点。まだできていなければnull。家の位置は持たないので、食べた店が集まっている場所を拠点とみなす。
/// 一度できれば、引っ越して記録が増えても消えない（奥義「拠点を構える」に使う）。
HomeBase? homeBase(List<ScoredVisit> scored) => _baseIn(_eatenStops(scored));

/// 「今の拠点」を決めるときに見る、いちばん新しい記録からさかのぼる月数。
const homeBaseRecentMonths = 12;

/// 今の拠点。いちばん新しい記録から[homeBaseRecentMonths]か月の記録で決め、
/// その間で拠点ができなければ全期間で決める（引っ越しても、新しいあたりが拠点になる）。
HomeBase? currentHomeBase(List<ScoredVisit> scored) =>
    _currentBase(_eatenStops(scored));

HomeBase? _currentBase(List<JourneyStop> eaten) {
  if (eaten.isEmpty) return null;
  final newest = eaten
      .map((s) => s.eatenAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final since = DateTime(
    newest.year,
    newest.month - homeBaseRecentMonths,
    newest.day,
    newest.hour,
    newest.minute,
    newest.second,
  );
  return _baseIn([
        for (final stop in eaten)
          if (!stop.eatenAt.isBefore(since)) stop,
      ]) ??
      _baseIn(eaten);
}

HomeBase? _baseIn(List<JourneyStop> eaten) {
  final bowlsByShop = <String, int>{};
  final stopByShop = <String, JourneyStop>{};
  for (final stop in eaten) {
    bowlsByShop.update(stop.shop.id, (n) => n + 1, ifAbsent: () => 1);
    stopByShop.putIfAbsent(stop.shop.id, () => stop);
  }
  HomeBase? best;
  for (final center in stopByShop.values) {
    var bowls = 0;
    for (final other in stopByShop.values) {
      if (distanceMeters(center.location, other.location) <=
          homeBaseKilometers * 1000) {
        bowls += bowlsByShop[other.shop.id]!;
      }
    }
    if (bowls < homeBaseBowls) continue;
    if (best == null || bowls > best.bowls) {
      best = HomeBase(
        shop: center.shop,
        location: center.location,
        bowls: bowls,
      );
    }
  }
  return best;
}

List<JourneyStop> _eatenStops(List<ScoredVisit> scored) => [
  for (final entry in scored)
    if (entry.visit.result == VisitResult.eaten &&
        entry.shop.latitude != null &&
        entry.shop.longitude != null)
      JourneyStop(
        shop: entry.shop,
        location: GeoPoint(entry.shop.latitude!, entry.shop.longitude!),
        eatenAt: entry.visit.eatenAt,
      ),
];

/// 遠くへ食べに行った1日。
class Expedition {
  const Expedition({required this.day, required this.stops});

  final DateTime day;
  final List<JourneyStop> stops;
}

/// その日の時点の拠点（その日までの記録で決めた今の拠点）から [expeditionKilometers] 以上離れた店で
/// 食べた日を、日ごとにまとめる（新しい順）。引っ越しても、前の遠征は変わらない。
/// その日に拠点がまだ無ければ、遠征も無い。[year]を渡すと、その年の遠征だけを返す。
List<Expedition> expeditions(List<ScoredVisit> scored, {int? year}) {
  final eaten = _eatenStops(scored);
  final byDay = <DateTime, List<JourneyStop>>{};
  for (final stop in eaten) {
    final at = stop.eatenAt;
    if (year != null && at.year != year) continue;
    (byDay[DateTime(at.year, at.month, at.day)] ??= []).add(stop);
  }
  final result = <Expedition>[];
  for (final MapEntry(key: day, value: stops) in byDay.entries) {
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    final base = _currentBase([
      for (final stop in eaten)
        if (stop.eatenAt.isBefore(nextDay)) stop,
    ]);
    if (base == null) continue;
    final far = [
      for (final stop in stops)
        if (distanceMeters(base.location, stop.location) >=
            expeditionKilometers * 1000)
          stop,
    ];
    if (far.isNotEmpty) result.add(Expedition(day: day, stops: far));
  }
  return result..sort((a, b) => b.day.compareTo(a.day));
}
