import '../records/models.dart';

const backupFormat = 'chakudon-quest-backup';
const backupVersion = 1;

/// 書き出す・読み込む記録ひとそろい。写真のファイルは別に扱う。
class BackupData {
  const BackupData({required this.shops, required this.visits});

  final List<Shop> shops;
  final List<Visit> visits;
}

Map<String, Object?> encodeBackup(
  BackupData data, {
  required DateTime exportedAt,
}) => {
  'format': backupFormat,
  'version': backupVersion,
  'exportedAt': exportedAt.toUtc().toIso8601String(),
  'shops': [
    for (final shop in data.shops)
      {
        'id': shop.id,
        'name': shop.name,
        'latitude': shop.latitude,
        'longitude': shop.longitude,
        'osmId': shop.osmId,
        'hoursConditions': [
          for (final condition in HoursCondition.values)
            if (shop.hoursConditions.contains(condition)) condition.name,
        ],
        'strategyMemo': shop.strategyMemo,
        'createdAt': shop.createdAt.toUtc().toIso8601String(),
      },
  ],
  'visits': [
    for (final visit in data.visits)
      {
        'id': visit.id,
        'shopId': visit.shopId,
        'result': visit.result.name,
        'photoPath': visit.photoPath,
        'checkedInAt': visit.checkedInAt?.toUtc().toIso8601String(),
        'eatenAt': visit.eatenAt.toUtc().toIso8601String(),
        'style': visit.style?.name,
        'rating': visit.rating,
        'isLimited': visit.isLimited,
        'hasTicket': visit.hasTicket,
        'memo': visit.memo,
        'createdAt': visit.createdAt.toUtc().toIso8601String(),
      },
  ],
};

/// このアプリのバックアップでない・壊れているときは[FormatException]にする。
BackupData decodeBackup(Object? json) {
  final root = _map(json, 'バックアップ');
  if (root['format'] != backupFormat) {
    throw const FormatException('着丼クエストのバックアップではありません');
  }
  final version = root['version'];
  if (version is! int || version > backupVersion) {
    throw const FormatException('新しい版のアプリで作ったバックアップです');
  }
  return BackupData(
    shops: [for (final shop in _list(root['shops'])) _decodeShop(shop)],
    visits: [for (final visit in _list(root['visits'])) _decodeVisit(visit)],
  );
}

Shop _decodeShop(Object? json) {
  final map = _map(json, '店');
  final byName = HoursCondition.values.asNameMap();
  return Shop(
    id: _string(map['id']),
    name: _string(map['name']),
    latitude: _doubleOrNull(map['latitude']),
    longitude: _doubleOrNull(map['longitude']),
    osmId: _stringOrNull(map['osmId']),
    hoursConditions: {
      for (final name in _list(map['hoursConditions'] ?? const []))
        ?byName[name],
    },
    strategyMemo: _stringOrNull(map['strategyMemo']) ?? '',
    createdAt: _dateTime(map['createdAt']),
  );
}

Visit _decodeVisit(Object? json) {
  final map = _map(json, '記録');
  final result = VisitResult.values.asNameMap()[map['result']];
  if (result == null) throw const FormatException('記録の結果が読めません');
  final rating = map['rating'];
  return Visit(
    id: _string(map['id']),
    shopId: _string(map['shopId']),
    result: result,
    photoPath: _stringOrNull(map['photoPath']),
    checkedInAt: map['checkedInAt'] == null
        ? null
        : _dateTime(map['checkedInAt']),
    eatenAt: _dateTime(map['eatenAt']),
    style: RamenStyle.values.asNameMap()[map['style']],
    rating: rating is int && rating >= 1 && rating <= 5 ? rating : null,
    isLimited: map['isLimited'] == true,
    hasTicket: map['hasTicket'] == true,
    memo: _stringOrNull(map['memo']) ?? '',
    createdAt: _dateTime(map['createdAt']),
  );
}

Map<String, Object?> _map(Object? json, String what) {
  if (json is Map<String, Object?>) return json;
  throw FormatException('$whatの形式が読めません');
}

List<Object?> _list(Object? json) {
  if (json is List<Object?>) return json;
  throw const FormatException('一覧の形式が読めません');
}

String _string(Object? json) {
  if (json is String && json.isNotEmpty) return json;
  throw const FormatException('文字列が読めません');
}

String? _stringOrNull(Object? json) {
  if (json == null || json is String) return json as String?;
  throw const FormatException('文字列が読めません');
}

double? _doubleOrNull(Object? json) => json is num ? json.toDouble() : null;

DateTime _dateTime(Object? json) {
  final value = json is String ? DateTime.tryParse(json) : null;
  if (value == null) throw const FormatException('日時が読めません');
  // 書き出しはUTC。機種変更先のタイムゾーンで、その土地の時刻に直す。
  return value.toLocal();
}
