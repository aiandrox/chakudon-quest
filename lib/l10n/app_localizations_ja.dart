// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => '着丼クエスト';

  @override
  String get homeEmpty => 'まだ記録がありません\n「＋」から最初の一杯を記録しましょう';

  @override
  String get homeLoadFailed => '記録を読み込めませんでした';

  @override
  String get addRecord => '記録する';

  @override
  String get recordTitle => '記録する';

  @override
  String get recordSaved => '着丼！記録しました';

  @override
  String get recordSaveFailed => '保存できませんでした。もう一度お試しください';

  @override
  String get save => '着丼！';

  @override
  String get takePhoto => 'カメラで撮る';

  @override
  String get retakePhoto => '撮り直す';

  @override
  String get pickFromGallery => 'ギャラリーから選ぶ';

  @override
  String get shopSection => '店';

  @override
  String get shopSearching => '近くの店を探しています…';

  @override
  String get shopNoLocation => '現在地がわかりませんでした。店名を入力してください';

  @override
  String get shopSearchFailed => '店を検索できませんでした。店名を入力してください';

  @override
  String get shopNoCandidates => '近くに候補が見つかりませんでした。店名を入力してください';

  @override
  String get shopNameLabel => '店名を入力';

  @override
  String get shopNameHint => '候補にないときはここに入力';

  @override
  String get shopVisited => '記録あり';

  @override
  String distanceMeters(int meters) {
    return '${meters}m';
  }

  @override
  String get osmAttribution => '© OpenStreetMap contributors';

  @override
  String get ratingSection => '評価';

  @override
  String ratingStar(int stars) {
    return '★$stars';
  }

  @override
  String get optionalSection => 'くわしく（任意）';

  @override
  String get styleSection => '系統';

  @override
  String get styleShoyu => '醤油';

  @override
  String get styleMiso => '味噌';

  @override
  String get styleShio => '塩';

  @override
  String get styleTonkotsu => '豚骨';

  @override
  String get styleIekei => '家系';

  @override
  String get styleJiro => '二郎系';

  @override
  String get styleTsukemen => 'つけ麺';

  @override
  String get styleOther => 'その他';

  @override
  String get isLimited => '限定メニュー';

  @override
  String get hasTicket => '整理券制';

  @override
  String get hoursSection => '店の営業時間';

  @override
  String get hoursNormal => '通常';

  @override
  String get hoursLunchOnly => '昼のみ';

  @override
  String get hoursFewDays => '週3日以下';

  @override
  String get memoLabel => 'メモ';

  @override
  String get discardTitle => '記録をやめますか？';

  @override
  String get discardMessage => '入力した内容は保存されません';

  @override
  String get discardConfirm => 'やめる';

  @override
  String get discardCancel => '続ける';
}
