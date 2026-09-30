import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../records/models.dart';
import '../records/photo_storage.dart';
import '../records/record_repository.dart';
import '../shop_search/geo.dart';
import '../shop_search/location_service.dart';
import '../shop_search/overpass.dart';
import '../shop_search/overpass_client.dart';
import '../shop_search/shop_candidate.dart';
import 'photo_picker.dart';
import 'record_state.dart';

final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final recordControllerProvider =
    NotifierProvider.autoDispose<RecordController, RecordState>(
      RecordController.new,
    );

class RecordController extends Notifier<RecordState> {
  List<Shop> _knownShops = const [];
  Future<void>? _knownShopsLoad;
  GeoPoint? _here;

  @override
  RecordState build() => const RecordState();

  /// カメラを開き、並行して近くの店を探す。位置情報が未許可のときは、許可ダイアログが
  /// カメラに重ならないよう、撮り終えてから尋ねる。
  Future<void> start({String? recoveredPhotoPath}) async {
    _knownShopsLoad = _loadKnownShops();
    final locationReady = await ref.read(locationServiceProvider).isReady();
    if (!ref.mounted) return;
    if (locationReady) unawaited(searchShops(requestPermission: false));
    if (recoveredPhotoPath != null) {
      _setPhoto(recoveredPhotoPath, fromCamera: true);
    } else {
      await takePhoto();
    }
    if (!ref.mounted) return;
    if (!locationReady) await searchShops(requestPermission: true);
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
      photoTakenAt: ref.read(clockProvider)(),
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
    final here = await ref
        .read(locationServiceProvider)
        .currentPosition(requestPermission: requestPermission);
    if (!ref.mounted) return;
    if (here == null) {
      state = state.copyWith(
        searchStatus: ShopSearchStatus.done,
        searchFailure: ShopSearchFailure.noLocation,
      );
      return;
    }
    _here = here;
    var found = const <OverpassShop>[];
    ShopSearchFailure? failure;
    try {
      found = await ref.read(overpassClientProvider).searchNearby(here);
    } catch (e) {
      debugPrint('Shop search failed: $e');
      failure = ShopSearchFailure.searchFailed;
    }
    await _knownShopsLoad;
    if (!ref.mounted) return;
    state = state.copyWith(
      searchStatus: ShopSearchStatus.done,
      searchFailure: failure,
      candidates: rankShopCandidates(
        here: here,
        found: found,
        knownShops: _knownShops,
      ),
    );
  }

  void selectShop(ShopCandidate shop) {
    state = state.copyWith(
      selectedShop: shop,
      manualName: '',
      nameMatches: const [],
      hoursType: shop.hoursType ?? state.hoursType,
    );
  }

  void setManualName(String name) {
    final query = name.trim().toLowerCase();
    state = state.copyWith(
      manualName: name,
      selectedShop: query.isEmpty ? state.selectedShop : null,
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

  void setHoursType(HoursType type) => state = state.copyWith(hoursType: type);

  void setMemo(String memo) => state = state.copyWith(memo: memo);

  Future<bool> save() async {
    final draft = state;
    if (!draft.canSave) return false;
    state = draft.copyWith(isSaving: true);
    final storage = ref.read(photoStorageProvider);
    String? savedPhoto;
    try {
      final photoPath = draft.photoPath;
      if (photoPath != null) savedPhoto = await storage.save(photoPath);
      final now = ref.read(clockProvider)();
      await ref
          .read(recordRepositoryProvider)
          .saveEatenVisit(
            shop: _shopInput(draft),
            hoursType: draft.hoursType,
            eatenAt: draft.photoTakenAt ?? now,
            rating: draft.rating!,
            photoPath: savedPhoto,
            style: draft.style,
            isLimited: draft.isLimited,
            hasTicket: draft.hasTicket,
            memo: draft.memo.trim(),
            now: now,
          );
      return true;
    } catch (e) {
      debugPrint('Record save failed: $e');
      if (savedPhoto != null) {
        try {
          await storage.delete(savedPhoto);
        } catch (_) {}
      }
      if (ref.mounted) state = state.copyWith(isSaving: false);
      return false;
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
