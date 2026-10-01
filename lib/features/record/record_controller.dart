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
import 'photo_metadata.dart';
import 'photo_picker.dart';
import 'record_state.dart';

final recordControllerProvider =
    NotifierProvider.autoDispose<RecordController, RecordState>(
      RecordController.new,
    );

class RecordController extends Notifier<RecordState> {
  List<Shop> _knownShops = const [];
  GeoPoint? _here;
  int _searchGeneration = 0;

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
      await _setGalleryPhoto(recoveredPhotoPath);
    } else {
      await takePhoto();
    }
    if (!ref.mounted) return;
    if (!locationReady) await searchShops(requestPermission: true);
  }

  /// 並んでいる店があれば、その店を選んだ状態で始める。
  Future<void> _loadCheckin() async {
    try {
      final repository = ref.read(recordRepositoryProvider);
      final checkin = await repository.activeCheckin();
      if (!ref.mounted || checkin == null) return;
      if (isCheckinExpired(checkin, ref.read(clockProvider)())) return;
      // 記録済みの店なら、攻略メモや営業の条件も引き継ぐため店から作る。
      final known = checkin.shopId == null
          ? null
          : (await repository.allShops())
                .where((shop) => shop.id == checkin.shopId)
                .firstOrNull;
      if (!ref.mounted) return;
      final latitude = checkin.latitude;
      final longitude = checkin.longitude;
      final shop = known != null
          ? ShopCandidate.fromShop(known)
          : ShopCandidate(
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
    await _setGalleryPhoto(path);
  }

  /// 過去の写真から記録できるよう、写真の撮影日時を食べた日時にし、撮影場所で店を探す。
  Future<void> _setGalleryPhoto(String path) async {
    final metadata = await ref.read(photoMetadataReaderProvider).read(path);
    if (!ref.mounted) return;
    _setPhoto(path, fromCamera: false, metadata: metadata);
  }

  void _setPhoto(
    String path, {
    required bool fromCamera,
    PhotoMetadata metadata = PhotoMetadata.empty,
  }) {
    final previousLocation = state.photoLocation;
    final takenAt = metadata.takenAt;
    final now = ref.read(clockProvider)();
    state = state.copyWith(
      photoPath: path,
      // 撮り直しても、待ち時間が食べている時間だけ延びないよう最初の時刻を残す。
      // 前の写真の撮影日時を使っていたときは、今撮ったので今の時刻にする。
      photoTakenAt:
          takenAt ??
          (state.photoDateFromPhoto ? now : state.photoTakenAt ?? now),
      photoDateFromPhoto: takenAt != null,
      photoLocation: metadata.location,
      photoFromCamera: fromCamera,
      photoStepDone: true,
    );
    final location = metadata.location;
    if (location != null || previousLocation != null) {
      unawaited(searchShops(requestPermission: false, force: true));
    }
  }

  /// 写真に撮影場所があればそこで、無ければ現在地で探す。
  Future<void> searchShops({
    required bool requestPermission,
    bool force = false,
  }) async {
    if (!force && state.searchStatus == ShopSearchStatus.searching) return;
    final generation = ++_searchGeneration;
    final near = state.photoLocation;
    // 前の写真の場所が、探し終えるまでの間に手入力の店の位置にならないよう消しておく。
    _here = null;
    state = state.copyWith(
      searchStatus: ShopSearchStatus.searching,
      searchFailure: null,
    );
    final result = await ref
        .read(shopSearchServiceProvider)
        .search(requestPermission: requestPermission, near: near);
    if (!ref.mounted || generation != _searchGeneration) return;
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
      chosenHoursConditions: null,
    );
  }

  void setManualName(String name) {
    final query = name.trim().toLowerCase();
    final deselects = query.isNotEmpty && state.selectedShop != null;
    state = state.copyWith(
      manualName: name,
      selectedShop: deselects ? null : state.selectedShop,
      chosenHoursConditions: deselects ? null : state.chosenHoursConditions,
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

  void setHoursConditions(Set<HoursCondition> conditions) =>
      state = state.copyWith(chosenHoursConditions: conditions);

  void setMemo(String memo) => state = state.copyWith(memo: memo);

  void setWaitMinutes(int? minutes) =>
      state = state.copyWith(manualWaitMinutes: minutes);

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
      final eatenAt = draft.photoTakenAt ?? now;
      final queuedAt = _checkedInAt(draft, eatenAt);
      final manualWait = draft.manualWaitMinutes;
      final visit = await ref
          .read(recordRepositoryProvider)
          .saveEatenVisit(
            shop: _shopInput(draft),
            hoursConditions: draft.chosenHoursConditions,
            eatenAt: eatenAt,
            rating: draft.rating,
            photoPath: savedPhoto,
            checkedInAt:
                queuedAt ??
                (manualWait == null || draft.isCheckinShopSelected
                    ? null
                    : eatenAt.subtract(Duration(minutes: manualWait))),
            endsCheckin: queuedAt != null,
            style: draft.style,
            isLimited: draft.isLimited,
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

  /// 並んだ店を選んでいて、並び始めたあとに食べたときだけ待ち時間をつける
  /// （並んでいる最中に、昔の写真から別の日の記録をすることもあるため）。
  DateTime? _checkedInAt(RecordState draft, DateTime eatenAt) {
    final checkedInAt = draft.checkin?.checkedInAt;
    if (!draft.isCheckinShopSelected || checkedInAt == null) return null;
    return eatenAt.isBefore(checkedInAt) ? null : checkedInAt;
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
    // 写真に撮影場所があれば、そこを店の位置にする。
    final here = draft.photoLocation ?? (draft.photoFromCamera ? _here : null);
    return ShopInput(
      name: draft.manualName,
      latitude: here?.latitude,
      longitude: here?.longitude,
    );
  }
}
