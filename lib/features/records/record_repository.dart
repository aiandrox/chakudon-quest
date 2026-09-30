import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
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

  Future<Visit> saveEatenVisit({
    required ShopInput shop,
    required HoursType hoursType,
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
    HoursType hoursType,
    DateTime now,
  ) async {
    final existing = await _findShop(input);
    if (existing != null) {
      if (existing.hoursType != hoursType) {
        await (_db.update(_db.shops)..where((s) => s.id.equals(existing.id)))
            .write(ShopsCompanion(hoursType: Value(hoursType)));
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
            hoursType: hoursType,
            createdAt: now,
          ),
        );
    return id;
  }

  Future<Shop?> _findShop(ShopInput input) {
    final query = _db.select(_db.shops)..limit(1);
    if (input.shopId != null) {
      query.where((s) => s.id.equals(input.shopId!));
    } else if (input.osmId != null) {
      query.where((s) => s.osmId.equals(input.osmId!));
    } else {
      query.where((s) => s.name.equals(input.name.trim()));
    }
    return query.getSingleOrNull();
  }
}
