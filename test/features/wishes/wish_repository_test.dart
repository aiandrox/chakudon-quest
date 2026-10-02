import 'package:flutter_test/flutter_test.dart';

import 'package:chakudon_quest/features/backup/backup_codec.dart';
import 'package:chakudon_quest/features/records/models.dart';
import 'package:chakudon_quest/features/records/record_repository.dart';
import 'package:chakudon_quest/features/wishes/wish_repository.dart';

import '../../support/fakes.dart';

void main() {
  late WishRepository wishes;
  late RecordRepository records;

  setUp(() {
    final database = createTestDatabase();
    wishes = WishRepository(database);
    records = RecordRepository(database);
  });

  test('願を書き留め、書き直し、消せる', () async {
    final wish = await wishes.addWish(
      shop: const ShopInput(
        osmId: 'node/1',
        name: ' はやし田 ',
        latitude: 35.0,
        longitude: 139.0,
        dataSource: ShopSource(licenses: ['CC BY 4.0']),
      ),
      trigger: '同僚に聞いた',
      note: '',
      now: DateTime(2026, 10, 3),
    );

    var saved = (await wishes.watchWishes().first).single;
    expect(saved.name, 'はやし田');
    expect(saved.osmId, 'node/1');
    expect(saved.trigger, '同僚に聞いた');
    expect(saved.dataSource!.licenses, ['CC BY 4.0']);

    await wishes.updateWish(wish.id, trigger: 'テレビ', note: '煮干し');
    saved = (await wishes.watchWishes().first).single;
    expect(saved.trigger, 'テレビ');
    expect(saved.note, '煮干し');

    await wishes.deleteWish(wish.id);
    expect(await wishes.watchWishes().first, isEmpty);
  });

  test('バックアップに願を含め、読み込むと端末に無い願だけを足す', () async {
    await wishes.addWish(
      shop: const ShopInput(name: 'はやし田'),
      trigger: '同僚に聞いた',
      now: DateTime(2026, 10, 3),
    );
    final exported = await records.exportAll();
    final decoded = decodeBackup(
      encodeBackup(exported, exportedAt: DateTime(2026, 10, 4)),
    );
    expect(decoded.wishes.single.trigger, '同僚に聞いた');

    final other = createTestDatabase();
    await RecordRepository(other).importAll(decoded);
    await RecordRepository(other).importAll(decoded);
    final restored = await WishRepository(other).watchWishes().first;
    expect(restored.single.name, 'はやし田');
  });

  test('願掛け帳より前のバックアップも読める', () {
    final data = decodeBackup({
      'format': backupFormat,
      'version': backupVersion,
      'shops': <Object?>[],
      'visits': <Object?>[],
    });

    expect(data.wishes, isEmpty);
  });
}
