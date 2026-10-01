import 'dart:io';

import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shop_search/geo.dart';

final photoMetadataReaderProvider = Provider<PhotoMetadataReader>(
  (ref) => const ExifPhotoMetadataReader(),
);

/// 写真に記録されている撮影日時と撮影場所。無いものはnull。
class PhotoMetadata {
  const PhotoMetadata({this.takenAt, this.location});

  static const empty = PhotoMetadata();

  final DateTime? takenAt;
  final GeoPoint? location;
}

abstract class PhotoMetadataReader {
  /// 読めないときは[PhotoMetadata.empty]を返す（例外にしない）。
  Future<PhotoMetadata> read(String path);
}

class ExifPhotoMetadataReader implements PhotoMetadataReader {
  const ExifPhotoMetadataReader();

  @override
  Future<PhotoMetadata> read(String path) async {
    try {
      final tags = await readExifFromBytes(await File(path).readAsBytes());
      return photoMetadataFromExif({
        for (final MapEntry(:key, :value) in tags.entries)
          key: value.values is IfdRatios
              ? [for (final Ratio r in value.values.toList()) r.toDouble()]
              : value.printable,
      });
    } catch (e) {
      debugPrint('Photo metadata read failed: $e');
      return PhotoMetadata.empty;
    }
  }
}

/// EXIFのタグ（文字列、または分数を小数にした一覧）から撮影日時と場所を取り出す。
PhotoMetadata photoMetadataFromExif(Map<String, Object> tags) {
  final takenAt =
      parseExifDateTime(
        tags['EXIF DateTimeOriginal'],
        offset: tags['EXIF OffsetTimeOriginal'],
      ) ??
      parseExifDateTime(
        tags['EXIF DateTimeDigitized'],
        offset: tags['EXIF OffsetTimeDigitized'],
      ) ??
      parseExifDateTime(
        tags['Image DateTime'],
        offset: tags['EXIF OffsetTime'],
      );
  final latitude = exifDegrees(
    tags['GPS GPSLatitude'],
    tags['GPS GPSLatitudeRef'],
  );
  final longitude = exifDegrees(
    tags['GPS GPSLongitude'],
    tags['GPS GPSLongitudeRef'],
  );
  final hasLocation =
      latitude != null &&
      longitude != null &&
      // 位置を消された写真は 0,0 になっていることがある。
      !(latitude == 0 && longitude == 0) &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180;
  return PhotoMetadata(
    takenAt: takenAt,
    location: hasLocation ? GeoPoint(latitude, longitude) : null,
  );
}

final _exifDateTime = RegExp(
  r'^(\d{4}):(\d{2}):(\d{2}) (\d{2}):(\d{2}):(\d{2})',
);

final _exifOffset = RegExp(r'^([+-])(\d{2}):(\d{2})$');

/// 「2026:09:20 12:34:56」を読む。時差（「+09:00」）があれば端末の時刻に直し、
/// 無ければ端末の時刻として扱う。読めなければnull。
DateTime? parseExifDateTime(Object? value, {Object? offset}) {
  if (value is! String) return null;
  final match = _exifDateTime.firstMatch(value.trim());
  if (match == null) return null;
  final [year, month, day, hour, minute, second] = [
    for (var i = 1; i <= 6; i++) int.parse(match.group(i)!),
  ];
  if (year < 1990 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final offsetMatch = offset is String
      ? _exifOffset.firstMatch(offset.trim())
      : null;
  if (offsetMatch == null) {
    return DateTime(year, month, day, hour, minute, second);
  }
  final sign = offsetMatch.group(1) == '-' ? -1 : 1;
  final shift = Duration(
    hours: int.parse(offsetMatch.group(2)!),
    minutes: int.parse(offsetMatch.group(3)!),
  );
  return DateTime.utc(
    year,
    month,
    day,
    hour,
    minute,
    second,
  ).subtract(shift * sign).toLocal();
}

/// 度・分・秒の3つの値と、N/S/E/W から緯度経度（南と西はマイナス）を求める。
double? exifDegrees(Object? values, Object? ref) {
  if (values is! List<double> || values.length != 3 || ref is! String) {
    return null;
  }
  if (values.any((value) => !value.isFinite)) return null;
  final degrees = values[0] + values[1] / 60 + values[2] / 3600;
  return switch (ref.trim().toUpperCase()) {
    'N' || 'E' => degrees,
    'S' || 'W' => -degrees,
    _ => null,
  };
}
