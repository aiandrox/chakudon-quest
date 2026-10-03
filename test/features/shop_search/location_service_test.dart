import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ramen_in_cho/features/shop_search/location_service.dart';

Position _position({required DateTime timestamp, required double accuracy}) =>
    Position(
      latitude: 35.0,
      longitude: 139.0,
      timestamp: timestamp,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  final now = DateTime(2026, 9, 30, 12);

  test('直近の正確な位置だけを、時間切れのときの代わりに使う', () {
    bool usable({required Duration age, required double accuracy}) =>
        GeolocatorLocationService.isUsableLastKnownPosition(
          _position(timestamp: now.subtract(age), accuracy: accuracy),
          now,
        );

    expect(usable(age: const Duration(minutes: 2), accuracy: 100), isTrue);
    expect(usable(age: const Duration(minutes: 3), accuracy: 10), isFalse);
    expect(usable(age: const Duration(seconds: 10), accuracy: 101), isFalse);
  });
}
