import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../checkin/checkin_rules.dart';
import '../records/clock.dart';
import '../records/models.dart';
import '../records/photo_storage.dart';
import '../records/record_repository.dart';
import '../shop_search/geo.dart';
import '../shop_search/location_service.dart';
import '../shop_search/shop_candidate.dart';
import '../shop_search/shop_search_service.dart';
import 'photo_picker.dart';
import 'record_state.dart';

final recordControllerProvider =
    NotifierProvider.autoDispose<RecordController, RecordState>(
      RecordController.new,
    );

class RecordController extends Notifier<RecordState> {
  List<Shop> _knownShops = const [];
  GeoPoint? _here;

  @override
  RecordState build() => const RecordState();

  /// カメラを開き、並行して近くの店を探す。位置情報が未許可のときは、許可ダイアログが
  /// カメラに重ならないよう、撮り終えてから尋ねる。
  Future<void> start({String? recoveredPhotoPath}) async {
    unawaited(_loadKnownShops());
    await _loadCheckin();
    if (!ref.mounted) return;
    final locationReady = await ref.read(locationServiceProvider).isReady();
    if (!ref.mounted) return;
    if (locationReady) unawaited(searchShops(requestPermission: false));
    if (recoveredPhotoPath != null) {
      // 取り戻した写真はカメラとギャラリーのどちらのものか区別できない。
      _setPhoto(recoveredPhotoPath, fromCamera: false);
    } else {
      await takePhoto();
    }
    if (!ref.mounted) return;
    if (!locationReady) await searchShops(requestPermission: true);
  }

  /// 並んでいる店があれば、その店を選んだ状態で始める。
  Future<void> _loadCheckin() async {
    try {
      final checkin = await ref.read(recordRepositoryProvider).activeCheckin();
      if (!ref.mounted || checkin == null) return;
      if (isCheckinExpired(checkin, ref.read(clockProvider)())) return;
      final latitude = checkin.latitude;
      final longitude = checkin.longitude;
      final shop = ShopCandidate(
        shopId: checkin.shopId,
        osmId: checkin.osmId,
        name: checkin.name,
        location: latitude != null && longitude != null
            ? GeoPoint(latitude, longitude)
            : null,
      );
      state = state.copyWith(
        checkin: checkin,
        checkinShop: shop,
        selectedShop: shop,
      );
    } catch (e) {
      debugPrint('Checkin load failed: $e');
    }
  }

  Future<void> _loadKnownShops() async {
    try {
      _knownShops = await ref.read(recordRepositoryProvider).allShops();
    } catch (e) {
      debugPrint('Known shops load failed: $e');
    }
  }

  Future<void> takePhoto() async {
    final path = await ref.read(photoPickerProvider).takePhoto();
    if (!ref.mounted) return;
    if (path == null) {
      state = state.copyWith(photoStepDone: true);
    } else {
      _setPhoto(path, fromCamera: true);
    }
  }

  Future<void> pickFromGallery() async {
    final path = await ref.read(photoPickerProvider).pickFromGallery();
    if (!ref.mounted || path == null) return;
    _setPhoto(path, fromCamera: false);
  }

  void _setPhoto(String path, {required bool fromCamera}) {
    state = state.copyWith(
      photoPath: path,
      // 撮り直しても、待ち時間が食べている時間だけ延びないよう最初の時刻を残す。
      photoTakenAt: state.photoTakenAt ?? ref.read(clockProvider)(),
      photoFromCamera: fromCamera,
      photoStepDone: true,
    );
  }

  Future<void> searchShops({required bool requestPermission}) async {
    if (state.searchStatus == ShopSearchStatus.searching) return;
    state = state.copyWith(
      searchStatus: ShopSearchStatus.searching,
      searchFailure: null,
    );
    final result = await ref
        .read(shopSearchServiceProvider)
        .search(requestPermission: requestPermission);
    if (!ref.mounted) return;
    _here = result.here;
    state = state.copyWith(
      searchStatus: ShopSearchStatus.done,
      searchFailure: result.failure,
      candidates: result.candidates,
    );
  }

  void selectShop(ShopCandidate shop) {
    state = state.copyWith(
      selectedShop: shop,
      manualName: '',
      nameMatches: const [],
      chosenHoursType: null,
    );
  }

  void setManualName(String name) {
    final query = name.trim().toLowerCase();
    final deselects = query.isNotEmpty && state.selectedShop != null;
    state = state.copyWith(
      manualName: name,
      selectedShop: deselects ? null : state.selectedShop,
      chosenHoursType: deselects ? null : state.chosenHoursType,
      nameMatches: query.isEmpty
          ? const []
          : [
              for (final shop in _knownShops)
                if (shop.name.toLowerCase().contains(query))
                  ShopCandidate.fromShop(shop),
            ].take(maxShopCandidates).toList(),
    );
  }

  void setRating(int rating) => state = state.copyWith(rating: rating);

  void setStyle(RamenStyle? style) => state = state.copyWith(style: style);

  void setLimited(bool value) => state = state.copyWith(isLimited: value);

  void setHasTicket(bool value) => state = state.copyWith(hasTicket: value);

  void setHoursType(HoursType type) =>
      state = state.copyWith(chosenHoursType: type);

  void setMemo(String memo) => state = state.copyWith(memo: memo);

  /// 保存できたら記録のID、できなければnullを返す。
  Future<String?> save() async {
    final draft = state;
    if (!draft.canSave) return null;
    state = draft.copyWith(isSaving: true);
    final storage = ref.read(photoStorageProvider);
    String? savedPhoto;
    try {
      final photoPath = draft.photoPath;
      if (photoPath != null) savedPhoto = await storage.save(photoPath);
      final now = ref.read(clockProvider)();
      final visit = await ref
          .read(recordRepositoryProvider)
          .saveEatenVisit(
            shop: _shopInput(draft),
            hoursType: draft.chosenHoursType,
            eatenAt: draft.photoTakenAt ?? now,
            rating: draft.rating,
            photoPath: savedPhoto,
            checkedInAt: draft.isCheckinShopSelected
                ? draft.checkin?.checkedInAt
                : null,
            style: draft.style,
            isLimited: draft.isLimited,
            hasTicket: draft.hasTicket,
            memo: draft.memo.trim(),
            now: now,
          );
      return visit.id;
    } catch (e) {
      debugPrint('Record save failed: $e');
      if (savedPhoto != null) {
        try {
          await storage.delete(savedPhoto);
        } catch (_) {}
      }
      if (ref.mounted) state = state.copyWith(isSaving: false);
      return null;
    }
  }

  ShopInput _shopInput(RecordState draft) {
    final selected = draft.selectedShop;
    if (selected != null) {
      return ShopInput(
        shopId: selected.shopId,
        osmId: selected.osmId,
        name: selected.name,
        latitude: selected.location?.latitude,
        longitude: selected.location?.longitude,
      );
    }
    // ギャラリーの写真は店にいるときに選んだとは限らないため、現在地を店の位置にしない。
    final here = draft.photoFromCamera ? _here : null;
    return ShopInput(
      name: draft.manualName,
      latitude: here?.latitude,
      longitude: here?.longitude,
    );
  }
}
