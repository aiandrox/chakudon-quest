import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'geo.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const GeolocatorLocationService(),
);

abstract class LocationService {
  /// 許可ダイアログを出さずに現在地を取れる状態か。
  Future<bool> isReady();

  /// 現在地。取れないとき（許可なし・位置情報オフ・時間切れ）はnull。
  /// [requestPermission]がtrueなら、未許可のとき許可ダイアログを出す。
  Future<GeoPoint?> currentPosition({required bool requestPermission});
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  static const _timeout = Duration(seconds: 8);

  @override
  Future<bool> isReady() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      return _isGranted(await Geolocator.checkPermission());
    } catch (_) {
      return false;
    }
  }

  @override
  Future<GeoPoint?> currentPosition({required bool requestPermission}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (!_isGranted(permission)) return null;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: _timeout,
          ),
        );
        return GeoPoint(position.latitude, position.longitude);
      } on TimeoutException {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : GeoPoint(last.latitude, last.longitude);
      }
    } catch (_) {
      return null;
    }
  }

  bool _isGranted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}
