import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../records/models.dart';

part 'app_database.g.dart';

/// 営業時間の条件を、定義順の名前をカンマでつないだ文字列で保存する。
class HoursConditionsConverter
    extends TypeConverter<Set<HoursCondition>, String> {
  const HoursConditionsConverter();

  @override
  Set<HoursCondition> fromSql(String fromDb) {
    final byName = HoursCondition.values.asNameMap();
    return {for (final name in fromDb.split(',')) ?byName[name]};
  }

  @override
  String toSql(Set<HoursCondition> value) => [
    for (final condition in HoursCondition.values)
      if (value.contains(condition)) condition.name,
  ].join(',');
}

@UseRowClass(Shop)
class Shops extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get osmId => text().nullable()();
  TextColumn get hoursConditions => text()
      .map(const HoursConditionsConverter())
      .withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@UseRowClass(Visit)
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().references(Shops, #id)();
  TextColumn get result => textEnum<VisitResult>()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get checkedInAt => dateTime().nullable()();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get style => textEnum<RamenStyle>().nullable()();
  IntColumn get rating => integer().nullable()();
  BoolColumn get isLimited => boolean().withDefault(const Constant(false))();
  BoolColumn get hasTicket => boolean().withDefault(const Constant(false))();
  TextColumn get memo => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 並んでいる最中のチェックイン。同時に1件だけなので、`id`は常に[activeCheckinId]。
class ActiveCheckins extends Table {
  IntColumn get id => integer()();
  TextColumn get shopId => text().nullable()();
  TextColumn get osmId => text().nullable()();
  TextColumn get name => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get checkedInAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

const activeCheckinId = 1;

@DriftDatabase(tables: [Shops, Visits, ActiveCheckins])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'chakudon_quest'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(activeCheckins);
      if (from < 3) {
        // 営業時間の種類（1つだけ選ぶ）を、条件（いくつでも選べる）に置き換える。
        await migrator.alterTable(
          TableMigration(
            shops,
            columnTransformer: {
              shops.hoursConditions: const CustomExpression<String>(
                "CASE hours_type WHEN 'lunchOnly' THEN 'lunchOnly' "
                "WHEN 'fewDays' THEN 'fewDays' ELSE '' END",
              ),
            },
            newColumns: [shops.hoursConditions],
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
