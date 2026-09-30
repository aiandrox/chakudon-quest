import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:chakudon_quest/features/backup/backup_codec.dart';
import 'package:chakudon_quest/features/backup/backup_service.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/photo_storage.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';

import '../../support/fakes.dart';

final _now = DateTime(2026, 10, 1, 21, 30);

void main() {
  group('backup_codec', () {
    test('店と記録を書き出して読み戻すと、同じ内容になる', () {
      final shop = Shop(
        id: 'shop',
        name: '麺屋',
        latitude: 35.0,
        longitude: 139.0,
        osmId: 'node/1',
        hoursConditions: {HoursCondition.fewDays, HoursCondition.lunchOnly},
        strategyMemo: '券売機は現金のみ',
        createdAt: DateTime(2026, 9, 1),
      );
      final visit = Visit(
        id: 'visit',
        shopId: 'shop',
        result: VisitResult.eaten,
        photoPath: 'photos/a.jpg',
        checkedInAt: DateTime(2026, 9, 1, 11, 20),
        eatenAt: DateTime(2026, 9, 1, 12),
        style: RamenStyle.iekei,
        rating: 4,
        isLimited: true,
        hasTicket: false,
        memo: 'うまい',
        createdAt: DateTime(2026, 9, 1, 12, 5),
      );

      final json = jsonDecode(
        jsonEncode(
          encodeBackup(
            BackupData(shops: [shop], visits: [visit]),
            exportedAt: _now,
          ),
        ),
      );
      final restored = decodeBackup(json);

      final restoredShop = restored.shops.single;
      expect(restoredShop.id, 'shop');
      expect(restoredShop.name, '麺屋');
      expect(restoredShop.latitude, 35.0);
      expect(restoredShop.osmId, 'node/1');
      expect(restoredShop.hoursConditions, {
        HoursCondition.lunchOnly,
        HoursCondition.fewDays,
      });
      expect(restoredShop.strategyMemo, '券売機は現金のみ');
      expect(restoredShop.createdAt, DateTime(2026, 9, 1));
      final restoredVisit = restored.visits.single;
      expect(restoredVisit.id, 'visit');
      expect(restoredVisit.result, VisitResult.eaten);
      expect(restoredVisit.photoPath, 'photos/a.jpg');
      expect(restoredVisit.checkedInAt, DateTime(2026, 9, 1, 11, 20));
      expect(restoredVisit.eatenAt, DateTime(2026, 9, 1, 12));
      expect(restoredVisit.style, RamenStyle.iekei);
      expect(restoredVisit.rating, 4);
      expect(restoredVisit.isLimited, isTrue);
      expect(restoredVisit.memo, 'うまい');
    });

    test('ほかのアプリのファイルや、新しい版のバックアップは読まない', () {
      expect(() => decodeBackup({'format': 'other'}), throwsFormatException);
      expect(
        () => decodeBackup({
          'format': backupFormat,
          'version': backupVersion + 1,
          'shops': <Object?>[],
          'visits': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(() => decodeBackup('not a map'), throwsFormatException);
    });

    test('記録の必須項目が壊れていれば読まない。知らない系統は「系統なし」にする', () {
      Map<String, Object?> backupWith(Map<String, Object?> visit) => {
        'format': backupFormat,
        'version': backupVersion,
        'shops': <Object?>[],
        'visits': [visit],
      };
      final visit = {
        'id': 'v',
        'shopId': 's',
        'result': 'eaten',
        'eatenAt': '2026-09-01T12:00:00.000',
        'createdAt': '2026-09-01T12:00:00.000',
        'style': 'unknownStyle',
        'rating': 9,
      };

      final restored = decodeBackup(backupWith(visit)).visits.single;
      expect(restored.style, isNull);
      expect(restored.rating, isNull);

      expect(
        () => decodeBackup(backupWith({...visit, 'result': 'burned'})),
        throwsFormatException,
      );
      expect(
        () => decodeBackup(backupWith({...visit, 'eatenAt': 'yesterday'})),
        throwsFormatException,
      );
    });
  });

  group('BackupService', () {
    late RecordRepository source;
    late PhotoStorage sourcePhotos;
    late Directory temporary;

    setUp(() async {
      source = RecordRepository(createTestDatabase());
      sourcePhotos = PhotoStorage(createTempDirectory());
      temporary = createTempDirectory();
      final picked = File(p.join(temporary.path, 'picked.jpg'))
        ..writeAsBytesSync([1, 2, 3]);
      final photoPath = await sourcePhotos.save(picked.path);
      final visit = await source.saveEatenVisit(
        shop: const ShopInput(name: '麺屋', latitude: 35.0, longitude: 139.0),
        eatenAt: DateTime(2026, 9, 1, 12),
        rating: 5,
        photoPath: photoPath,
        now: DateTime(2026, 9, 1, 12),
      );
      await source.setShopMemo(visit.shopId, '開店30分前');
      await source.saveEatenVisit(
        shop: const ShopInput(name: '写真なしの店'),
        eatenAt: DateTime(2026, 9, 2, 12),
        now: DateTime(2026, 9, 2, 12),
      );
    });

    BackupService serviceFor(
      RecordRepository repository,
      PhotoStorage photos,
    ) => BackupService(
      repository: repository,
      photos: photos,
      temporaryDirectory: () async => temporary,
    );

    test('書き出したファイルを別のスマホで読み込むと、記録と写真が戻る', () async {
      final backup = await serviceFor(source, sourcePhotos).writeBackup(_now);
      expect(p.basename(backup.path), 'chakudon-quest-20261001-2130.zip');

      final target = RecordRepository(createTestDatabase());
      final targetPhotos = PhotoStorage(createTempDirectory());
      final summary = await serviceFor(
        target,
        targetPhotos,
      ).restoreBackup(backup.path);

      expect(summary.addedVisits, 2);
      expect(summary.totalVisits, 2);
      final visits = await target.watchVisits().first;
      expect(visits.map((v) => v.shop.name).toSet(), {'麺屋', '写真なしの店'});
      final withPhoto = visits.firstWhere((v) => v.shop.name == '麺屋');
      expect(withPhoto.shop.strategyMemo, '開店30分前');
      expect(withPhoto.visit.rating, 5);
      expect(
        targetPhotos.fileFor(withPhoto.visit.photoPath!).readAsBytesSync(),
        [1, 2, 3],
      );
    });

    test('同じファイルをもう一度読み込んでも、記録は増えない', () async {
      final service = serviceFor(source, sourcePhotos);
      final backup = await service.writeBackup(_now);

      final summary = await service.restoreBackup(backup.path);

      expect(summary.addedVisits, 0);
      expect(await source.watchVisits().first, hasLength(2));
    });

    test('バックアップでないzipは読み込まない', () async {
      final path = p.join(temporary.path, 'other.zip');
      final encoder = ZipFileEncoder()..create(path);
      encoder.addArchiveFile(ArchiveFile.string('readme.txt', 'hello'));
      await encoder.close();

      expect(
        () => serviceFor(source, sourcePhotos).restoreBackup(path),
        throwsFormatException,
      );
    });

    test('写真のフォルダの外を指す名前のファイルは書き出さない', () async {
      final data = await source.exportAll();
      final path = p.join(temporary.path, 'evil.zip');
      final encoder = ZipFileEncoder()..create(path);
      encoder.addArchiveFile(
        ArchiveFile.string(
          'backup.json',
          jsonEncode(encodeBackup(data, exportedAt: _now)),
        ),
      );
      encoder.addArchiveFile(ArchiveFile.bytes('photos/../escaped.jpg', [9]));
      encoder.addArchiveFile(ArchiveFile.bytes('other/x.jpg', [9]));
      await encoder.close();
      final targetDocuments = createTempDirectory();

      await serviceFor(
        RecordRepository(createTestDatabase()),
        PhotoStorage(targetDocuments),
      ).restoreBackup(path);

      expect(
        File(p.join(targetDocuments.path, 'escaped.jpg')).existsSync(),
        isFalse,
      );
      expect(
        File(p.join(targetDocuments.path, 'other', 'x.jpg')).existsSync(),
        isFalse,
      );
    });
  });
}
