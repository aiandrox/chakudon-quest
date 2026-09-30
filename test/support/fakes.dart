import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/backup/backup_codec.dart';
import 'package:chakudon_quest/features/database/app_database.dart';
import 'package:chakudon_quest/features/record/photo_picker.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/overpass_client.dart';
import 'package:chakudon_quest/features/shop_search/shop_search_service.dart';

AppDatabase createTestDatabase() {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  return database;
}

Directory createTempDirectory() {
  final directory = Directory.systemTemp.createTempSync('chakudon_test');
  addTearDown(() => directory.deleteSync(recursive: true));
  return directory;
}

class FakeLocationService implements LocationService {
  FakeLocationService({this.position, this.ready = true});

  GeoPoint? position;
  bool ready;
  final requests = <bool>[];

  @override
  Future<bool> isReady() async => ready;

  @override
  Future<GeoPoint?> currentPosition({required bool requestPermission}) async {
    requests.add(requestPermission);
    return position;
  }
}

class FakeOverpassClient implements OverpassClient {
  FakeOverpassClient({this.shops = const [], this.error});

  List<OverpassShop> shops;
  Object? error;
  int calls = 0;

  @override
  Future<List<OverpassShop>> searchNearby(GeoPoint center) async {
    calls++;
    final error = this.error;
    if (error != null) throw error;
    return shops;
  }
}

class FakePhotoPicker implements PhotoPicker {
  FakePhotoPicker({this.cameraPath, this.galleryPath, this.lostPath});

  String? cameraPath;
  String? galleryPath;
  String? lostPath;

  @override
  Future<String?> takePhoto() async => cameraPath;

  @override
  Future<String?> pickFromGallery() async => galleryPath;

  @override
  Future<String?> retrieveLostPhoto() async => lostPath;
}

typedef VisitUpdate = ({
  String visitId,
  String shopName,
  Set<HoursCondition>? hoursConditions,
  DateTime eatenAt,
  int? rating,
  RamenStyle? style,
  bool isLimited,
  bool hasTicket,
  String memo,
});

/// 画面のテスト用。driftを通さずに、呼ばれた内容だけを覚える。
class FakeRecordRepository implements RecordRepository {
  final updates = <VisitUpdate>[];
  final deletedVisitIds = <String>[];
  String? deletedPhotoPath;
  Object? error;

  @override
  Future<void> updateVisit({
    required String visitId,
    required String shopName,
    required Set<HoursCondition>? hoursConditions,
    required DateTime eatenAt,
    required int? rating,
    required RamenStyle? style,
    required bool isLimited,
    required bool hasTicket,
    required String memo,
    required DateTime now,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    updates.add((
      visitId: visitId,
      shopName: shopName,
      hoursConditions: hoursConditions,
      eatenAt: eatenAt,
      rating: rating,
      style: style,
      isLimited: isLimited,
      hasTicket: hasTicket,
      memo: memo,
    ));
  }

  @override
  Future<String?> deleteVisit(String visitId) async {
    final error = this.error;
    if (error != null) throw error;
    deletedVisitIds.add(visitId);
    return deletedPhotoPath;
  }

  final checkins = <ShopInput>[];
  final retreatMemos = <String>[];
  int cancelCount = 0;

  @override
  Future<void> checkIn({required ShopInput shop, required DateTime at}) async {
    final error = this.error;
    if (error != null) throw error;
    checkins.add(shop);
  }

  Object? importError;

  @override
  Future<int> importAll(BackupData data) async {
    final error = importError;
    if (error != null) throw error;
    return data.visits.length;
  }

  final shopMemos = <String, String>{};

  @override
  Future<void> setShopMemo(String shopId, String memo) async {
    shopMemos[shopId] = memo;
  }

  final ratings = <String, int>{};
  Object? ratingError;

  @override
  Future<void> setRating(String visitId, int rating) async {
    final error = ratingError;
    if (error != null) throw error;
    ratings[visitId] = rating;
  }

  @override
  Future<void> cancelCheckin() async {
    cancelCount++;
  }

  @override
  Future<Visit> saveRetreat({
    required Checkin checkin,
    String memo = '',
    required DateTime now,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    retreatMemos.add(memo);
    return Visit(
      id: 'retreat',
      shopId: 'shop',
      result: VisitResult.retreated,
      checkedInAt: checkin.checkedInAt,
      eatenAt: now,
      isLimited: false,
      hasTicket: false,
      memo: memo,
      createdAt: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeShopSearchService implements ShopSearchService {
  FakeShopSearchService(this.result);

  ShopSearchResult result;

  @override
  Future<ShopSearchResult> search({required bool requestPermission}) async =>
      result;
}
