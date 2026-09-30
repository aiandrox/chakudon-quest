import 'dart:math' as math;

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

const _earthRadiusMeters = 6371000.0;

double distanceMeters(GeoPoint a, GeoPoint b) {
  final lat1 = _radians(a.latitude);
  final lat2 = _radians(b.latitude);
  final dLat = lat2 - lat1;
  final dLon = _radians(b.longitude - a.longitude);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
}

double _radians(double degrees) => degrees * math.pi / 180;
