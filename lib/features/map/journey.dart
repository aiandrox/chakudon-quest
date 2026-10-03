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

/// 拠点。まだできていなければnull。家の位置は持たないので、食べた店が集まっている場所を拠点とみなす。
HomeBase? homeBase(List<ScoredVisit> scored) {
  final eaten = _eatenStops(scored);
  HomeBase? best;
  for (final center in eaten) {
    final bowls = eaten
        .where(
          (s) =>
              distanceMeters(center.location, s.location) <=
              homeBaseKilometers * 1000,
        )
        .length;
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

/// 拠点から [expeditionKilometers] 以上離れた店で食べた日を、日ごとにまとめる（新しい順）。
/// 拠点がまだ無ければ、遠征も無い。[year]を渡すと、その年の遠征だけを返す。
List<Expedition> expeditions(List<ScoredVisit> scored, {int? year}) {
  final base = homeBase(scored);
  if (base == null) return const [];
  final byDay = <DateTime, List<JourneyStop>>{};
  for (final stop in _eatenStops(scored)) {
    final at = stop.eatenAt;
    if (year != null && at.year != year) continue;
    if (distanceMeters(base.location, stop.location) <
        expeditionKilometers * 1000) {
      continue;
    }
    (byDay[DateTime(at.year, at.month, at.day)] ??= []).add(stop);
  }
  return [
    for (final MapEntry(:key, :value) in byDay.entries)
      Expedition(day: key, stops: value),
  ]..sort((a, b) => b.day.compareTo(a.day));
}
