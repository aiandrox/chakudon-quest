import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// 起動時に`main`で実際のディレクトリへ差し替える。
final documentsDirectoryProvider = Provider<Directory>(
  (ref) => throw UnimplementedError('documentsDirectoryProvider'),
);

final photoStorageProvider = Provider<PhotoStorage>(
  (ref) => PhotoStorage(ref.watch(documentsDirectoryProvider)),
);

/// 撮った写真をdocumentsディレクトリに保存する。image_pickerが返すのは一時ファイルで、
/// OSに消されることがあるため。
class PhotoStorage {
  PhotoStorage(this._documents, {this._uuid = const Uuid()});

  static const _directoryName = 'photos';

  final Directory _documents;
  final Uuid _uuid;

  /// 保存したファイルの、documentsディレクトリからの相対パスを返す。
  Future<String> save(String sourcePath) async {
    final extension = p.extension(sourcePath).toLowerCase();
    final relativePath = p.join(
      _directoryName,
      '${_uuid.v4()}${extension.isEmpty ? '.jpg' : extension}',
    );
    final destination = fileFor(relativePath);
    await destination.parent.create(recursive: true);
    await File(sourcePath).copy(destination.path);
    return relativePath;
  }

  File fileFor(String relativePath) =>
      File(p.join(_documents.path, relativePath));

  Future<void> delete(String relativePath) async {
    final file = fileFor(relativePath);
    if (await file.exists()) await file.delete();
  }
}
