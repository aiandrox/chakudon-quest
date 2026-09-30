import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../shop_search/geo.dart';
import 'models.dart';

final recordRepositoryProvider = Provider<RecordRepository>(
  (ref) => RecordRepository(ref.watch(appDatabaseProvider)),
);

final visitsProvider = StreamProvider<List<VisitWithShop>>(
  (ref) => ref.watch(recordRepositoryProvider).watchVisits(),
);

/// 記録につける店の指定。既存の店・OpenStreetMapの店・手入力の店のどれか。
class ShopInput {
  const ShopInput({
    this.shopId,
    this.osmId,
    required this.name,
    this.latitude,
    this.longitude,
  });

  final String? shopId;
  final String? osmId;
  final String name;
  final double? latitude;
  final double? longitude;
}

class RecordRepository {
  RecordRepository(this._db, {this._uuid = const Uuid()});

  final AppDatabase _db;
  final Uuid _uuid;

  Stream<List<VisitWithShop>> watchVisits() {
    final query = _db.select(_db.visits).join([
      innerJoin(_db.shops, _db.shops.id.equalsExp(_db.visits.shopId)),
    ])..orderBy([OrderingTerm.desc(_db.visits.eatenAt)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          VisitWithShop(
            visit: row.readTable(_db.visits),
            shop: row.readTable(_db.shops),
          ),
      ],
    );
  }

  Future<List<Shop>> allShops() => _db.select(_db.shops).get();

  /// [hoursType]は利用者が選んだときだけ渡す。nullなら記録済みの店の値を変えず、
  /// 初めての店は「通常」にする。
  Future<Visit> saveEatenVisit({
    required ShopInput shop,
    HoursType? hoursType,
    required DateTime eatenAt,
    required int rating,
    String? photoPath,
    DateTime? checkedInAt,
    RamenStyle? style,
    bool isLimited = false,
    bool hasTicket = false,
    String memo = '',
    required DateTime now,
  }) {
    return _db.transaction(() async {
      final shopId = await _resolveShop(shop, hoursType, now);
      final visit = Visit(
        id: _uuid.v4(),
        shopId: shopId,
        result: VisitResult.eaten,
        photoPath: photoPath,
        checkedInAt: checkedInAt,
        eatenAt: eatenAt,
        style: style,
        rating: rating,
        isLimited: isLimited,
        hasTicket: hasTicket,
        memo: memo,
        createdAt: now,
      );
      await _db
          .into(_db.visits)
          .insert(
            VisitsCompanion.insert(
              id: visit.id,
              shopId: visit.shopId,
              result: visit.result,
              photoPath: Value(visit.photoPath),
              checkedInAt: Value(visit.checkedInAt),
              eatenAt: visit.eatenAt,
              style: Value(visit.style),
              rating: Value(visit.rating),
              isLimited: Value(visit.isLimited),
              hasTicket: Value(visit.hasTicket),
              memo: Value(visit.memo),
              createdAt: visit.createdAt,
            ),
          );
      return visit;
    });
  }

  Future<String> _resolveShop(
    ShopInput input,
    HoursType? hoursType,
    DateTime now,
  ) async {
    final existing = await _findShop(input);
    if (existing != null) {
      // 手入力で記録した店をあとから検索結果で選んだときは、同じ店として位置とIDを補う。
      final adoptsOsm = existing.osmId == null && input.osmId != null;
      final changesHours = hoursType != null && existing.hoursType != hoursType;
      if (adoptsOsm || changesHours) {
        await (_db.update(
          _db.shops,
        )..where((s) => s.id.equals(existing.id))).write(
          ShopsCompanion(
            osmId: adoptsOsm ? Value(input.osmId) : const Value.absent(),
            latitude: adoptsOsm ? Value(input.latitude) : const Value.absent(),
            longitude: adoptsOsm
                ? Value(input.longitude)
                : const Value.absent(),
            hoursType: changesHours ? Value(hoursType) : const Value.absent(),
          ),
        );
      }
      return existing.id;
    }
    final id = _uuid.v4();
    await _db
        .into(_db.shops)
        .insert(
          ShopsCompanion.insert(
            id: id,
            name: input.name.trim(),
            latitude: Value(input.latitude),
            longitude: Value(input.longitude),
            osmId: Value(input.osmId),
            hoursType: hoursType ?? HoursType.normal,
            createdAt: now,
          ),
        );
    return id;
  }

  Future<Shop?> _findShop(ShopInput input) async {
    final shopId = input.shopId;
    if (shopId != null) {
      return (_db.select(
        _db.shops,
      )..where((s) => s.id.equals(shopId))).getSingleOrNull();
    }
    final osmId = input.osmId;
    if (osmId != null) {
      final byOsmId =
          await (_db.select(_db.shops)
                ..where((s) => s.osmId.equals(osmId))
                ..limit(1))
              .getSingleOrNull();
      if (byOsmId != null) return byOsmId;
    }
    final sameName = await (_db.select(
      _db.shops,
    )..where((s) => s.name.equals(input.name.trim()))).get();
    return _nearestSameShop(input, [
      for (final shop in sameName)
        if (osmId == null || shop.osmId == null) shop,
    ]);
  }

  /// 同じ名前でも離れていれば別の店（支店）として扱う。どちらかの位置がわからないときは
  /// 同じ店とみなす。
  Shop? _nearestSameShop(ShopInput input, List<Shop> sameName) {
    final latitude = input.latitude;
    final longitude = input.longitude;
    Shop? best;
    var bestDistance = double.infinity;
    for (final shop in sameName) {
      var distance = _sameShopRadiusMeters;
      if (latitude != null &&
          longitude != null &&
          shop.latitude != null &&
          shop.longitude != null) {
        distance = distanceMeters(
          GeoPoint(latitude, longitude),
          GeoPoint(shop.latitude!, shop.longitude!),
        );
      }
      if (distance > _sameShopRadiusMeters) continue;
      if (distance < bestDistance) {
        best = shop;
        bestDistance = distance;
      }
    }
    return best;
  }

  static const _sameShopRadiusMeters = 300.0;
}
