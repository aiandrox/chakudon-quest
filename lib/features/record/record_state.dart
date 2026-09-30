import '../records/models.dart';
import '../shop_search/shop_candidate.dart';

enum ShopSearchStatus { idle, searching, done }

enum ShopSearchFailure { noLocation, searchFailed }

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

  bool get hasShop => selectedShop != null || manualName.trim().isNotEmpty;

  bool get hasInput => photoPath != null || hasShop || rating != null;

  bool get canSave => hasShop && rating != null && !isSaving;

  RecordState copyWith({
    Object? photoPath = _unset,
    Object? photoTakenAt = _unset,
    bool? photoFromCamera,
    bool? photoStepDone,
    ShopSearchStatus? searchStatus,
    Object? searchFailure = _unset,
    List<ShopCandidate>? candidates,
    List<ShopCandidate>? nameMatches,
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
