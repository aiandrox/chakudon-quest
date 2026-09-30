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

  /// No description provided for @shopSearchPartial.
  ///
  /// In ja, this message translates to:
  /// **'店を検索できなかったため、記録済みの店だけを表示しています'**
  String get shopSearchPartial;

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

  /// No description provided for @ratingOptional.
  ///
  /// In ja, this message translates to:
  /// **'評価（食べ終わってから、あとで付けてもOK）'**
  String get ratingOptional;

  /// No description provided for @ratingUnrated.
  ///
  /// In ja, this message translates to:
  /// **'未評価'**
  String get ratingUnrated;

  /// No description provided for @ratingPrompt.
  ///
  /// In ja, this message translates to:
  /// **'{shop} はどうでしたか？'**
  String ratingPrompt(String shop);

  /// No description provided for @ratingTapToRate.
  ///
  /// In ja, this message translates to:
  /// **'★をタップして評価できます'**
  String get ratingTapToRate;

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
  /// **'営業の条件（当てはまるものすべて）'**
  String get hoursSection;

  /// No description provided for @hoursNote.
  ///
  /// In ja, this message translates to:
  /// **'ポイントの倍率: 1つで×1.5、2つ以上で×2'**
  String get hoursNote;

  /// No description provided for @hoursLunchOnly.
  ///
  /// In ja, this message translates to:
  /// **'昼のみ'**
  String get hoursLunchOnly;

  /// No description provided for @hoursNightOnly.
  ///
  /// In ja, this message translates to:
  /// **'夜のみ'**
  String get hoursNightOnly;

  /// No description provided for @hoursWeekdaysOnly.
  ///
  /// In ja, this message translates to:
  /// **'平日のみ'**
  String get hoursWeekdaysOnly;

  /// No description provided for @hoursWeekendsOnly.
  ///
  /// In ja, this message translates to:
  /// **'土日のみ'**
  String get hoursWeekendsOnly;

  /// No description provided for @hoursFewDays.
  ///
  /// In ja, this message translates to:
  /// **'週3日以下'**
  String get hoursFewDays;

  /// No description provided for @hoursIrregular.
  ///
  /// In ja, this message translates to:
  /// **'不定休'**
  String get hoursIrregular;

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

  /// No description provided for @checkinButton.
  ///
  /// In ja, this message translates to:
  /// **'並んだ'**
  String get checkinButton;

  /// No description provided for @checkinTitle.
  ///
  /// In ja, this message translates to:
  /// **'並んだ店を選ぶ'**
  String get checkinTitle;

  /// No description provided for @checkinDone.
  ///
  /// In ja, this message translates to:
  /// **'{shop} に並びました'**
  String checkinDone(String shop);

  /// No description provided for @checkinFailed.
  ///
  /// In ja, this message translates to:
  /// **'チェックインできませんでした。もう一度お試しください'**
  String get checkinFailed;

  /// No description provided for @checkinTooFar.
  ///
  /// In ja, this message translates to:
  /// **'100m以内に近づくとチェックインできます'**
  String get checkinTooFar;

  /// No description provided for @checkinNoLocation.
  ///
  /// In ja, this message translates to:
  /// **'現在地がわからないため、チェックインできません。位置情報をオンにして、もう一度お試しください'**
  String get checkinNoLocation;

  /// No description provided for @checkinSearchFailed.
  ///
  /// In ja, this message translates to:
  /// **'店を検索できませんでした。店名を入力してチェックインできます'**
  String get checkinSearchFailed;

  /// No description provided for @checkinNoCandidates.
  ///
  /// In ja, this message translates to:
  /// **'近くに候補が見つかりませんでした。店名を入力してチェックインできます'**
  String get checkinNoCandidates;

  /// No description provided for @checkinRetry.
  ///
  /// In ja, this message translates to:
  /// **'もう一度探す'**
  String get checkinRetry;

  /// No description provided for @checkinManualButton.
  ///
  /// In ja, this message translates to:
  /// **'この店名でチェックイン'**
  String get checkinManualButton;

  /// No description provided for @checkinBanner.
  ///
  /// In ja, this message translates to:
  /// **'{shop} に並び中'**
  String checkinBanner(String shop);

  /// No description provided for @checkinWaiting.
  ///
  /// In ja, this message translates to:
  /// **'並び始めてから {minutes}分'**
  String checkinWaiting(int minutes);

  /// No description provided for @checkinCancel.
  ///
  /// In ja, this message translates to:
  /// **'取り消す'**
  String get checkinCancel;

  /// No description provided for @checkinCancelTitle.
  ///
  /// In ja, this message translates to:
  /// **'チェックインを取り消しますか？'**
  String get checkinCancelTitle;

  /// No description provided for @checkinCancelMessage.
  ///
  /// In ja, this message translates to:
  /// **'並んだ記録は残りません'**
  String get checkinCancelMessage;

  /// No description provided for @checkinKeep.
  ///
  /// In ja, this message translates to:
  /// **'並び続ける'**
  String get checkinKeep;

  /// No description provided for @retreat.
  ///
  /// In ja, this message translates to:
  /// **'撤退'**
  String get retreat;

  /// No description provided for @retreatTitle.
  ///
  /// In ja, this message translates to:
  /// **'撤退を記録しますか？'**
  String get retreatTitle;

  /// No description provided for @retreatMessage.
  ///
  /// In ja, this message translates to:
  /// **'食べられなかった記録として残します。次に同じ店で食べると「再挑戦成功」になります'**
  String get retreatMessage;

  /// No description provided for @retreatReasonSoldOut.
  ///
  /// In ja, this message translates to:
  /// **'売り切れ'**
  String get retreatReasonSoldOut;

  /// No description provided for @retreatReasonClosed.
  ///
  /// In ja, this message translates to:
  /// **'臨時休業'**
  String get retreatReasonClosed;

  /// No description provided for @retreatReasonNoTime.
  ///
  /// In ja, this message translates to:
  /// **'時間切れ'**
  String get retreatReasonNoTime;

  /// No description provided for @retreatMemoLabel.
  ///
  /// In ja, this message translates to:
  /// **'メモ（任意）'**
  String get retreatMemoLabel;

  /// No description provided for @retreatConfirm.
  ///
  /// In ja, this message translates to:
  /// **'撤退を記録'**
  String get retreatConfirm;

  /// No description provided for @retreatSaved.
  ///
  /// In ja, this message translates to:
  /// **'撤退を記録しました。次こそ着丼！'**
  String get retreatSaved;

  /// No description provided for @retreatFailed.
  ///
  /// In ja, this message translates to:
  /// **'記録できませんでした。もう一度お試しください'**
  String get retreatFailed;

  /// No description provided for @retreatBadge.
  ///
  /// In ja, this message translates to:
  /// **'撤退'**
  String get retreatBadge;

  /// No description provided for @waitTime.
  ///
  /// In ja, this message translates to:
  /// **'待ち時間 {minutes}分'**
  String waitTime(int minutes);

  /// No description provided for @rankApprentice.
  ///
  /// In ja, this message translates to:
  /// **'見習い冒険者'**
  String get rankApprentice;

  /// No description provided for @rankTraveler.
  ///
  /// In ja, this message translates to:
  /// **'麺の旅人'**
  String get rankTraveler;

  /// No description provided for @rankHero.
  ///
  /// In ja, this message translates to:
  /// **'行列の勇者'**
  String get rankHero;

  /// No description provided for @rankLegend.
  ///
  /// In ja, this message translates to:
  /// **'伝説の麺道士'**
  String get rankLegend;

  /// No description provided for @points.
  ///
  /// In ja, this message translates to:
  /// **'{points} pt'**
  String points(int points);

  /// No description provided for @pointsGained.
  ///
  /// In ja, this message translates to:
  /// **'+{points} pt'**
  String pointsGained(int points);

  /// No description provided for @pointsSection.
  ///
  /// In ja, this message translates to:
  /// **'獲得ポイント'**
  String get pointsSection;

  /// No description provided for @pointsBase.
  ///
  /// In ja, this message translates to:
  /// **'基本'**
  String get pointsBase;

  /// No description provided for @pointsWait.
  ///
  /// In ja, this message translates to:
  /// **'待ち時間 {minutes}分'**
  String pointsWait(int minutes);

  /// No description provided for @pointsFirstVisit.
  ///
  /// In ja, this message translates to:
  /// **'初訪問'**
  String get pointsFirstVisit;

  /// No description provided for @pointsRetry.
  ///
  /// In ja, this message translates to:
  /// **'再挑戦成功'**
  String get pointsRetry;

  /// No description provided for @pointsHours.
  ///
  /// In ja, this message translates to:
  /// **'営業の条件（{label}）'**
  String pointsHours(String label);

  /// No description provided for @pointsMultiplier.
  ///
  /// In ja, this message translates to:
  /// **'×{multiplier}'**
  String pointsMultiplier(String multiplier);

  /// No description provided for @pointsRetreat.
  ///
  /// In ja, this message translates to:
  /// **'撤退の記録にポイントはつきません'**
  String get pointsRetreat;

  /// No description provided for @totalPoints.
  ///
  /// In ja, this message translates to:
  /// **'累計 {points} pt'**
  String totalPoints(int points);

  /// No description provided for @nextRank.
  ///
  /// In ja, this message translates to:
  /// **'「{rank}」まで あと {points} pt'**
  String nextRank(String rank, int points);

  /// No description provided for @maxRank.
  ///
  /// In ja, this message translates to:
  /// **'最高ランクに到達しました'**
  String get maxRank;

  /// No description provided for @rankUp.
  ///
  /// In ja, this message translates to:
  /// **'ランクアップ！'**
  String get rankUp;

  /// No description provided for @resultTitle.
  ///
  /// In ja, this message translates to:
  /// **'着丼！'**
  String get resultTitle;

  /// No description provided for @resultOk.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get resultOk;

  /// No description provided for @navRecords.
  ///
  /// In ja, this message translates to:
  /// **'記録'**
  String get navRecords;

  /// No description provided for @navQuests.
  ///
  /// In ja, this message translates to:
  /// **'クエスト'**
  String get navQuests;

  /// No description provided for @questTitle.
  ///
  /// In ja, this message translates to:
  /// **'クエスト'**
  String get questTitle;

  /// No description provided for @questSummary.
  ///
  /// In ja, this message translates to:
  /// **'達成 {achieved} / {total}'**
  String questSummary(int achieved, int total);

  /// No description provided for @questStatusAchieved.
  ///
  /// In ja, this message translates to:
  /// **'達成済み'**
  String get questStatusAchieved;

  /// No description provided for @questStatusInProgress.
  ///
  /// In ja, this message translates to:
  /// **'挑戦中'**
  String get questStatusInProgress;

  /// No description provided for @questStatusNotStarted.
  ///
  /// In ja, this message translates to:
  /// **'未達成'**
  String get questStatusNotStarted;

  /// No description provided for @questAchievedOn.
  ///
  /// In ja, this message translates to:
  /// **'{date} 達成'**
  String questAchievedOn(String date);

  /// No description provided for @questProgress.
  ///
  /// In ja, this message translates to:
  /// **'{current} / {target}'**
  String questProgress(int current, int target);

  /// No description provided for @questAchieved.
  ///
  /// In ja, this message translates to:
  /// **'クエスト達成！'**
  String get questAchieved;

  /// No description provided for @navStats.
  ///
  /// In ja, this message translates to:
  /// **'統計'**
  String get navStats;

  /// No description provided for @statsTitle.
  ///
  /// In ja, this message translates to:
  /// **'統計'**
  String get statsTitle;

  /// No description provided for @statsEmpty.
  ///
  /// In ja, this message translates to:
  /// **'記録が増えると、ここに統計が出ます'**
  String get statsEmpty;

  /// No description provided for @statsThisYear.
  ///
  /// In ja, this message translates to:
  /// **'今年の杯数'**
  String get statsThisYear;

  /// No description provided for @statsTotal.
  ///
  /// In ja, this message translates to:
  /// **'累計の杯数'**
  String get statsTotal;

  /// No description provided for @bowls.
  ///
  /// In ja, this message translates to:
  /// **'{count}杯'**
  String bowls(int count);

  /// No description provided for @statsStyles.
  ///
  /// In ja, this message translates to:
  /// **'系統の割合'**
  String get statsStyles;

  /// No description provided for @styleUnset.
  ///
  /// In ja, this message translates to:
  /// **'系統なし'**
  String get styleUnset;

  /// No description provided for @percent.
  ///
  /// In ja, this message translates to:
  /// **'{percent}%'**
  String percent(int percent);

  /// No description provided for @statsFrequent.
  ///
  /// In ja, this message translates to:
  /// **'よく行く店'**
  String get statsFrequent;

  /// No description provided for @shopMemoSection.
  ///
  /// In ja, this message translates to:
  /// **'この店の攻略メモ'**
  String get shopMemoSection;

  /// No description provided for @shopMemoEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだありません'**
  String get shopMemoEmpty;

  /// No description provided for @shopMemoHint.
  ///
  /// In ja, this message translates to:
  /// **'開店の何分前に着けばいいか、券売機、整理券の配り方など'**
  String get shopMemoHint;

  /// No description provided for @shopMemoEdit.
  ///
  /// In ja, this message translates to:
  /// **'攻略メモを書く'**
  String get shopMemoEdit;

  /// No description provided for @shopMemoInline.
  ///
  /// In ja, this message translates to:
  /// **'攻略メモ: {memo}'**
  String shopMemoInline(String memo);

  /// No description provided for @backupTitle.
  ///
  /// In ja, this message translates to:
  /// **'バックアップ'**
  String get backupTitle;

  /// No description provided for @backupDescription.
  ///
  /// In ja, this message translates to:
  /// **'記録と写真を1つのファイル（zip）にまとめて書き出します。機種変更のときは、新しいスマホでこのファイルを読み込んでください。'**
  String get backupDescription;

  /// No description provided for @backupExport.
  ///
  /// In ja, this message translates to:
  /// **'書き出す'**
  String get backupExport;

  /// No description provided for @backupExportNote.
  ///
  /// In ja, this message translates to:
  /// **'書き出したファイルは、「ファイル」アプリやクラウド、メールなどに保存してください'**
  String get backupExportNote;

  /// No description provided for @backupImport.
  ///
  /// In ja, this message translates to:
  /// **'読み込む'**
  String get backupImport;

  /// No description provided for @backupImportNote.
  ///
  /// In ja, this message translates to:
  /// **'書き出したファイルを選ぶと、このスマホに無い記録だけを足します。今ある記録は消えません'**
  String get backupImportNote;

  /// No description provided for @backupExportFailed.
  ///
  /// In ja, this message translates to:
  /// **'書き出せませんでした。もう一度お試しください'**
  String get backupExportFailed;

  /// No description provided for @backupImportDone.
  ///
  /// In ja, this message translates to:
  /// **'{added}件の記録を読み込みました（ファイルの記録 {total}件のうち、このスマホに無かったもの）'**
  String backupImportDone(int added, int total);

  /// No description provided for @backupImportInvalid.
  ///
  /// In ja, this message translates to:
  /// **'着丼クエストのバックアップとして読めないファイルです'**
  String get backupImportInvalid;

  /// No description provided for @backupImportFailed.
  ///
  /// In ja, this message translates to:
  /// **'読み込めませんでした。もう一度お試しください'**
  String get backupImportFailed;

  /// No description provided for @backupFileType.
  ///
  /// In ja, this message translates to:
  /// **'バックアップ（zip）'**
  String get backupFileType;

  /// No description provided for @statsBests.
  ///
  /// In ja, this message translates to:
  /// **'自己ベスト'**
  String get statsBests;

  /// No description provided for @bestLongestWait.
  ///
  /// In ja, this message translates to:
  /// **'最長の待ち時間'**
  String get bestLongestWait;

  /// No description provided for @bestHighestPoints.
  ///
  /// In ja, this message translates to:
  /// **'1杯の最高ポイント'**
  String get bestHighestPoints;

  /// No description provided for @bestMostRetreats.
  ///
  /// In ja, this message translates to:
  /// **'いちばん手ごわい店'**
  String get bestMostRetreats;

  /// No description provided for @minutes.
  ///
  /// In ja, this message translates to:
  /// **'{minutes}分'**
  String minutes(int minutes);

  /// No description provided for @retreatCount.
  ///
  /// In ja, this message translates to:
  /// **'撤退 {count}回'**
  String retreatCount(int count);

  /// No description provided for @bestDetail.
  ///
  /// In ja, this message translates to:
  /// **'{shop}（{date}）'**
  String bestDetail(String shop, String date);

  /// No description provided for @statsShopRanks.
  ///
  /// In ja, this message translates to:
  /// **'店ランク'**
  String get statsShopRanks;

  /// No description provided for @statsShopRanksNote.
  ///
  /// In ja, this message translates to:
  /// **'その店で1杯に得た最高ポイントで決まります（S 60以上 / A 40以上 / B 25以上）'**
  String get statsShopRanksNote;

  /// No description provided for @navMap.
  ///
  /// In ja, this message translates to:
  /// **'地図'**
  String get navMap;

  /// No description provided for @mapAttribution.
  ///
  /// In ja, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get mapAttribution;

  /// No description provided for @mapTitle.
  ///
  /// In ja, this message translates to:
  /// **'行った店の地図'**
  String get mapTitle;

  /// No description provided for @mapEmpty.
  ///
  /// In ja, this message translates to:
  /// **'位置のわかる店がまだありません。カメラで撮って、近くの店の候補から選ぶと地図に出ます'**
  String get mapEmpty;

  /// No description provided for @mapShopBowls.
  ///
  /// In ja, this message translates to:
  /// **'{count}杯'**
  String mapShopBowls(int count);

  /// No description provided for @mapShopRetreats.
  ///
  /// In ja, this message translates to:
  /// **'撤退 {count}回'**
  String mapShopRetreats(int count);

  /// No description provided for @mapLastVisit.
  ///
  /// In ja, this message translates to:
  /// **'最後に行った日 {date}'**
  String mapLastVisit(String date);

  /// No description provided for @mapShopRank.
  ///
  /// In ja, this message translates to:
  /// **'店ランク {rank}'**
  String mapShopRank(String rank);

  /// No description provided for @statsBestPoints.
  ///
  /// In ja, this message translates to:
  /// **'最高 {points} pt'**
  String statsBestPoints(int points);
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
