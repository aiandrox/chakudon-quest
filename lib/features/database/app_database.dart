import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../records/models.dart';

part 'app_database.g.dart';

@UseRowClass(Shop)
class Shops extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get osmId => text().nullable()();
  TextColumn get hoursType => textEnum<HoursType>()();
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) await migrator.createTable(activeCheckins);
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
