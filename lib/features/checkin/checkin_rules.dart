import '../records/models.dart';

const checkinMaxDistanceMeters = 100;
const checkinTimeout = Duration(hours: 3);

/// 店から100m以内にいるときだけチェックインできる。距離がわからないときはできない。
bool canCheckIn(double? distanceMeters) =>
    distanceMeters != null && distanceMeters <= checkinMaxDistanceMeters;

/// 3時間を超えたチェックインは、取り消し忘れとみなして自動で取り消す。
bool isCheckinExpired(Checkin checkin, DateTime now) =>
    now.difference(checkin.checkedInAt) > checkinTimeout;

int checkinElapsedMinutes(Checkin checkin, DateTime now) {
  final minutes = now.difference(checkin.checkedInAt).inMinutes;
  return minutes < 0 ? 0 : minutes;
}
