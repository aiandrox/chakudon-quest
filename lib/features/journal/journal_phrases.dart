import '../records/models.dart';

/// 道中記の言い回しの候補。{ } の中は、その1杯の数字や名前に置き換わる。
/// 候補の中から記録のIDで1つに決めるので、並びを変えると過去の道中記の文も変わる。空の文は「何も添えない」。
///
/// 一覧は `docs/journal/README.md`（`test/tool/journal_catalog_test.dart` で作る）。
class Phrases {
  const Phrases(this.when, this.lines);

  /// どんな1杯のときに使うか（一覧に出す説明）。
  final String when;
  final List<String> lines;

  List<String> fill([Map<String, Object> values = const {}]) => [
    for (final line in lines)
      line.replaceAllMapped(
        _placeholder,
        (m) => values.containsKey(m[1]) ? '${values[m[1]]}' : m[0]!,
      ),
  ];
}

final _placeholder = RegExp(r'\{([^{}]+)\}');

/// 一覧の見出しごとのまとまり（道中記の文の順）。
class PhraseSection {
  const PhraseSection(this.title, this.phrases, {this.note = ''});

  final String title;
  final String note;
  final List<Phrases> phrases;
}

// 書き出し

const wishOpening = Phrases('願を掛けた店で食べた（きっかけなし）', ['{日付}、願を掛けた店。']);
const wishOpeningWithTrigger = Phrases('願を掛けた店で食べた（きっかけあり）', [
  '{日付}、願を掛けた店。きっかけは「{きっかけ}」。',
]);
const firstRetreatOpening = Phrases('初めての店で、食べずに撤退', ['初めて挑む道場。', 'まだ見ぬ道場へ。']);
const firstVisitOpening = Phrases('初めての店', [
  'まだ見ぬ{軒}軒目の道場へ。',
  '{軒}軒目の道場の暖簾をくぐる。',
  '新たな道場、{軒}軒目。',
]);
const repeatOpening = Phrases('2度目以降の店', [
  '通うこと{度}度目。',
  '{度}度目の来訪。',
  'またこの暖簾をくぐる。{度}度目。',
  '勝手知ったる道場、{度}度目。',
]);

// 節目・間隔・特別な日

/// 通算の杯数の節目。
const milestoneBowls = {10, 30, 50, 100, 200, 300, 500, 1000};

const newYearsFirstMoment = Phrases('1月1日のその日最初の1杯', ['年明け最初の一杯。']);
const newYearsEveMoment = Phrases('12月31日', ['大晦日の一杯。']);
const firstOfYearMoment = Phrases('その年の最初の1杯（元日の最初の1杯と、初めての1杯は除く）', ['今年の初麺。']);
const milestoneMoment = Phrases('通算 10・30・50・100・200・300・500・1000 杯目', [
  '通算{杯}杯目の節目。',
]);
const sameDayMoment = Phrases('同じ日の2杯目以降', ['本日{杯}杯目。']);
const streakMoment = Phrases('3日以上続けて食べた', ['{日}日連続の麺修行。']);
const yearsApartMoment = Phrases('同じ店に1年以上ぶり', ['{年}年ぶりの再会。']);
const longGapMoment = Phrases('同じ店に90日以上ぶり', ['久しぶりの暖簾。']);
const regularMoment = Phrases('同じ店で5杯目', ['常連の域に入った。']);
const secondHomeMoment = Phrases('同じ店で10杯目', ['十度目。もはや第二の我が家。']);

// 時間帯・曜日・季節

const sceneHour6 = Phrases('6時台', ['明け六つ、朝一番の一杯。', '朝の澄んだ空気の中、朝ラーの暖簾へ。']);
const sceneHour18 = Phrases('18時台', ['暮れ六つの鐘とともに。', '一日の終わりに、夜の暖簾へ。']);
const sceneHour2 = Phrases('2時台', ['丑三つ時の一杯。', '真夜中の一杯は、背徳の味。']);
const sceneMorning = Phrases('5〜10時台（6時台を除く）', [
  '朝の澄んだ空気の中、朝ラーの暖簾へ。',
  '一日の始まりは一杯から。',
]);
const sceneNoon = Phrases('11〜14時台', ['昼どきの喧騒をくぐり抜けて。', '腹の虫が鳴る昼下がり。']);
const sceneAfternoon = Phrases('15〜17時台', ['中休み前のすき間を狙って。', '夕暮れ前のひと休み。']);
const sceneEvening = Phrases('19〜22時台', ['一日の終わりに、夜の暖簾へ。', '夜風に誘われて。']);
const sceneNight = Phrases('23〜4時台（2時台を除く）', ['真夜中の一杯は、背徳の味。', '眠らない街の灯りの下で。']);
const sceneWeekend = Phrases('土日', ['休日の気ままな一杯。']);
const sceneFridayNight = Phrases('金曜の18時以降', ['花金の一杯。']);
const sceneMonday = Phrases('月曜', ['週の始まりに気合を入れる。']);
const sceneWinter = Phrases('12〜2月', ['冷えた体に湯気がしみる。']);
const sceneSummer = Phrases('6〜8月', ['汗をぬぐいながらすする。']);
const sceneSpring = Phrases('3〜5月', ['春の陽気に誘われて。']);
const sceneAutumn = Phrases('9〜11月', ['秋の夜長にもう一杯。']);

/// 時間帯・曜日・季節の候補に足す、何も添えない分。
const sceneSkip = Phrases('（何も添えない分）', ['', '']);

// 地名

const nearArea = Phrases('いつもの店から20km未満', [
  '{地名}の街で。',
  '{地名}の空の下で。',
  '{地名}にて。',
  '{地名}の町角で。',
  'ふらりと{地名}へ。',
  '{地名}の路地をゆく。',
  '',
]);
const farArea = Phrases('いつもの店から20km以上80km未満', [
  '遠く{地名}まで足をのばして。',
  'はるばる{地名}へ。',
  '少し遠出して{地名}へ。',
  '今日は{地名}まで遠出。',
  '{地名}まで、ひと足のばして。',
  '見知らぬ{地名}の街で。',
]);
const expeditionArea = Phrases('いつもの店から80km以上（遠征）', [
  '今日は{地名}まで遠征。',
  '遠征の地、{地名}。',
  'はるばる{地名}まで遠征。',
  '旅の空の下、{地名}にて。',
  '{地名}へ、修行の旅。',
  '旅先の{地名}で一杯。',
]);

// 撤退

/// 撤退のメモが無いか長いときの、撤退の理由。
const unknownReason = '思わぬ壁';

const retreatedOnceBefore = Phrases('前回この店で撤退した', ['前回は{理由}に阻まれ、撤退した。']);
const retreatedManyBefore = Phrases('この店で続けて2回以上撤退した', ['{回}度の撤退を越えて、ここまで来た。']);
const retreatWaited = Phrases('並んでから撤退した', ['{分}分並んだが、']);
const retreatBlocked = Phrases('撤退した', ['{理由}に阻まれ、撤退。']);
const retreatClosing = Phrases('撤退した（締め）', ['次こそは。', 'この借りは、必ず返す。']);

// 行列

const longWait = Phrases('60分以上並んだ', ['{分}分の長い行列を耐え抜き、', '並ぶこと{分}分。足が棒になっても、']);
const shortWait = Phrases('1〜59分並んだ', ['行列に並ぶこと{分}分、', '{分}分の行列を越え、']);

// 系統

const flavors = <RamenStyle, Phrases>{
  RamenStyle.shoyu: Phrases('醤油', ['澄んだ醤油の香りが立つ。', '黄金色のスープに顔が映る。', '']),
  RamenStyle.miso: Phrases('味噌', ['濃厚な湯気に包まれる。', '味噌の香りが鼻をくすぐる。', '']),
  RamenStyle.shio: Phrases('塩', ['透きとおるスープをひと口。', '塩の一杯は、ごまかしがきかない。', '']),
  RamenStyle.tonkotsu: Phrases('豚骨', ['白濁のスープが香り立つ。', '替え玉の誘惑と戦う。', '']),
  RamenStyle.iekei: Phrases('家系', ['海苔をスープに浸して。', '「お好みは？」に「硬め濃いめ多め」。', '']),
  RamenStyle.jiro: Phrases('二郎', ['「ニンニク入れますか？」に静かに頷く。', '野菜の山を崩しにかかる。', '']),
  RamenStyle.tsukemen: Phrases('つけ麺', ['麺をつけ汁にくぐらせて。', '最後はスープ割りで締める。', '']),
  RamenStyle.shirunashi: Phrases('汁なし', ['底からよく混ぜて。', '追い飯まで抜かりなく。', '']),
};

// 着丼

const dramaticBowl = Phrases('願の店・撤退のあと・60分以上並んだ', ['ついに着丼。{一杯}、修行点 {点}。']);
const bowl = Phrases('そのほか', [
  '着丼。{一杯}、修行点 {点}。',
  '丼が置かれた。{一杯}、修行点 {点}。',
  '湯気の向こうに{一杯}、修行点 {点}。',
  '待望の{一杯}、修行点 {点}。',
]);

// 記録の更新（当てはまるうち最初の1つ）

const bestPointsRecord = Phrases('自己最高の修行点', ['自己最高の修行点を更新。']);
const shopRankSRecord = Phrases('この店で初めて修行点60以上（印が極に）', ['この道場の印は「極」に。']);
const longestWaitRecord = Phrases('この店でいちばん長く並んだ', ['この店で最長の待ち。']);

// ★

const verdicts = <int, Phrases>{
  5: Phrases('★5', [
    '文句なしの一杯。また必ず来る。',
    'これぞ求めていた味。',
    '箸が止まらなかった。',
    'スープまで一滴残らず。',
  ]),
  4: Phrases('★4', ['満足の一杯。', 'いい道場に出会えた。', 'また来たいと思える味。']),
  3: Phrases('★3', ['悪くない。', '可もなく不可もなく、それもまた修行。', 'いつもの安心する味。']),
  2: Phrases('★2', ['今日はあと一歩。', '好みとは少し違った。']),
  1: Phrases('★1', ['これもまた修行。', '合わない味を知るのも道のうち。']),
};

const memoQuote = Phrases('メモが20文字以内で1行（共有カードでは出さない）', ['――「{メモ}」と書き残す。']);

// 締め

const wishSameDayClosing = Phrases('願を掛けたその日に食べた', ['願を掛けたその日に、願成就。']);
const wishClosing = Phrases('願を掛けた店で食べた', ['{日}日越しの願成就。']);
const retryClosing = Phrases('撤退のあと、同じ店で食べた', ['再挑戦、成功。']);
const yearClosing = Phrases('そのほか', [
  '今年 {杯}杯目。',
  '今年 {杯}杯目の修行。',
  '修行は続く。今年 {杯}杯目。',
  '麺道、今年 {杯}杯目。',
]);

final journalCatalog = <PhraseSection>[
  PhraseSection('書き出し', [
    wishOpening,
    wishOpeningWithTrigger,
    firstRetreatOpening,
    firstVisitOpening,
    repeatOpening,
  ]),
  PhraseSection('節目・間隔・特別な日', [
    newYearsFirstMoment,
    newYearsEveMoment,
    firstOfYearMoment,
    milestoneMoment,
    sameDayMoment,
    streakMoment,
    yearsApartMoment,
    longGapMoment,
    regularMoment,
    secondHomeMoment,
  ], note: '食べた1杯だけ。当てはまるものを上から2つまで'),
  PhraseSection('時間帯・曜日・季節', [
    sceneHour6,
    sceneHour18,
    sceneHour2,
    sceneMorning,
    sceneNoon,
    sceneAfternoon,
    sceneEvening,
    sceneNight,
    sceneWeekend,
    sceneFridayNight,
    sceneMonday,
    sceneWinter,
    sceneSummer,
    sceneSpring,
    sceneAutumn,
    sceneSkip,
  ], note: '願の店でも撤退のあとでもない1杯。当てはまる時間帯・曜日・季節の候補をまとめた中から1つ（何も添えないこともある）'),
  PhraseSection('地名', [
    nearArea,
    farArea,
    expeditionArea,
  ], note: '店の市区町村がわかるとき。いつもの店＝その1杯までにいちばん多く食べた店'),
  PhraseSection('撤退', [
    retreatedOnceBefore,
    retreatedManyBefore,
    retreatWaited,
    retreatBlocked,
    retreatClosing,
  ], note: '{理由}は撤退のメモ（10文字以内）。無いか長いときは「$unknownReason」'),
  PhraseSection('行列', [longWait, shortWait]),
  PhraseSection('系統', [...flavors.values], note: '系統を選んだ1杯。何も添えないこともある'),
  PhraseSection(
    '着丼',
    [dramaticBowl, bowl],
    note:
        '{一杯}は「限定の」＋系統名＋「の一杯」（系統なしは「ラーメンの一杯」）。共有カードで修行点を外すため「、修行点 {点}」の形は崩さない',
  ),
  PhraseSection('記録の更新', [
    bestPointsRecord,
    shopRankSRecord,
    longestWaitRecord,
  ], note: '当てはまるもののうち最初の1つ'),
  PhraseSection('★', [...verdicts.values], note: '★を付けた1杯'),
  PhraseSection('メモ', [memoQuote]),
  PhraseSection('締め', [
    wishSameDayClosing,
    wishClosing,
    retryClosing,
    yearClosing,
  ]),
];
