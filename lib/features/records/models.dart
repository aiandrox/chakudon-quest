/// 店の「攻略しにくさ」（営業の条件とアクセス）。店ごとに当てはまるものをいくつでも付ける。
enum HoursCondition {
  lunchOnly,
  nightOnly,
  weekdaysOnly,
  weekendsOnly,
  fewDays,
  irregular,
  badAccess,
}

enum VisitResult { eaten, retreated }

enum RamenStyle {
  shoyu,
  miso,
  shio,
  tonkotsu,
  iekei,
  jiro,
  tsukemen,
  shirunashi,
  other,
}

class Shop {
  const Shop({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.osmId,
    this.hoursConditions = const {},
    this.strategyMemo = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? osmId;
  final Set<HoursCondition> hoursConditions;

  /// 店ごとの攻略メモ（開店の何分前に着けばよいか、券売機など）。記録ごとのメモとは別。
  final String strategyMemo;
  final DateTime createdAt;
}

class Visit {
  const Visit({
    required this.id,
    required this.shopId,
    required this.result,
    this.photoPath,
    this.checkedInAt,
    required this.eatenAt,
    this.style,
    this.rating,
    required this.isLimited,
    required this.hasTicket,
    required this.memo,
    required this.createdAt,
  });

  final String id;
  final String shopId;
  final VisitResult result;

  /// documentsディレクトリからの相対パス。iOSは更新のたびに絶対パスが変わるため。
  final String? photoPath;
  final DateTime? checkedInAt;
  final DateTime eatenAt;
  final RamenStyle? style;
  final int? rating;
  final bool isLimited;

  /// 整理券制か。今は入力も採点もしないが、過去の記録の値は残している。
  final bool hasTicket;
  final String memo;
  final DateTime createdAt;
}

/// 並んでいる最中の店。記録がまだ無い店のこともあるため、店の情報をそのまま持つ。
class Checkin {
  const Checkin({
    this.shopId,
    this.osmId,
    required this.name,
    this.latitude,
    this.longitude,
    required this.checkedInAt,
  });

  final String? shopId;
  final String? osmId;
  final String name;
  final double? latitude;
  final double? longitude;
  final DateTime checkedInAt;
}

class VisitWithShop {
  const VisitWithShop({required this.visit, required this.shop});

  final Visit visit;
  final Shop shop;
}
