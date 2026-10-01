import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/record/photo_metadata.dart';

void main() {
  group('parseExifDateTime', () {
    test('EXIFの日時を端末の時刻として読む', () {
      expect(
        parseExifDateTime('2026:09:20 12:34:56'),
        DateTime(2026, 9, 20, 12, 34, 56),
      );
    });

    test('読めない値はnull', () {
      expect(parseExifDateTime(null), isNull);
      expect(parseExifDateTime(''), isNull);
      expect(parseExifDateTime('0000:00:00 00:00:00'), isNull);
      expect(parseExifDateTime('2026-09-20 12:34:56'), isNull);
      expect(parseExifDateTime([1.0]), isNull);
    });
  });

  group('exifDegrees', () {
    test('度・分・秒から緯度経度にし、南と西はマイナスにする', () {
      expect(exifDegrees([35.0, 41.0, 22.2], 'N'), closeTo(35.6895, 0.0001));
      expect(exifDegrees([139.0, 41.0, 30.0], 'E'), closeTo(139.6917, 0.0001));
      expect(exifDegrees([33.0, 52.0, 0.0], 'S'), closeTo(-33.8667, 0.0001));
      expect(exifDegrees([151.0, 12.0, 0.0], 'W'), closeTo(-151.2, 0.0001));
    });

    test('値が足りない・向きがわからないときはnull', () {
      expect(exifDegrees([35.0, 41.0], 'N'), isNull);
      expect(exifDegrees([35.0, 41.0, 22.2], null), isNull);
      expect(exifDegrees([35.0, 41.0, 22.2], 'X'), isNull);
      expect(exifDegrees([double.nan, 0.0, 0.0], 'N'), isNull);
    });
  });

  group('photoMetadataFromExif', () {
    test('撮影日時と撮影場所を取り出す', () {
      final metadata = photoMetadataFromExif({
        'EXIF DateTimeOriginal': '2026:09:20 12:34:56',
        'Image DateTime': '2026:09:21 08:00:00',
        'GPS GPSLatitude': [35.0, 41.0, 22.2],
        'GPS GPSLatitudeRef': 'N',
        'GPS GPSLongitude': [139.0, 41.0, 30.0],
        'GPS GPSLongitudeRef': 'E',
      });

      expect(metadata.takenAt, DateTime(2026, 9, 20, 12, 34, 56));
      expect(metadata.location!.latitude, closeTo(35.6895, 0.0001));
      expect(metadata.location!.longitude, closeTo(139.6917, 0.0001));
    });

    test('撮影日時が無ければ、ファイルの日時を使う', () {
      final metadata = photoMetadataFromExif({
        'Image DateTime': '2026:09:21 08:00:00',
      });

      expect(metadata.takenAt, DateTime(2026, 9, 21, 8));
      expect(metadata.location, isNull);
    });

    test('位置が消されて 0,0 になっている写真は、場所なしとして扱う', () {
      final metadata = photoMetadataFromExif({
        'GPS GPSLatitude': [0.0, 0.0, 0.0],
        'GPS GPSLatitudeRef': 'N',
        'GPS GPSLongitude': [0.0, 0.0, 0.0],
        'GPS GPSLongitudeRef': 'E',
      });

      expect(metadata.location, isNull);
    });
  });

  test('実際のJPEGから撮影日時と撮影場所を読む', () async {
    final metadata = await const ExifPhotoMetadataReader().read(
      'test/fixtures/photo_with_exif.jpg',
    );

    expect(metadata.takenAt, DateTime(2026, 9, 20, 12, 34, 56));
    expect(metadata.location!.latitude, closeTo(35.6895, 0.0001));
    expect(metadata.location!.longitude, closeTo(139.6917, 0.0001));
  });

  test('写真として読めないファイルは、何も無いものとして扱う', () async {
    final metadata = await const ExifPhotoMetadataReader().read(
      '/nonexistent/photo.jpg',
    );

    expect(metadata.takenAt, isNull);
    expect(metadata.location, isNull);
  });
}
