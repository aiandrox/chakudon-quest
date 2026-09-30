import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/database/app_database.dart';
import 'package:chakudon_quest/features/record/photo_picker.dart';
import 'package:chakudon_quest/features/shop_search/geo.dart';
import 'package:chakudon_quest/features/shop_search/location_service.dart';
import 'package:chakudon_quest/features/shop_search/overpass.dart';
import 'package:chakudon_quest/features/shop_search/overpass_client.dart';

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
