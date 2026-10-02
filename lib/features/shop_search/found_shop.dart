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

/// 表記ゆれを許して同じ店とみなす距離。同じ名前の別の支店（数百 m 離れている）と混ざらない程度に狭くする。
const lookAlikeShopMeters = 100;

/// 出どころの違う（ID で比べられない）2つの店が同じ店か。
/// 近くにあり、空白や全角半角を無視して一方の名前がもう一方を含むなら同じ店とみなす（「鴨 to 葱」と「らーめん鴨to葱」）。
bool looksLikeSameShop(String aName, GeoPoint a, String bName, GeoPoint b) {
  if (distanceMeters(a, b) > lookAlikeShopMeters) return false;
  return shopNamesLookAlike(aName, bName);
}

bool shopNamesLookAlike(String a, String b) {
  final aName = normalizeShopName(a);
  final bName = normalizeShopName(b);
  final (shorter, longer) = aName.length <= bName.length
      ? (aName, bName)
      : (bName, aName);
  return shorter.length >= 2 && longer.contains(shorter);
}

/// 空白を除き、全角英数を半角に、英字を小文字にそろえる。
String normalizeShopName(String name) {
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    if (rune == 0x20 || rune == 0x3000) continue;
    final ascii = rune >= 0xFF01 && rune <= 0xFF5E ? rune - 0xFEE0 : rune;
    buffer.writeCharCode(ascii);
  }
  return buffer.toString().toLowerCase();
}
