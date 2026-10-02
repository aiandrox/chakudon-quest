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

/// 遠征とみなす、いつもの場所からの距離。
const expeditionKilometers = 20;

/// 遠くへ食べに行った1日。
class Expedition {
  const Expedition({required this.day, required this.stops});

  final DateTime day;
  final List<JourneyStop> stops;
}

/// いつもの場所（いちばん多く食べた店）から [expeditionKilometers] 以上離れた店で食べた日を、日ごとにまとめる。
/// 家の位置は持たないので、いちばん通っている店を「いつもの場所」とみなす。
List<Expedition> expeditions(List<JourneyStop> stops) {
  if (stops.isEmpty) return const [];
  final counts = <String, int>{};
  for (final stop in stops) {
    counts.update(stop.shop.id, (n) => n + 1, ifAbsent: () => 1);
  }
  final homeId = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  final home = stops.firstWhere((s) => s.shop.id == homeId).location;
  final byDay = <DateTime, List<JourneyStop>>{};
  for (final stop in stops) {
    if (distanceMeters(home, stop.location) < expeditionKilometers * 1000) {
      continue;
    }
    final at = stop.eatenAt;
    (byDay[DateTime(at.year, at.month, at.day)] ??= []).add(stop);
  }
  return [
    for (final MapEntry(:key, :value) in byDay.entries)
      Expedition(day: key, stops: value),
  ]..sort((a, b) => b.day.compareTo(a.day));
}
