import '../records/models.dart';

/// OpenStreetMap の営業時間（`opening_hours`）から、店の攻略しにくさを推し量る。
/// 「Mo-Fr 11:00-15:00; Sa off」のような、曜日と時間だけの書き方に限る。
/// 読めない書き方（月・祝日の扱い・注記など）ならnull。不定休は営業時間からはわからないので出さない。
Set<HoursCondition>? conditionsFromOpeningHours(String? openingHours) {
  final text = openingHours?.trim();
  if (text == null || text.isEmpty) return null;
  if (text == '24/7') return const {};
  final ranges = <int, List<(int, int)>>{};
  for (final rule in text.split(';')) {
    final trimmed = rule.trim();
    if (trimmed.isEmpty) continue;
    final parsed = _parseRule(trimmed);
    if (parsed == null) return null;
    final (days, times) = parsed;
    // 後に書いた決まりが、同じ曜日の前の決まりを上書きする。
    for (final day in days) {
      ranges[day] = times;
    }
  }
  final open = {
    for (final MapEntry(key: day, value: times) in ranges.entries)
      if (times.isNotEmpty) day,
  };
  if (open.isEmpty) return null;
  final all = [for (final day in open) ...ranges[day]!];
  return {
    if (all.every((r) => r.$2 <= _lunchEnd)) HoursCondition.lunchOnly,
    if (all.every((r) => r.$1 >= _nightStart)) HoursCondition.nightOnly,
    if (open.every((d) => d <= DateTime.friday)) HoursCondition.weekdaysOnly,
    if (open.every((d) => d >= DateTime.saturday)) HoursCondition.weekendsOnly,
    if (open.length <= 3) HoursCondition.fewDays,
  };
}

/// 昼のみ：すべての営業が16時までに終わる。夜のみ：すべての営業が17時以降に始まる。
const _lunchEnd = 16 * 60;
const _nightStart = 17 * 60;

const _dayNames = {
  'Mo': DateTime.monday,
  'Tu': DateTime.tuesday,
  'We': DateTime.wednesday,
  'Th': DateTime.thursday,
  'Fr': DateTime.friday,
  'Sa': DateTime.saturday,
  'Su': DateTime.sunday,
};

final _rulePattern = RegExp(r'^(?:([A-Za-z,\- ]+?)\s+)?(.+)$');
final _timePattern = RegExp(r'^(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})$');

(Set<int>, List<(int, int)>)? _parseRule(String rule) {
  // 曜日だけ・時間だけの決まりもある（「Su off」「11:00-14:00」）。
  final match = _rulePattern.firstMatch(rule);
  if (match == null) return null;
  var daysText = match[1];
  var timesText = match[2]!.trim();
  if (daysText == null && _looksLikeDays(timesText)) return null;
  final days = daysText == null ? {..._dayNames.values} : _parseDays(daysText);
  if (days == null) return null;
  if (timesText == 'off' || timesText == 'closed') return (days, const []);
  final times = <(int, int)>[];
  for (final part in timesText.split(',')) {
    final time = _timePattern.firstMatch(part.trim());
    if (time == null) return null;
    final start = int.parse(time[1]!) * 60 + int.parse(time[2]!);
    var end = int.parse(time[3]!) * 60 + int.parse(time[4]!);
    // 日をまたぐ営業（18:00-02:00）は、終わりを翌日の時刻として扱う。
    if (end <= start) end += 24 * 60;
    times.add((start, end));
  }
  return (days, times);
}

bool _looksLikeDays(String text) =>
    _dayNames.keys.any((name) => text.startsWith(name));

/// 祝日（PH）は曜日に数えず、読み飛ばす。
Set<int>? _parseDays(String text) {
  final days = <int>{};
  for (final part in text.split(',')) {
    if (part.trim() == 'PH') continue;
    final bounds = part.trim().split('-');
    if (bounds.length > 2) return null;
    final from = _dayNames[bounds.first.trim()];
    final to = _dayNames[bounds.last.trim()];
    if (from == null || to == null) return null;
    // 「Fr-Mo」のように週をまたぐ書き方もある。
    for (var day = from; ; day = day % 7 + 1) {
      days.add(day);
      if (day == to) break;
    }
  }
  return days;
}
