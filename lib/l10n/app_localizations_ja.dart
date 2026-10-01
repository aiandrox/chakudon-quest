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
  String get shopSearchPartial => '店を検索できなかったため、記録済みの店だけを表示しています';

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
  String get ratingOptional => '評価（食べ終わってから、あとで付けてもOK）';

  @override
  String get ratingUnrated => '未評価';

  @override
  String ratingPrompt(String shop) {
    return '$shop はどうでしたか？';
  }

  @override
  String get ratingTapToRate => '★をタップして評価できます';

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
  String get styleShirunashi => '汁なし';

  @override
  String get styleOther => 'その他';

  @override
  String get isLimited => '限定メニュー';

  @override
  String get hoursSection => '攻略しにくさ（当てはまるものすべて）';

  @override
  String get hoursNote => '当てはまるものが多いほど、修行点の倍率が上がります（最大×2.5）';

  @override
  String get hoursLunchOnly => '昼のみ';

  @override
  String get hoursNightOnly => '夜のみ';

  @override
  String get hoursWeekdaysOnly => '平日のみ';

  @override
  String get hoursWeekendsOnly => '土日のみ';

  @override
  String get hoursFewDays => '週3日以下';

  @override
  String get hoursIrregular => '不定休';

  @override
  String get hoursBadAccess => 'アクセスが悪い';

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

  @override
  String get cancel => 'キャンセル';

  @override
  String get edit => '編集';

  @override
  String get delete => '削除';

  @override
  String get deleteConfirmTitle => 'この記録を削除しますか？';

  @override
  String get deleteConfirmMessage => '写真も削除されます。元に戻せません';

  @override
  String get deleteFailed => '削除できませんでした';

  @override
  String get previousVisit => '前回の記録';

  @override
  String get visitNotFound => '記録が見つかりません';

  @override
  String get editTitle => '記録を編集';

  @override
  String get editSave => '保存';

  @override
  String get editSaveFailed => '保存できませんでした。もう一度お試しください';

  @override
  String get editShopName => '店名';

  @override
  String get editEatenAt => '食べた日時';

  @override
  String get limitedBadge => '限定';

  @override
  String get checkinButton => '並んだ';

  @override
  String get checkinTitle => '並んだ店を選ぶ';

  @override
  String checkinDone(String shop) {
    return '$shop に並びました';
  }

  @override
  String get checkinFailed => 'チェックインできませんでした。もう一度お試しください';

  @override
  String get checkinTooFar => '100m以内に近づくとチェックインできます';

  @override
  String get checkinNoLocation =>
      '現在地がわからないため、チェックインできません。位置情報をオンにして、もう一度お試しください';

  @override
  String get checkinSearchFailed => '店を検索できませんでした。店名を入力してチェックインできます';

  @override
  String get checkinNoCandidates => '近くに候補が見つかりませんでした。店名を入力してチェックインできます';

  @override
  String get checkinRetry => 'もう一度探す';

  @override
  String get checkinManualButton => 'この店名でチェックイン';

  @override
  String checkinBanner(String shop) {
    return '$shop に並び中';
  }

  @override
  String checkinWaiting(int minutes) {
    return '並び始めてから $minutes分';
  }

  @override
  String checkinNotificationBody(String time) {
    return '$time から並んでいます。着丼したら「＋」で記録しましょう';
  }

  @override
  String streakWeeks(int weeks) {
    return '$weeks週連続で着丼中';
  }

  @override
  String get streakAtRisk => '今週はまだ';

  @override
  String streakReminderTitle(int weeks) {
    return '$weeks週連続の記録が途切れそう';
  }

  @override
  String get streakReminderBody => '今週はまだ着丼していません。日曜が終わるまでに一杯いかがですか？';

  @override
  String get checkinCancel => '取り消す';

  @override
  String get checkinCancelTitle => 'チェックインを取り消しますか？';

  @override
  String get checkinCancelMessage => '並んだ記録は残りません';

  @override
  String get checkinKeep => '並び続ける';

  @override
  String get retreat => '撤退';

  @override
  String get retreatTitle => '撤退を記録しますか？';

  @override
  String get retreatMessage => '食べられなかった記録として残します。次に同じ店で食べると「再挑戦成功」になります';

  @override
  String get retreatReasonSoldOut => '売り切れ';

  @override
  String get retreatReasonClosed => '臨時休業';

  @override
  String get retreatReasonNoTime => '時間切れ';

  @override
  String get retreatMemoLabel => 'メモ（任意）';

  @override
  String get retreatConfirm => '撤退を記録';

  @override
  String get retreatSaved => '撤退を記録しました。次こそ着丼！';

  @override
  String get retreatFailed => '記録できませんでした。もう一度お試しください';

  @override
  String get retreatBadge => '撤退';

  @override
  String waitTime(int minutes) {
    return '待ち時間 $minutes分';
  }

  @override
  String get rankApprentice => '入門';

  @override
  String get rankTraveler => '初段';

  @override
  String get rankHero => '師範代';

  @override
  String get rankLegend => '免許皆伝';

  @override
  String points(int points) {
    return '$points点';
  }

  @override
  String pointsGained(int points) {
    return '+$points点';
  }

  @override
  String get pointsSection => '修行点';

  @override
  String get pointsBase => '基本';

  @override
  String pointsWait(int minutes) {
    return '待ち時間 $minutes分';
  }

  @override
  String get pointsFirstVisit => '初訪問';

  @override
  String get pointsRetry => '再挑戦成功';

  @override
  String pointsHours(String label) {
    return '攻略しにくさ（$label）';
  }

  @override
  String pointsMultiplier(String multiplier) {
    return '×$multiplier';
  }

  @override
  String get pointsRetreat => '撤退の記録に修行点はつきません';

  @override
  String totalPoints(int points) {
    return '修行点 $points';
  }

  @override
  String nextRank(String rank, int points) {
    return '$rankまで あと $points点';
  }

  @override
  String get maxRank => '免許皆伝に至りました';

  @override
  String get rankUp => '昇段！';

  @override
  String get resultTitle => '着丼！';

  @override
  String get resultOk => '印帳にもどる';

  @override
  String get navRecords => '印帳';

  @override
  String get navQuests => 'クエスト';

  @override
  String get questTitle => 'クエスト';

  @override
  String get questStanding => '常設クエスト';

  @override
  String get questStandingNote => '回数を重ねるほどレベルが上がります';

  @override
  String get questSpot => 'スポットクエスト';

  @override
  String get questSpotNote => '1回達成すればクリアです';

  @override
  String questLevelTotal(int total) {
    return 'レベル合計 $total';
  }

  @override
  String questSpotSummary(int achieved, int total) {
    return '達成 $achieved / $total';
  }

  @override
  String questLevel(int level) {
    return 'Lv.$level';
  }

  @override
  String get questMaxLevel => 'MAX';

  @override
  String get questCleared => '達成';

  @override
  String questNext(int current, int target, String unit) {
    return '次のレベルまで $current / $target$unit';
  }

  @override
  String questCount(int count, String unit) {
    return '$count$unit';
  }

  @override
  String questAchievedOn(String date) {
    return '$date 達成';
  }

  @override
  String get questLevelUp => 'クエスト レベルアップ！';

  @override
  String questLevelReached(String title, int level) {
    return '$title Lv.$level';
  }

  @override
  String get questAchieved => 'クエスト達成！';

  @override
  String get navStats => '統計';

  @override
  String get statsTitle => '統計';

  @override
  String get statsEmpty => '記録が増えると、ここに統計が出ます';

  @override
  String get statsThisYear => '今年の杯数';

  @override
  String get statsTotal => '累計の杯数';

  @override
  String bowls(int count) {
    return '$count杯';
  }

  @override
  String get statsStyles => '系統の割合';

  @override
  String get styleUnset => '系統なし';

  @override
  String percent(int percent) {
    return '$percent%';
  }

  @override
  String get statsFrequent => 'よく行く店';

  @override
  String get shopMemoSection => 'この店の攻略メモ';

  @override
  String get shopMemoEmpty => 'まだありません';

  @override
  String get shopMemoHint => '開店の何分前に着けばいいか、券売機、整理券の配り方など';

  @override
  String get shopMemoEdit => '攻略メモを書く';

  @override
  String shopMemoInline(String memo) {
    return '攻略メモ: $memo';
  }

  @override
  String get backupTitle => 'バックアップ';

  @override
  String get backupDescription =>
      '記録と写真を1つのファイル（zip）にまとめて書き出します。機種変更のときは、新しいスマホでこのファイルを読み込んでください。';

  @override
  String get backupExport => '書き出す';

  @override
  String get backupExportNote => '書き出したファイルは、「ファイル」アプリやクラウド、メールなどに保存してください';

  @override
  String get backupImport => '読み込む';

  @override
  String get backupImportNote => '書き出したファイルを選ぶと、このスマホに無い記録だけを足します。今ある記録は消えません';

  @override
  String get backupExportFailed => '書き出せませんでした。もう一度お試しください';

  @override
  String backupImportDone(int added, int total) {
    return '$added件の記録を読み込みました（ファイルの記録 $total件のうち、このスマホに無かったもの）';
  }

  @override
  String get backupImportInvalid => '着丼クエストのバックアップとして読めないファイルです';

  @override
  String get backupImportFailed => '読み込めませんでした。もう一度お試しください';

  @override
  String get backupFileType => 'バックアップ（zip）';

  @override
  String get statsBests => '自己ベスト';

  @override
  String get bestLongestWait => '最長の待ち時間';

  @override
  String get bestHighestPoints => '1杯の最高の修行点';

  @override
  String get bestMostRetreats => 'いちばん手ごわい店';

  @override
  String minutes(int minutes) {
    return '$minutes分';
  }

  @override
  String retreatCount(int count) {
    return '撤退 $count回';
  }

  @override
  String bestDetail(String shop, String date) {
    return '$shop（$date）';
  }

  @override
  String get statsShopRanks => '店ランク';

  @override
  String get statsShopRanksNote =>
      'その店で1杯に得た最高の修行点で決まります（極 60以上 / 特 40以上 / 上 25以上 / 並）';

  @override
  String get navMap => '地図';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get mapTitle => 'ラーメン地図';

  @override
  String get mapEmpty => '行った店はまだ地図にありません。「このあたりのラーメン店を探す」で、まわりの店を探せます';

  @override
  String get mapSearchHere => 'このあたりのラーメン店を探す';

  @override
  String get mapMyLocation => '現在地';

  @override
  String get mapNoLocation => '現在地がわかりませんでした。位置情報をオンにしてください';

  @override
  String mapNearbyFound(int count) {
    return 'まだ行っていない店が $count軒 見つかりました';
  }

  @override
  String get mapNearbyNone => 'このあたりに、まだ行っていないラーメン店は見つかりませんでした';

  @override
  String get mapSearchFailed => '店を検索できませんでした。少し待ってから、もう一度お試しください';

  @override
  String get mapUnvisited => 'まだ行っていない店';

  @override
  String mapDistanceFromHere(int meters) {
    return '現在地から ${meters}m';
  }

  @override
  String mapShopBowls(int count) {
    return '$count杯';
  }

  @override
  String mapShopRetreats(int count) {
    return '撤退 $count回';
  }

  @override
  String mapLastVisit(String date) {
    return '最後に行った日 $date';
  }

  @override
  String mapShopRank(String rank) {
    return '店ランク $rank';
  }

  @override
  String statsBestPoints(int points) {
    return '最高 $points点';
  }

  @override
  String get shopRankS => '極';

  @override
  String get shopRankA => '特';

  @override
  String get shopRankB => '上';

  @override
  String get shopRankC => '並';

  @override
  String get inkanEaten => '一本';

  @override
  String get inkanRetry => '雪辱';

  @override
  String get inkanRetreat => '敗';

  @override
  String inkanTop(String rank, String kind) {
    return '$rank　$kind';
  }

  @override
  String get inkanStyleShoyu => '醤';

  @override
  String get inkanStyleMiso => '味';

  @override
  String get inkanStyleShio => '塩';

  @override
  String get inkanStyleTonkotsu => '豚';

  @override
  String get inkanStyleIekei => '家';

  @override
  String get inkanStyleJiro => '郎';

  @override
  String get inkanStyleTsukemen => '沾';

  @override
  String get inkanStyleShirunashi => '混';

  @override
  String get inkanStyleOther => '麺';

  @override
  String kanjiMonthDay(String month, String day) {
    return '$month月$day日';
  }

  @override
  String get inchoTitle => '印帳';

  @override
  String inchoCount(int stamps, int shops) {
    return '集めた印 $stamps　道場 $shops';
  }

  @override
  String inchoMetaWait(int minutes) {
    return '待 $minutes分';
  }

  @override
  String get inchoMetaUnrated => '★ まだ';

  @override
  String get shopStamps => 'この道場の印';

  @override
  String get resultStamped => '印をいただきました';

  @override
  String recordPhotoDate(String date) {
    return '食べた日時: $date（写真の撮影日時）';
  }

  @override
  String kanjiEraDate(String era, String year, String month, String day) {
    return '$era$year年$month月$day日';
  }

  @override
  String get eraReiwa => '令和';

  @override
  String get eraHeisei => '平成';

  @override
  String get eraFirstYear => '元';
}
