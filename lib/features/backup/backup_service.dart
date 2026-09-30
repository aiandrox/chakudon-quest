import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../records/photo_storage.dart';
import '../records/record_repository.dart';
import 'backup_codec.dart';

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    repository: ref.watch(recordRepositoryProvider),
    photos: ref.watch(photoStorageProvider),
    temporaryDirectory: getTemporaryDirectory,
  ),
);

const _dataFileName = 'backup.json';
const _fileNamePrefix = 'chakudon-quest-';
const _photosDirectory = 'photos';

class RestoreSummary {
  const RestoreSummary({required this.addedVisits, required this.totalVisits});

  final int addedVisits;
  final int totalVisits;
}

/// 記録と写真を1つのzipファイルにまとめて書き出し、読み込む。
class BackupService {
  BackupService({
    required this._repository,
    required this._photos,
    required this._temporaryDirectory,
  });

  final RecordRepository _repository;
  final PhotoStorage _photos;
  final Future<Directory> Function() _temporaryDirectory;

  Future<File> writeBackup(DateTime now) async {
    final data = await _repository.exportAll();
    final directory = await _temporaryDirectory();
    // 前回までに書き出したファイルは共有が終わっているので消す。写真が全部入っていて大きいため。
    await for (final old in directory.list()) {
      final name = p.basename(old.path);
      if (old is File &&
          name.startsWith(_fileNamePrefix) &&
          name.endsWith('.zip')) {
        await old.delete();
      }
    }
    final path = p.join(
      directory.path,
      '$_fileNamePrefix${DateFormat('yyyyMMdd-HHmm').format(now)}.zip',
    );
    final encoder = ZipFileEncoder()..create(path);
    try {
      encoder.addArchiveFile(
        ArchiveFile.string(
          _dataFileName,
          jsonEncode(encodeBackup(data, exportedAt: now)),
        ),
      );
      for (final visit in data.visits) {
        final photoPath = visit.photoPath;
        if (photoPath == null) continue;
        final photo = _photos.fileFor(photoPath);
        if (!await photo.exists()) continue;
        await encoder.addFile(photo, _archivePhotoName(photoPath));
      }
    } finally {
      await encoder.close();
    }
    return File(path);
  }

  /// 端末にない記録と写真だけを足す。バックアップとして読めなければ[FormatException]。
  Future<RestoreSummary> restoreBackup(String zipPath) async {
    final input = InputFileStream(zipPath);
    try {
      final archive = ZipDecoder().decodeStream(input);
      final dataFile = archive.findFile(_dataFileName);
      if (dataFile == null) {
        throw const FormatException('着丼クエストのバックアップではありません');
      }
      final data = decodeBackup(
        jsonDecode(utf8.decode(dataFile.readBytes() ?? const [])),
      );
      final written = <File>[];
      try {
        for (final file in archive.files) {
          final photoPath = _photoPathOf(file.name);
          if (!file.isFile || photoPath == null) continue;
          final destination = _photos.fileFor(photoPath);
          if (await destination.exists()) continue;
          await destination.parent.create(recursive: true);
          await destination.writeAsBytes(file.readBytes() ?? const []);
          written.add(destination);
        }
        final added = await _repository.importAll(data);
        return RestoreSummary(
          addedVisits: added,
          totalVisits: data.visits.length,
        );
      } catch (_) {
        // 記録を足せなかったら、書いた写真も消して読み込む前に戻す。
        for (final file in written) {
          if (await file.exists()) await file.delete();
        }
        rethrow;
      }
    } finally {
      await input.close();
    }
  }

  String _archivePhotoName(String photoPath) =>
      '$_photosDirectory/${p.basename(photoPath)}';

  /// zipの中の写真の名前から、保存先の相対パスを求める。写真以外やフォルダを
  /// さかのぼる名前は、ほかの場所を書き換えないよう無視する。
  String? _photoPathOf(String name) {
    final parts = name.split('/');
    if (parts.length != 2 || parts.first != _photosDirectory) return null;
    final fileName = parts.last;
    if (fileName.isEmpty ||
        fileName.startsWith('.') ||
        fileName.contains('\\')) {
      return null;
    }
    return p.join(_photosDirectory, fileName);
  }
}
