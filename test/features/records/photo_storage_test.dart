import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:ramen_in_cho/features/records/photo_storage.dart';

import '../../support/fakes.dart';

void main() {
  test('写真をdocumentsディレクトリにコピーし、相対パスを返す', () async {
    final documents = createTempDirectory();
    final source = File(p.join(createTempDirectory().path, 'picked.JPG'))
      ..writeAsBytesSync([1, 2, 3]);
    final storage = PhotoStorage(documents);

    final relativePath = await storage.save(source.path);

    expect(p.isRelative(relativePath), isTrue);
    expect(relativePath, startsWith('photos${p.separator}'));
    expect(relativePath, endsWith('.jpg'));
    expect(storage.fileFor(relativePath).readAsBytesSync(), [1, 2, 3]);
    expect(
      p.isWithin(documents.path, storage.fileFor(relativePath).path),
      isTrue,
    );
    expect(source.existsSync(), isTrue);
  });

  test('保存した写真を削除できる。無いファイルの削除は何もしない', () async {
    final storage = PhotoStorage(createTempDirectory());
    final source = File(p.join(createTempDirectory().path, 'picked.jpg'))
      ..writeAsBytesSync([1]);
    final relativePath = await storage.save(source.path);

    await storage.delete(relativePath);
    await storage.delete(relativePath);

    expect(storage.fileFor(relativePath).existsSync(), isFalse);
  });
}
