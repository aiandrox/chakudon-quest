import '../records/models.dart';
import '../shop_search/shop_candidate.dart';
import '../shop_search/shop_search_service.dart';

enum ShopSearchStatus { idle, searching, done }

const _unset = Object();

class RecordState {
  const RecordState({
    this.photoPath,
    this.photoTakenAt,
    this.photoFromCamera = false,
    this.photoStepDone = false,
    this.searchStatus = ShopSearchStatus.idle,
    this.searchFailure,
    this.candidates = const [],
    this.nameMatches = const [],
    this.checkin,
    this.checkinShop,
    this.selectedShop,
    this.manualName = '',
    this.rating,
    this.style,
    this.isLimited = false,
    this.hasTicket = false,
    this.chosenHoursType,
    this.memo = '',
    this.isSaving = false,
  });

  /// image_pickerが返した一時ファイルのパス。
  final String? photoPath;
  final DateTime? photoTakenAt;
  final bool photoFromCamera;

  /// 最初のカメラ起動が終わったか（撮った・キャンセルしたのどちらでも）。
  final bool photoStepDone;

  final ShopSearchStatus searchStatus;
  final ShopSearchFailure? searchFailure;
  final List<ShopCandidate> candidates;

  /// 手入力中の店名に合う、記録済みの店。
  final List<ShopCandidate> nameMatches;

  /// 並んでいる最中のチェックインと、その店。
  final Checkin? checkin;
  final ShopCandidate? checkinShop;
  final ShopCandidate? selectedShop;
  final String manualName;
  final int? rating;
  final RamenStyle? style;
  final bool isLimited;
  final bool hasTicket;

  /// 利用者がこの画面で選んだ営業時間の種類。選んでいなければnull。
  final HoursType? chosenHoursType;
  final String memo;
  final bool isSaving;

  HoursType get hoursType =>
      chosenHoursType ?? selectedShop?.hoursType ?? HoursType.normal;

  /// 並んでいる店を選んでいるか。このときだけ待ち時間を記録する。
  bool get isCheckinShopSelected {
    final selected = selectedShop;
    final checkedIn = checkinShop;
    return selected != null &&
        checkedIn != null &&
        isSameShop(selected, checkedIn);
  }

  bool get hasShop => selectedShop != null || manualName.trim().isNotEmpty;

  bool get hasInput =>
      photoPath != null ||
      rating != null ||
      manualName.trim().isNotEmpty ||
      (selectedShop != null && !identical(selectedShop, checkinShop));

  /// ★は食べ終わってから付けることが多いため、店さえ決まれば保存できる。
  bool get canSave => hasShop && !isSaving;

  RecordState copyWith({
    Object? photoPath = _unset,
    Object? photoTakenAt = _unset,
    bool? photoFromCamera,
    bool? photoStepDone,
    ShopSearchStatus? searchStatus,
    Object? searchFailure = _unset,
    List<ShopCandidate>? candidates,
    List<ShopCandidate>? nameMatches,
    Checkin? checkin,
    ShopCandidate? checkinShop,
    Object? selectedShop = _unset,
    String? manualName,
    Object? rating = _unset,
    Object? style = _unset,
    bool? isLimited,
    bool? hasTicket,
    Object? chosenHoursType = _unset,
    String? memo,
    bool? isSaving,
  }) {
    return RecordState(
      photoPath: photoPath == _unset ? this.photoPath : photoPath as String?,
      photoTakenAt: photoTakenAt == _unset
          ? this.photoTakenAt
          : photoTakenAt as DateTime?,
      photoFromCamera: photoFromCamera ?? this.photoFromCamera,
      photoStepDone: photoStepDone ?? this.photoStepDone,
      searchStatus: searchStatus ?? this.searchStatus,
      searchFailure: searchFailure == _unset
          ? this.searchFailure
          : searchFailure as ShopSearchFailure?,
      candidates: candidates ?? this.candidates,
      nameMatches: nameMatches ?? this.nameMatches,
      checkin: checkin ?? this.checkin,
      checkinShop: checkinShop ?? this.checkinShop,
      selectedShop: selectedShop == _unset
          ? this.selectedShop
          : selectedShop as ShopCandidate?,
      manualName: manualName ?? this.manualName,
      rating: rating == _unset ? this.rating : rating as int?,
      style: style == _unset ? this.style : style as RamenStyle?,
      isLimited: isLimited ?? this.isLimited,
      hasTicket: hasTicket ?? this.hasTicket,
      chosenHoursType: chosenHoursType == _unset
          ? this.chosenHoursType
          : chosenHoursType as HoursType?,
      memo: memo ?? this.memo,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
