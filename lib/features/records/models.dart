enum HoursType { normal, lunchOnly, fewDays }

enum VisitResult { eaten, retreated }

enum RamenStyle { shoyu, miso, shio, tonkotsu, iekei, jiro, tsukemen, other }

class Shop {
  const Shop({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.osmId,
    required this.hoursType,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? osmId;
  final HoursType hoursType;
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
  final bool hasTicket;
  final String memo;
  final DateTime createdAt;
}

class VisitWithShop {
  const VisitWithShop({required this.visit, required this.shop});

  final Visit visit;
  final Shop shop;
}
