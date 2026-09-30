import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ja')];

  /// No description provided for @appName.
  ///
  /// In ja, this message translates to:
  /// **'着丼クエスト'**
  String get appName;

  /// No description provided for @homeEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだ記録がありません\n「＋」から最初の一杯を記録しましょう'**
  String get homeEmpty;

  /// No description provided for @homeLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'記録を読み込めませんでした'**
  String get homeLoadFailed;

  /// No description provided for @addRecord.
  ///
  /// In ja, this message translates to:
  /// **'記録する'**
  String get addRecord;

  /// No description provided for @recordTitle.
  ///
  /// In ja, this message translates to:
  /// **'記録する'**
  String get recordTitle;

  /// No description provided for @recordSaved.
  ///
  /// In ja, this message translates to:
  /// **'着丼！記録しました'**
  String get recordSaved;

  /// No description provided for @recordSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。もう一度お試しください'**
  String get recordSaveFailed;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'着丼！'**
  String get save;

  /// No description provided for @takePhoto.
  ///
  /// In ja, this message translates to:
  /// **'カメラで撮る'**
  String get takePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In ja, this message translates to:
  /// **'撮り直す'**
  String get retakePhoto;

  /// No description provided for @pickFromGallery.
  ///
  /// In ja, this message translates to:
  /// **'ギャラリーから選ぶ'**
  String get pickFromGallery;

  /// No description provided for @shopSection.
  ///
  /// In ja, this message translates to:
  /// **'店'**
  String get shopSection;

  /// No description provided for @shopSearching.
  ///
  /// In ja, this message translates to:
  /// **'近くの店を探しています…'**
  String get shopSearching;

  /// No description provided for @shopNoLocation.
  ///
  /// In ja, this message translates to:
  /// **'現在地がわかりませんでした。店名を入力してください'**
  String get shopNoLocation;

  /// No description provided for @shopSearchFailed.
  ///
  /// In ja, this message translates to:
  /// **'店を検索できませんでした。店名を入力してください'**
  String get shopSearchFailed;

  /// No description provided for @shopNoCandidates.
  ///
  /// In ja, this message translates to:
  /// **'近くに候補が見つかりませんでした。店名を入力してください'**
  String get shopNoCandidates;

  /// No description provided for @shopNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'店名を入力'**
  String get shopNameLabel;

  /// No description provided for @shopNameHint.
  ///
  /// In ja, this message translates to:
  /// **'候補にないときはここに入力'**
  String get shopNameHint;

  /// No description provided for @shopVisited.
  ///
  /// In ja, this message translates to:
  /// **'記録あり'**
  String get shopVisited;

  /// No description provided for @distanceMeters.
  ///
  /// In ja, this message translates to:
  /// **'{meters}m'**
  String distanceMeters(int meters);

  /// No description provided for @osmAttribution.
  ///
  /// In ja, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get osmAttribution;

  /// No description provided for @ratingSection.
  ///
  /// In ja, this message translates to:
  /// **'評価'**
  String get ratingSection;

  /// No description provided for @ratingStar.
  ///
  /// In ja, this message translates to:
  /// **'★{stars}'**
  String ratingStar(int stars);

  /// No description provided for @optionalSection.
  ///
  /// In ja, this message translates to:
  /// **'くわしく（任意）'**
  String get optionalSection;

  /// No description provided for @styleSection.
  ///
  /// In ja, this message translates to:
  /// **'系統'**
  String get styleSection;

  /// No description provided for @styleShoyu.
  ///
  /// In ja, this message translates to:
  /// **'醤油'**
  String get styleShoyu;

  /// No description provided for @styleMiso.
  ///
  /// In ja, this message translates to:
  /// **'味噌'**
  String get styleMiso;

  /// No description provided for @styleShio.
  ///
  /// In ja, this message translates to:
  /// **'塩'**
  String get styleShio;

  /// No description provided for @styleTonkotsu.
  ///
  /// In ja, this message translates to:
  /// **'豚骨'**
  String get styleTonkotsu;

  /// No description provided for @styleIekei.
  ///
  /// In ja, this message translates to:
  /// **'家系'**
  String get styleIekei;

  /// No description provided for @styleJiro.
  ///
  /// In ja, this message translates to:
  /// **'二郎系'**
  String get styleJiro;

  /// No description provided for @styleTsukemen.
  ///
  /// In ja, this message translates to:
  /// **'つけ麺'**
  String get styleTsukemen;

  /// No description provided for @styleOther.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get styleOther;

  /// No description provided for @isLimited.
  ///
  /// In ja, this message translates to:
  /// **'限定メニュー'**
  String get isLimited;

  /// No description provided for @hasTicket.
  ///
  /// In ja, this message translates to:
  /// **'整理券制'**
  String get hasTicket;

  /// No description provided for @hoursSection.
  ///
  /// In ja, this message translates to:
  /// **'店の営業時間'**
  String get hoursSection;

  /// No description provided for @hoursNormal.
  ///
  /// In ja, this message translates to:
  /// **'通常'**
  String get hoursNormal;

  /// No description provided for @hoursLunchOnly.
  ///
  /// In ja, this message translates to:
  /// **'昼のみ'**
  String get hoursLunchOnly;

  /// No description provided for @hoursFewDays.
  ///
  /// In ja, this message translates to:
  /// **'週3日以下'**
  String get hoursFewDays;

  /// No description provided for @memoLabel.
  ///
  /// In ja, this message translates to:
  /// **'メモ'**
  String get memoLabel;

  /// No description provided for @discardTitle.
  ///
  /// In ja, this message translates to:
  /// **'記録をやめますか？'**
  String get discardTitle;

  /// No description provided for @discardMessage.
  ///
  /// In ja, this message translates to:
  /// **'入力した内容は保存されません'**
  String get discardMessage;

  /// No description provided for @discardConfirm.
  ///
  /// In ja, this message translates to:
  /// **'やめる'**
  String get discardConfirm;

  /// No description provided for @discardCancel.
  ///
  /// In ja, this message translates to:
  /// **'続ける'**
  String get discardCancel;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In ja, this message translates to:
  /// **'編集'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In ja, this message translates to:
  /// **'この記録を削除しますか？'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In ja, this message translates to:
  /// **'写真も削除されます。元に戻せません'**
  String get deleteConfirmMessage;

  /// No description provided for @deleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'削除できませんでした'**
  String get deleteFailed;

  /// No description provided for @previousVisit.
  ///
  /// In ja, this message translates to:
  /// **'前回の記録'**
  String get previousVisit;

  /// No description provided for @visitNotFound.
  ///
  /// In ja, this message translates to:
  /// **'記録が見つかりません'**
  String get visitNotFound;

  /// No description provided for @editTitle.
  ///
  /// In ja, this message translates to:
  /// **'記録を編集'**
  String get editTitle;

  /// No description provided for @editSave.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get editSave;

  /// No description provided for @editSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存できませんでした。もう一度お試しください'**
  String get editSaveFailed;

  /// No description provided for @editShopName.
  ///
  /// In ja, this message translates to:
  /// **'店名'**
  String get editShopName;

  /// No description provided for @editEatenAt.
  ///
  /// In ja, this message translates to:
  /// **'食べた日時'**
  String get editEatenAt;

  /// No description provided for @limitedBadge.
  ///
  /// In ja, this message translates to:
  /// **'限定'**
  String get limitedBadge;

  /// No description provided for @ticketBadge.
  ///
  /// In ja, this message translates to:
  /// **'整理券'**
  String get ticketBadge;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
