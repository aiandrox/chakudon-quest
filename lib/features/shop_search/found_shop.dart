import 'geo.dart';

const shopSearchRadiusMeters = 300;

/// 店の検索（Overpass・OpenPOI）で見つかった店。
class FoundShop {
  const FoundShop({this.osmId, required this.name, required this.location});

  /// OpenStreetMap の ID。OpenPOI で見つかった店は null。
  final String? osmId;
  final String name;
  final GeoPoint location;
}
